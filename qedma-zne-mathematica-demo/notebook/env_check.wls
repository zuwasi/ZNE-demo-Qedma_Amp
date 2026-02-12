(* Environment Check Script *)
Print["=== Mathematica Environment Check ==="];
Print["Version: ", $VersionNumber];
Print["System: ", $SystemID];
Print["Date: ", DateString[]];

(* Check for QuantumFramework *)
Print["\n--- QuantumFramework Check ---"];
found = PacletFind["Wolfram/QuantumFramework"];
If[found === {},
  Print["QuantumFramework not found. Attempting install..."];
  result = Quiet[Check[PacletInstall["Wolfram/QuantumFramework"], $Failed]];
  If[result === $Failed,
    Print["INSTALL FAILED - see manual steps in docs/env-check.md"];
    ,
    Print["Installed: ", result];
  ];
  ,
  Print["Found: ", First[found]];
];

(* Try loading *)
Print["\n--- Loading QuantumFramework ---"];
Quiet[Check[
  Needs["Wolfram`QuantumFramework`"];
  Print["Load: OK"];
  ,
  Print["Load: FAILED"];
]];

(* Quick smoke test *)
Print["\n--- Smoke Test ---"];
Quiet[Check[
  state = QuantumState[0];
  Print["QuantumState[0]: ", state];
  Print["Smoke test: PASSED"];
  ,
  Print["Smoke test: FAILED"];
]];

Print["\n=== Done ==="];
