# Goal
Build an end-to-end, reproducible Mathematica 14.3 demonstrator for Zero-Noise Extrapolation (ZNE) inspired by Temme–Bravyi–Gambetta (arXiv:1612.02058). The deliverable is:
1) A Mathematica notebook (.nb) with an interactive visual demo (ideal vs noisy vs ZNE, with controls).
2) A Wolfram Language package (.wl) that contains reusable functions.
3) A short validation report (Markdown + exported PDF from the notebook) with figures and acceptance checks.
4) A "runbook" section in the notebook explaining how to reproduce results on another machine.

The agent must perform all steps automatically, using subagents where helpful.

# Constraints
- OS: Windows 11
- Mathematica: 14.3
- Use Wolfram Quantum Framework paclet (Wolfram/QuantumFramework).
- Keep code self-contained. No external Python or Jupyter required.
- Prefer deterministic outputs with a fixed random seed for any sampling.
- Do not assume the user has administrative privileges.
- If network access is required (paclet install), detect failures and produce a fallback guide.

# References (to download and cite)
- Temme, Bravyi, Gambetta, "Error Mitigation for Short-Depth Quantum Circuits" (arXiv:1612.02058)
  PDF: https://arxiv.org/pdf/1612.02058
- Optional: Kandala et al., "Error mitigation extends the computational reach..." (arXiv:1805.04492)
  https://arxiv.org/abs/1805.04492

# Repository Layout (create locally)
Create a folder: ./qedma-zne-mathematica-demo
Inside:
- README.md
- docs/
  - references.md (links + short summary)
  - validation-report.md (auto-generated)
- src/
  - ZNEDemo.wl (package code)
- notebook/
  - ZNE_Demo.nb
  - exports/
    - ZNE_Demo.pdf
    - figures/ (PNGs exported from notebook)

# High-level Plan
Use a coordinator agent that delegates to subagents:
1) "EnvCheck" subagent: verify Mathematica + paclet state, install paclet if missing.
2) "NotebookAuthor" subagent: generate a polished Mathematica notebook with interactive UI and plots.
3) "PackageAuthor" subagent: generate a .wl package that notebook imports.
4) "Validation" subagent: implement quantitative checks, generate validation-report.md, export figures and PDF.
5) "ReproRunbook" subagent: ensure notebook contains a step-by-step reproduction section and that README.md is complete.

# Execution Instructions for Ampcode
You are the coordinator. Follow the phases below. After each phase, verify outputs exist and are correct. Do not skip verification.

## Phase 0: Create workspace
- Create folder ./qedma-zne-mathematica-demo with subfolders as above.
- Create an initial README.md describing objectives and how to run.

## Phase 1: Environment check (EnvCheck subagent)
Task:
- Detect whether the Quantum Framework is installed and loadable.
- If not installed, install it.
- Produce a short log in docs/env-check.md.

Method:
- Create a temporary Mathematica script file: notebook/env_check.wls
- Run it using wolframscript if available.
  - If wolframscript is not present, generate a manual instruction section in docs/env-check.md and continue by writing the notebook anyway.

Script requirements:
- Print Mathematica version.
- Check `PacletFind["QuantumFramework"]`
- If empty, run `PacletInstall["Wolfram/QuantumFramework"]`
- Then `Needs["Wolfram`QuantumFramework`"]`
- Finally evaluate `QuantumState[0]` and print success.

Deliverable:
- docs/env-check.md containing:
  - version output
  - paclet installed version/location
  - whether wolframscript automation succeeded
  - fallback manual steps if automation is not possible

## Phase 2: Core package (PackageAuthor subagent)
Create src/ZNEDemo.wl that exposes the following public functions:

Public API:
- ZNE`MakeCircuit[theta_, nQubits_:1, depth_:1]  (* returns QuantumCircuit *)
- ZNE`IdealExpectation[theta_, opts___]          (* returns numeric expectation *)
- ZNE`NoisyExpectation[theta_, lambda_, opts___] (* returns numeric expectation *)
- ZNE`ZNEEstimate[theta_, lambdaList_List, order_Integer:2, opts___]
- ZNE`GenerateSweep[thetaList_List, lambdaList_List, order_Integer:2, opts___]
  returns an Association with keys:
  - "IdealData" -> {{theta, val}...}
  - "NoisyData" -> <|lambda -> {{theta, val}...}, ...|>
  - "ZNEData" -> {{theta, val}...}
  - "Meta" -> <|params...|>

Options (must be supported):
- "NoiseModel" -> "DepolarizingEnd" | "DepolarizingPerGate"
- "BaseNoise" -> p0 (default 0.02)
- "Shots" -> Infinity (default Infinity means analytic expectation; integer means sample-based)
- "Seed" -> 1234
- "Observable" -> PauliZ[1] by default
- "State" -> QuantumState[0] by default

Implementation details:
- For "DepolarizingEnd": apply a depolarizing channel once at end.
- For "DepolarizingPerGate": apply depolarizing channel after each gate in the circuit.
- For finite shots: simulate measurement sampling to estimate expectation and include standard error; return both mean and stderr when shots is finite (use a consistent structure such as {mean, stderr}).
- Ensure all results are numeric and stable. Use memoization sparingly.

Include internal helper functions:
- normalize options, clip probabilities, compute expectation from state, sampling for PauliZ measurement.

Write clean, commented code suitable for review by a research team.

## Phase 3: Elaborate interactive notebook (NotebookAuthor subagent)
Create notebook/ZNE_Demo.nb programmatically (or via templated Wolfram language code saved as .nb) containing:

Sections:
1) Title + Abstract (what ZNE is, what is shown)
2) References (paper links)
3) Environment (Mathematica version, paclet version; auto-filled if possible)
4) Demo Controls (interactive):
   - slider: base noise p0 in [0, 0.1]
   - choice: noise model (end vs per-gate)
   - list control: lambdaList (preset options: {1,2,3,4} and {1,1.5,2,2.5,3})
   - integer: polynomial order (1..3)
   - theta sweep resolution (10..80 points)
   - shots: Infinity or numeric (e.g., 100, 500, 2000)
5) Main Plot:
   - Ideal curve
   - Noisy curves for each lambda
   - ZNE curve
   - include legends and axis labels
6) Error Plot:
   - absolute error of noisy vs ideal
   - absolute error of ZNE vs ideal
   - if shots finite: include error bars
7) Local fit diagnostics:
   - for a selected theta value, show points E(lambda) and polynomial fit
   - show extrapolated estimate at lambda=0
8) Validation section:
   - automated checks with pass/fail:
     - as p0 -> 0, ZNE approx equals ideal (tolerance)
     - for moderate p0, ZNE improves over lambda=1 noisy at most theta points
     - for per-gate noise, show stronger degradation and corresponding mitigation
9) Export section:
   - code cell that exports:
     - notebook as PDF to notebook/exports/ZNE_Demo.pdf
     - figures to notebook/exports/figures/
10) Reproducibility runbook:
    - step-by-step instructions to install paclet and run
    - list of parameters used for the exported artifacts

The notebook must load the package:
- `Get[FileNameJoin[{NotebookDirectory[], "..", "src", "ZNEDemo.wl"}]]`
(or equivalent robust path handling)

## Phase 4: Validation artifacts (Validation subagent)
- Run the notebook (or the underlying package functions) to generate exported figures and PDF.
- Create docs/validation-report.md summarizing:
  - parameter settings used for exports
  - numeric table: mean absolute error for noisy lambda=1 vs ideal; ZNE vs ideal
  - a short interpretation of results and limitations (variance amplification, sampling overhead)
- Ensure exports exist:
  - notebook/exports/ZNE_Demo.pdf
  - at least 2 PNG figures in notebook/exports/figures/

If automated notebook execution is not possible, produce manual instructions and confirm the notebook contains the export cells.

## Phase 5: Final polish and verification (Coordinator)
- Confirm all files exist.
- Open README.md and ensure it gives:
  - purpose
  - requirements
  - how to run notebook
  - how to export artifacts
- Ensure the notebook runs from top to bottom without errors in Mathematica 14.3.
- Provide a final summary of what was produced and where each artifact is located.

# Acceptance Criteria
- The demo runs in Mathematica 14.3 with QuantumFramework installed.
- Interactive Manipulate UI works and updates plots quickly (reasonable performance).
- Exports generate PDF and PNG figures.
- Validation report includes numeric evidence that ZNE reduces error relative to baseline noisy curve at the chosen settings.
- The project is portable (another machine can run it following README).

# Safety / Failure Handling
- If paclet install fails (network restrictions), document the exact error and add manual install steps in docs/env-check.md.
- If wolframscript is missing, do not block; keep everything runnable via opening the notebook manually.

# Deliverable Summary (must output at end)
List paths of:
- notebook/ZNE_Demo.nb
- src/ZNEDemo.wl
- docs/validation-report.md
- notebook/exports/ZNE_Demo.pdf
- notebook/exports/figures/*.png
