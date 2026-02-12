# Goal
Live demo: Amp creates a fully professional, interactive Mathematica 14.3 notebook (.nb) from scratch in front of an audience. The notebook must showcase Mathematica's most impressive capabilities — Manipulate, dynamic visualisations, real-time interactivity, and polished formatting. The audience opens the notebook and interacts with it immediately.

This demo reuses the proven ZNEDemo.wl backend from ./qedma-zne-mathematica-demo but creates a NEW, even more impressive notebook.

# Constraints
- OS: Windows 11
- Mathematica 14.3 + wolframscript on PATH
- QuantumFramework paclet already installed
- Output folder: ./zne-live-demo
- The notebook MUST be generated using wolframscript (Export[path, nbExpr, "NB"]) — this is the only reliable method to produce valid .nb files without a GUI. Do NOT write raw .nb text.

# Key Lesson from Full Project
Notebooks must be built as Wolfram expressions and exported via:
```
nbExpr = Notebook[{cells...}, options...];
Export["path.nb", nbExpr, "NB"];
```
This produces a proper .nb with headers, UUIDs, and cache metadata that Mathematica opens correctly. Writing raw text to a .nb file does NOT work.

# Phase 1: Scaffold and copy package
- Create ./zne-live-demo/src/
- COPY ./qedma-zne-mathematica-demo/src/ZNEDemo.wl → ./zne-live-demo/src/ZNEDemo.wl

# Phase 2: Create the notebook generator script
Create ./zne-live-demo/build_notebook.wls

This script builds a Notebook expression and exports it to ./zne-live-demo/ZNE_Interactive.nb

The notebook must contain these sections, each demonstrating a different Mathematica capability:

## Section 1: Title & Introduction
- Title cell: "Zero-Noise Extrapolation — Interactive Explorer"
- Subtitle cell: "Quantum Error Mitigation with Mathematica 14.3"
- Text cell: Brief 3-line explanation of ZNE

## Section 2: Setup
- Input cell that loads the ZNE package:
  Get[FileNameJoin[{NotebookDirectory[], "src", "ZNEDemo.wl"}]]
- Input cell that prints version info ($VersionNumber, $SystemID)

## Section 3: Interactive ZNE Explorer (MAIN SHOWCASE — Manipulate)
This is the centrepiece. Create a Manipulate with:

Controls:
- Slider: p0 (base noise) from 0 to 0.15, step 0.005, default 0.03
- PopupMenu: noiseModel — "DepolarizingEnd" or "DepolarizingPerGate"
- SetterBar: lambdaList — {1,2,3} or {1,2,3,4} or {1,1.5,2,2.5,3,3.5,4}
- SetterBar: polyOrd — 1, 2, 3
- Slider: nPts (resolution) from 15 to 60, step 5, default 30
- Slider: thetaProbe from 0.2 to 6.0, step 0.1, default 1.5

Body of Manipulate — use Module to compute and display a TabView with 3 tabs:

**Tab "Main Plot":**
- Show[ ListLinePlot of Ideal (thick black) + all Noisy curves (colors), ListLinePlot of ZNE (thick red dashed) ]
- PlotLabel, AxesLabel, PlotLegends, ImageSize->580, GridLines->Automatic

**Tab "Error Analysis":**
- A Column with two items:
  1. ListLinePlot of absolute error: noisy(λ=1) vs ZNE, with Filling->Axis on the noisy curve to highlight the error area
  2. A styled Grid/Panel showing numeric summary:
     - Noisy MAE (NumberForm, 6 digits)
     - ZNE MAE (NumberForm, 6 digits)  
     - Improvement % (NumberForm, 3 digits)
     - Verdict: Style["PASS", Green, Bold] or Style["FAIL", Red, Bold]

**Tab "Extrapolation Fit":**
- Show[ ListPlot of E(λ) data points (large dots), Plot of polynomial fit (red dashed curve), ListPlot of extrapolated point at λ=0 (large red dot) ]
- Epilog: Text annotation showing "ZNE = <value>" and "Ideal = <value>"
- PlotRange including λ=0

Use Paneled->True, FrameLabel, and a clean layout.

## Section 4: Static Publication Figure
An input cell that generates a single polished figure for publications:
- Use a fixed parameter set (p0=0.04, lambdas={1,2,3,4}, order=2, 40 points)
- Show ideal + noisy + ZNE in a single plot
- Use PlotTheme->"Scientific", Frame->True, FrameLabel, PlotLabel
- Use specific PlotStyle with colour choices suitable for colour-blind readers
- Assign to variable pubFig
- Display it

## Section 5: Export Cell
An input cell that:
- Creates an "exports" directory next to the notebook
- Exports pubFig as PNG (150 dpi) and PDF (vector)
- Prints confirmation with file paths

## Section 6: Quick Reference
A Text cell with a formatted summary of the ZNE API:
- MakeCircuit, IdealExpectation, NoisyExpectation, ZNEEstimate, GenerateSweep
- Supported options table

Important: The Manipulate cell must use Defer or equivalent so that when the notebook is opened, the code is visible but not auto-evaluated — the user clicks to evaluate.

Use ExpressionCell[Defer[...], "Input"] for all Input cells.

# Phase 3: Run the generator
Execute: wolframscript -file "./zne-live-demo/build_notebook.wls"
Allow up to 60 seconds. Verify the .nb file was created and is >10KB.

# Phase 4: Open the notebook
Open the generated ZNE_Interactive.nb in Mathematica so the audience can see it:
  Start-Process ".\zne-live-demo\ZNE_Interactive.nb"

# Deliverables
List:
- zne-live-demo/src/ZNEDemo.wl
- zne-live-demo/build_notebook.wls
- zne-live-demo/ZNE_Interactive.nb
