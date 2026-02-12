(* ::Package:: *)
(* ZNEDemo.wl — Zero-Noise Extrapolation Demo Package *)
(* Inspired by Temme, Bravyi, Gambetta (arXiv:1612.02058) *)
(* Requires: Wolfram/QuantumFramework paclet *)

BeginPackage["ZNE`"];

(* ===== Public API ===== *)

MakeCircuit::usage = 
  "MakeCircuit[theta, nQubits, depth] returns a QuantumCircuitOperator for a parameterized circuit.";

IdealExpectation::usage = 
  "IdealExpectation[theta, opts] returns the ideal (noiseless) expectation value of the observable.";

NoisyExpectation::usage = 
  "NoisyExpectation[theta, lambda, opts] returns the noisy expectation value at noise scale lambda.";

ZNEEstimate::usage = 
  "ZNEEstimate[theta, lambdaList, order, opts] returns the ZNE-extrapolated expectation at lambda=0.";

GenerateSweep::usage = 
  "GenerateSweep[thetaList, lambdaList, order, opts] returns an Association with IdealData, NoisyData, ZNEData, Meta.";

(* ===== Options ===== *)

Options[ZNEDemoOptions] = {
  "NoiseModel" -> "DepolarizingEnd",
  "BaseNoise" -> 0.02,
  "Shots" -> Infinity,
  "Seed" -> 1234,
  "Observable" -> "PauliZ",
  "State" -> Automatic
};

Begin["`Private`"];

(* ---------- Helper: Merge options ---------- *)
resolveOpts[opts___] := Module[{merged},
  merged = Join[{opts}, Options[ZNEDemoOptions]];
  Association @@ merged
];

(* ---------- Helper: Clip probability to [0, 1] ---------- *)
clipProb[p_] := Clip[p, {0, 1}];

(* ---------- Circuit Construction ---------- *)
(* Simple parameterized single-qubit circuit: Ry(theta) repeated depth times *)
MakeCircuit[theta_, nQubits_Integer:1, depth_Integer:1] := Module[
  {gates},
  gates = Table[
    QuantumOperator["RY", {1} -> {1}, "Parameters" -> {theta}],
    {depth}
  ];
  QuantumCircuitOperator[gates]
];

(* ---------- Ideal Expectation ---------- *)
(* For a single qubit with PauliZ observable: <psi|Z|psi> *)
(* Ry(theta)|0> = cos(theta/2)|0> + sin(theta/2)|1> *)
(* <Z> = cos^2(theta/2) - sin^2(theta/2) = cos(theta) *)
IdealExpectation[theta_, opts___] := Module[
  {o = resolveOpts[opts]},
  (* Analytic: for Ry(theta)|0>, <Z> = Cos[theta] for depth=1 *)
  (* For depth d with repeated Ry(theta): Ry(theta)^d = Ry(d*theta) *)
  (* So <Z> = Cos[d*theta]. Default depth=1. *)
  N[Cos[theta]]
];

(* ---------- Depolarizing Channel ---------- *)
(* Single-qubit depolarizing channel: rho -> (1-p)*rho + p*I/2 *)
(* Effect on Bloch vector: r -> (1-p)*r *)
(* Effect on <Z>: <Z>_noisy = (1-p)*<Z>_ideal *)
applyDepolarizing[expectation_, p_] := (1 - clipProb[p]) * expectation;

(* ---------- Noisy Expectation ---------- *)
NoisyExpectation[theta_, lambda_, opts___] := Module[
  {o, p0, noiseModel, idealVal, effectiveP, noisyVal, shots, seed, stderr},
  o = resolveOpts[opts];
  p0 = o["BaseNoise"];
  noiseModel = o["NoiseModel"];
  shots = o["Shots"];
  seed = o["Seed"];
  
  idealVal = IdealExpectation[theta, opts];
  
  (* Compute effective noise parameter *)
  effectiveP = Switch[noiseModel,
    "DepolarizingEnd",
      (* Single depolarizing channel at end, scaled by lambda *)
      clipProb[lambda * p0],
    "DepolarizingPerGate",
      (* Per-gate noise: for depth d gates, total = 1-(1-lambda*p0)^d *)
      (* Default depth=1 for simplicity, so same as End for d=1 *)
      (* For stronger effect, use effective = 1-(1-lambda*p0)^3 to simulate deeper circuit *)
      clipProb[1 - (1 - clipProb[lambda * p0])^3],
    _,
      clipProb[lambda * p0]
  ];
  
  noisyVal = applyDepolarizing[idealVal, effectiveP];
  
  (* If finite shots, add sampling noise *)
  If[shots === Infinity,
    noisyVal,
    (* Simulate shot noise for PauliZ measurement *)
    (* P(+1) = (1 + <Z>)/2, P(-1) = (1 - <Z>)/2 *)
    (* Sample from binomial, compute mean and stderr *)
    BlockRandom[
      SeedRandom[seed + Round[1000 * theta] + Round[100 * lambda]];
      Module[{pPlus, counts, mean, se},
        pPlus = clipProb[(1 + noisyVal) / 2];
        counts = RandomVariate[BinomialDistribution[shots, pPlus]];
        mean = 2 * counts / shots - 1;
        se = 2 * Sqrt[pPlus * (1 - pPlus) / shots];
        {mean, se}
      ]
    ]
  ]
];

(* ---------- ZNE Estimate (Richardson Extrapolation) ---------- *)
ZNEEstimate[theta_, lambdaList_List, order_Integer:2, opts___] := Module[
  {noisyVals, lambdas, polyOrder, fitData, fit, lam, extrapolated,
   hasShotNoise, means, stderrs},
  
  lambdas = N[lambdaList];
  
  (* Collect noisy expectations at each lambda *)
  noisyVals = Table[
    NoisyExpectation[theta, lam, opts],
    {lam, lambdas}
  ];
  
  (* Check if we have shot noise (list entries are {mean, stderr}) *)
  hasShotNoise = MatchQ[First[noisyVals], {_, _}];
  
  If[hasShotNoise,
    means = noisyVals[[All, 1]];
    stderrs = noisyVals[[All, 2]];,
    means = noisyVals;
    stderrs = ConstantArray[0, Length[lambdas]];
  ];
  
  (* Polynomial fit: E(lambda) ~ a0 + a1*lambda + ... + a_n*lambda^n *)
  polyOrder = Min[order, Length[lambdas] - 1];
  fitData = Transpose[{lambdas, means}];
  
  fit = Fit[fitData, Table[lam^k, {k, 0, polyOrder}], lam];
  
  (* Extrapolate to lambda = 0 *)
  extrapolated = fit /. lam -> 0;
  
  If[hasShotNoise,
    {N[extrapolated], Mean[stderrs]},  (* approximate propagated error *)
    N[extrapolated]
  ]
];

(* ---------- Full Parameter Sweep ---------- *)
GenerateSweep[thetaList_List, lambdaList_List, order_Integer:2, opts___] := Module[
  {idealData, noisyData, zneData, o, hasShotNoise, firstResult},
  
  o = resolveOpts[opts];
  
  (* Ideal curve *)
  idealData = Table[{th, IdealExpectation[th, opts]}, {th, thetaList}];
  
  (* Noisy curves for each lambda *)
  noisyData = Association @@ Table[
    lam -> Table[
      Module[{val = NoisyExpectation[th, lam, opts]},
        If[MatchQ[val, {_, _}],
          {th, val[[1]], val[[2]]},  (* {theta, mean, stderr} *)
          {th, val}                   (* {theta, value} *)
        ]
      ],
      {th, thetaList}
    ],
    {lam, lambdaList}
  ];
  
  (* ZNE curve *)
  zneData = Table[
    Module[{val = ZNEEstimate[th, lambdaList, order, opts]},
      If[MatchQ[val, {_, _}],
        {th, val[[1]], val[[2]]},
        {th, val}
      ]
    ],
    {th, thetaList}
  ];
  
  (* Return structured result *)
  <|
    "IdealData" -> idealData,
    "NoisyData" -> noisyData,
    "ZNEData" -> zneData,
    "Meta" -> <|
      "NoiseModel" -> o["NoiseModel"],
      "BaseNoise" -> o["BaseNoise"],
      "Shots" -> o["Shots"],
      "LambdaList" -> lambdaList,
      "Order" -> order,
      "NumPoints" -> Length[thetaList]
    |>
  |>
];

End[];
EndPackage[];
