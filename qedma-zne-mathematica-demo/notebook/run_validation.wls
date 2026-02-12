(* Validation Script - generates figures and validation data *)
Print["=== ZNE Validation Script ==="];

(* Load package *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "src", "ZNEDemo.wl"}]];

(* Setup directories *)
exportDir = FileNameJoin[{DirectoryName[$InputFileName], "exports"}];
figDir = FileNameJoin[{exportDir, "figures"}];
If[!DirectoryQ[figDir], CreateDirectory[figDir, CreateIntermediateDirectories -> True]];

(* Generate sweep data *)
thetaList = N[Range[0, 2 Pi, 2 Pi/40]];
lambdas = {1, 2, 3, 4};

sweep = ZNE`GenerateSweep[thetaList, lambdas, 2, "BaseNoise" -> 0.03];
Print["Sweep generated: ", Length[sweep["IdealData"]], " points"];

(* Main figure *)
mainFig = Show[
  ListLinePlot[
    Prepend[Values[sweep["NoisyData"]], sweep["IdealData"]],
    PlotLegends -> Prepend[Table["\[Lambda]=" <> ToString[l], {l, lambdas}], "Ideal"],
    PlotLabel -> "ZNE: Ideal vs Noisy vs Mitigated",
    AxesLabel -> {"\[Theta]", "\[LeftAngleBracket]Z\[RightAngleBracket]"},
    ImageSize -> 700,
    PlotStyle -> {{Thick, Black}, Automatic}
  ],
  ListLinePlot[sweep["ZNEData"],
    PlotStyle -> {Thick, Red, Dashed},
    PlotLegends -> {"ZNE"}
  ]
];

(* Error figure *)
errorFig = ListLinePlot[{
  MapThread[Function[{i, n}, {i[[1]], Abs[n[[2]] - i[[2]]]}],
    {sweep["IdealData"], sweep["NoisyData", 1]}],
  MapThread[Function[{i, z}, {i[[1]], Abs[z[[2]] - i[[2]]]}],
    {sweep["IdealData"], sweep["ZNEData"]}]
  },
  PlotLegends -> {"Noisy (\[Lambda]=1)", "ZNE"},
  PlotLabel -> "Absolute Error Comparison",
  AxesLabel -> {"\[Theta]", "|Error|"},
  ImageSize -> 700
];

(* Export figures *)
Export[FileNameJoin[{figDir, "zne_main_plot.png"}], mainFig, ImageResolution -> 150];
Print["Exported: zne_main_plot.png"];
Export[FileNameJoin[{figDir, "zne_error_plot.png"}], errorFig, ImageResolution -> 150];
Print["Exported: zne_error_plot.png"];

(* Validation checks *)
Print["\n=== Validation Checks ==="];
thetaTest = N[Range[0.1, 2 Pi, 0.3]];

(* Check 1: Low noise *)
sweep1 = ZNE`GenerateSweep[thetaTest, lambdas, 2, "BaseNoise" -> 0.001];
maxErr1 = Max[Abs[sweep1["ZNEData"][[All, 2]] - sweep1["IdealData"][[All, 2]]]];
Print["Check 1 (low noise p0=0.001): max|ZNE-Ideal| = ", maxErr1,
  If[maxErr1 < 0.01, " PASS", " FAIL"]];

(* Check 2: ZNE improvement *)
sweep2 = ZNE`GenerateSweep[thetaTest, lambdas, 2, "BaseNoise" -> 0.05];
noisyErr2 = Mean[Abs[sweep2["NoisyData", 1][[All, 2]] - sweep2["IdealData"][[All, 2]]]];
zneErr2 = Mean[Abs[sweep2["ZNEData"][[All, 2]] - sweep2["IdealData"][[All, 2]]]];
improvement2 = (noisyErr2 - zneErr2) / noisyErr2;
Print["Check 2 (p0=0.05): noisy MAE=", NumberForm[noisyErr2, 4],
  " | ZNE MAE=", NumberForm[zneErr2, 4],
  " | improvement=", NumberForm[100 improvement2, 3], "%",
  If[zneErr2 < noisyErr2, " PASS", " FAIL"]];

(* Check 3: Per-gate stronger *)
sweepE = ZNE`GenerateSweep[thetaTest, lambdas, 2, "NoiseModel" -> "DepolarizingEnd", "BaseNoise" -> 0.03];
sweepP = ZNE`GenerateSweep[thetaTest, lambdas, 2, "NoiseModel" -> "DepolarizingPerGate", "BaseNoise" -> 0.03];
endErr = Mean[Abs[sweepE["NoisyData", 1][[All, 2]] - sweepE["IdealData"][[All, 2]]]];
pgErr = Mean[Abs[sweepP["NoisyData", 1][[All, 2]] - sweepP["IdealData"][[All, 2]]]];
Print["Check 3: End MAE=", NumberForm[endErr, 4],
  " | PerGate MAE=", NumberForm[pgErr, 4],
  If[pgErr > endErr, " PASS", " FAIL"]];

(* Output numeric table for report *)
Print["\n=== Numeric Summary (p0=0.03, DepolarizingEnd) ==="];
sweep3 = ZNE`GenerateSweep[thetaTest, lambdas, 2, "BaseNoise" -> 0.03];
noisyMAE = Mean[Abs[sweep3["NoisyData", 1][[All, 2]] - sweep3["IdealData"][[All, 2]]]];
zneMAE = Mean[Abs[sweep3["ZNEData"][[All, 2]] - sweep3["IdealData"][[All, 2]]]];
Print["Noisy (lambda=1) MAE: ", NumberForm[noisyMAE, 6]];
Print["ZNE MAE: ", NumberForm[zneMAE, 6]];
Print["Improvement: ", NumberForm[100 (noisyMAE - zneMAE)/noisyMAE, 4], "%"];

Print["\n=== Validation Complete ==="];
