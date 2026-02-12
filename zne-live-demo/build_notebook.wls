#!/usr/bin/env wolframscript
(* build_notebook.wls — Generates the ZNE Interactive Explorer notebook *)
(* Strategy: build all Input cells using ToBoxes[Defer[...]] via ToExpression *)

Print["[build_notebook] Starting notebook generation..."];

(* Helper: create an Input cell from a code string that will NOT auto-evaluate *)
makeInputCell[codeString_String] := Module[{expr, boxes},
  expr = ToExpression[codeString, InputForm, Defer];
  boxes = ToBoxes[expr, StandardForm];
  Cell[BoxData[boxes], "Input"]
];

(* Helper: create an Input cell from a code string — compound (;-separated) *)
makeInputCellRaw[codeString_String] := Cell[BoxData[codeString], "Input"];

(* ===== Section 1: Title & Introduction ===== *)
sec1 = {
  Cell["Zero-Noise Extrapolation \[LongDash] Interactive Explorer", "Title"],
  Cell["Quantum Error Mitigation with Mathematica 14.3", "Subtitle"],
  Cell[
    "Zero-Noise Extrapolation (ZNE) is a leading quantum error mitigation technique. \
The idea: run a circuit at several amplified noise levels (\[Lambda] = 1, 2, 3, \[Ellipsis]), \
then extrapolate back to the zero-noise limit (\[Lambda] \[Rule] 0) using polynomial fitting. \
This notebook lets you explore ZNE interactively, powered by the ZNEDemo.wl package.",
    "Text"
  ]
};

(* ===== Section 2: Setup ===== *)
sec2 = {
  Cell["Setup", "Section"],
  makeInputCell["Get[FileNameJoin[{NotebookDirectory[], \"src\", \"ZNEDemo.wl\"}]]"],
  makeInputCell["Print[\"Mathematica \" <> ToString[$VersionNumber] <> \" on \" <> $SystemID]"]
};

(* ===== Section 3: Interactive ZNE Explorer ===== *)

manipulateString = "Manipulate[
 Module[{thetaList, sweep, idealPts, noisyPtsAll, znePts, lambdaColors,
   mainPlot, noisyLam1, zneAbs, noisyMAE, zneMAE, improv, verdict,
   errorPlot, summaryGrid, errorTab,
   noisyAtProbe, zneAtProbe, idealAtProbe, fitData, polyOrder, fitExpr, lam, extrapTab},

  thetaList = N[Range[0.1, 6.0, (6.0 - 0.1)/Max[nPts - 1, 1]]];

  sweep = ZNE`GenerateSweep[thetaList, lambdaList, polyOrd,
    \"NoiseModel\" -> noiseModel, \"BaseNoise\" -> p0];

  idealPts = sweep[\"IdealData\"];
  noisyPtsAll = sweep[\"NoisyData\"];
  znePts = sweep[\"ZNEData\"];

  lambdaColors = Table[
    ColorData[\"Rainbow\"][(i - 1)/Max[Length[lambdaList] - 1, 1]],
    {i, Length[lambdaList]}];

  mainPlot = Show[
    ListLinePlot[
      Prepend[Table[noisyPtsAll[lambdaList[[i]]], {i, Length[lambdaList]}], idealPts],
      PlotStyle -> Prepend[
        Table[{lambdaColors[[i]], AbsoluteThickness[1.5]}, {i, Length[lambdaList]}],
        {Black, AbsoluteThickness[2.5]}],
      PlotLegends -> Prepend[
        Table[\"\\[Lambda]=\" <> ToString[lambdaList[[i]]], {i, Length[lambdaList]}],
        \"Ideal\"]],
    ListLinePlot[znePts,
      PlotStyle -> {Red, Thick, Dashed},
      PlotLegends -> {\"ZNE\"}],
    PlotLabel -> \"ZNE Interactive Explorer\",
    AxesLabel -> {\"\\[Theta]\", \"\\[LeftAngleBracket]Z\\[RightAngleBracket]\"},
    ImageSize -> 580, GridLines -> Automatic];

  noisyLam1 = noisyPtsAll[lambdaList[[1]]];

  zneAbs = MapThread[{#1[[1]], Abs[#1[[2]] - #2[[2]]]} &, {idealPts, znePts}];

  noisyMAE = Mean[MapThread[Abs[#1[[2]] - #2[[2]]] &, {idealPts, noisyLam1}]];
  zneMAE = Mean[zneAbs[[All, 2]]];

  improv = If[noisyMAE > 0, 100.0*(1 - zneMAE/noisyMAE), 0];
  verdict = If[zneMAE < noisyMAE,
    Style[\"PASS\", Darker[Green], Bold],
    Style[\"FAIL\", Red, Bold]];

  errorPlot = ListLinePlot[
    {MapThread[{#1[[1]], Abs[#1[[2]] - #2[[2]]]} &, {idealPts, noisyLam1}], zneAbs},
    PlotStyle -> {{Blue, Thick}, {Red, Thick, Dashed}},
    PlotLegends -> {\"Noisy (\\[Lambda]=1)\", \"ZNE\"},
    Filling -> {1 -> Axis},
    AxesLabel -> {\"\\[Theta]\", \"Abs Error\"},
    PlotLabel -> \"Absolute Error vs Ideal\",
    ImageSize -> 560];

  summaryGrid = Panel[
    Grid[{
      {Style[\"Metric\", Bold], Style[\"Value\", Bold]},
      {\"Noisy MAE\", NumberForm[noisyMAE, 6]},
      {\"ZNE MAE\", NumberForm[zneMAE, 6]},
      {\"Improvement\", Row[{NumberForm[improv, 3], \"%\"}]},
      {\"Verdict\", verdict}},
      Frame -> All, Alignment -> Center, Spacings -> {2, 1}],
    Style[\"Error Summary\", Bold, 12]];

  errorTab = Column[{errorPlot, summaryGrid}, Spacings -> 1];

  noisyAtProbe = Table[
    {ll, ZNE`NoisyExpectation[thetaProbe, ll,
      \"NoiseModel\" -> noiseModel, \"BaseNoise\" -> p0]},
    {ll, lambdaList}];

  zneAtProbe = ZNE`ZNEEstimate[thetaProbe, lambdaList, polyOrd,
    \"NoiseModel\" -> noiseModel, \"BaseNoise\" -> p0];

  idealAtProbe = ZNE`IdealExpectation[thetaProbe];

  fitData = noisyAtProbe;
  polyOrder = Min[polyOrd, Length[lambdaList] - 1];
  fitExpr = Fit[fitData, Table[lam^k, {k, 0, polyOrder}], lam];

  extrapTab = Show[
    ListPlot[fitData,
      PlotStyle -> {PointSize[0.02], Blue},
      PlotLegends -> {\"E(\\[Lambda]) data\"}],
    Plot[fitExpr, {lam, 0, Max[lambdaList] + 0.5},
      PlotStyle -> {Red, Dashed, Thick},
      PlotLegends -> {\"Poly fit\"}],
    ListPlot[{{0, zneAtProbe}},
      PlotStyle -> {Red, PointSize[0.025]},
      PlotLegends -> {\"ZNE (\\[Lambda]\\[Rule]0)\"}],
    PlotLabel -> \"Extrapolation at \\[Theta] = \" <> ToString[thetaProbe],
    AxesLabel -> {\"\\[Lambda]\", \"E(\\[Lambda])\"},
    ImageSize -> 560,
    Epilog -> {Text[
      Style[\"ZNE = \" <> ToString[NumberForm[zneAtProbe, 5]] <>
        \"\\nIdeal = \" <> ToString[NumberForm[idealAtProbe, 5]], 11, Bold],
      Scaled[{0.75, 0.85}]]},
    PlotRange -> All];

  TabView[{\"Main Plot\" -> mainPlot,
    \"Error Analysis\" -> errorTab,
    \"Extrapolation Fit\" -> extrapTab}]
 ],
 {{p0, 0.03, \"Base Noise p\\_0\"}, 0, 0.15, 0.005},
 {{noiseModel, \"DepolarizingEnd\", \"Noise Model\"},
   {\"DepolarizingEnd\", \"DepolarizingPerGate\"}},
 {{lambdaList, {1, 2, 3}, \"\\[Lambda] Values\"},
   {{1, 2, 3}, {1, 2, 3, 4}, {1, 1.5, 2, 2.5, 3, 3.5, 4}}},
 {{polyOrd, 2, \"Poly Order\"}, {1, 2, 3}, SetterBar},
 {{nPts, 30, \"Resolution\"}, 15, 60, 5},
 {{thetaProbe, 1.5, \"\\[Theta] Probe\"}, 0.2, 6.0, 0.1},
 Paneled -> True,
 FrameLabel -> \"Zero-Noise Extrapolation Explorer\"]";

sec3 = {
  Cell["Interactive ZNE Explorer", "Section"],
  Cell["Evaluate the cell below and use the sliders and controls to explore how ZNE \
corrects noisy quantum expectation values. This is the main showcase of this notebook.", "Text"],
  makeInputCell[manipulateString]
};

(* ===== Section 4: Static Publication Figure ===== *)
pubString = "Module[{thetaList, sweep, idealPts, noisyPts, znePts},
  thetaList = N[Range[0.1, 6.0, (6.0 - 0.1)/39]];
  sweep = ZNE`GenerateSweep[thetaList, {1, 2, 3, 4}, 2, \"BaseNoise\" -> 0.04];
  idealPts = sweep[\"IdealData\"];
  noisyPts = sweep[\"NoisyData\"];
  znePts = sweep[\"ZNEData\"];
  pubFig = Show[
    ListLinePlot[{idealPts, noisyPts[1], noisyPts[2], znePts},
      PlotTheme -> \"Scientific\", Frame -> True,
      FrameLabel -> {\"\\[Theta] (rad)\", \"\\[LeftAngleBracket]Z\\[RightAngleBracket]\"},
      PlotLabel -> Style[\"ZNE Error Mitigation\", 14, Bold],
      PlotStyle -> {{Black, Thick},
        {ColorData[\"ColorblindSafe\"][1]},
        {ColorData[\"ColorblindSafe\"][2]},
        {Red, Thick, Dashed}},
      PlotLegends -> Placed[{\"Ideal\", \"Noisy (\\[Lambda]=1)\",
        \"Noisy (\\[Lambda]=2)\", \"ZNE\"}, Right],
      ImageSize -> 600]];
  pubFig]";

sec4 = {
  Cell["Publication Figure", "Section"],
  Cell["Generate a publication-quality figure with fixed parameters \
(p0=0.04, \[Lambda]={1,2,3,4}, order=2, 40 points). \
Colour scheme chosen for colour-blind accessibility.", "Text"],
  makeInputCell[pubString]
};

(* ===== Section 5: Export Cell ===== *)
exportString = "Module[{exportDir},
  exportDir = FileNameJoin[{NotebookDirectory[], \"exports\"}];
  If[!DirectoryQ[exportDir], CreateDirectory[exportDir]];
  Export[FileNameJoin[{exportDir, \"ZNE_Figure.png\"}], pubFig, ImageResolution -> 150];
  Export[FileNameJoin[{exportDir, \"ZNE_Figure.pdf\"}], pubFig];
  Print[\"Exported to:\\n\" <>
    FileNameJoin[{exportDir, \"ZNE_Figure.png\"}] <> \"\\n\" <>
    FileNameJoin[{exportDir, \"ZNE_Figure.pdf\"}]]]";

sec5 = {
  Cell["Export", "Section"],
  Cell["Run this cell after generating pubFig above. Exports PNG (150 dpi) and PDF (vector).", "Text"],
  makeInputCell[exportString]
};

(* ===== Section 6: Quick Reference ===== *)
sec6 = {
  Cell["Quick Reference", "Section"],
  Cell[TextData[{
    StyleBox["ZNE API Summary\n\n", FontWeight -> "Bold", FontSize -> 13],
    StyleBox["MakeCircuit[theta, nQubits, depth]", FontFamily -> "Courier"],
    " \[LongDash] Build a parameterized quantum circuit\n",
    StyleBox["IdealExpectation[theta, opts]", FontFamily -> "Courier"],
    " \[LongDash] Noiseless expectation value\n",
    StyleBox["NoisyExpectation[theta, lambda, opts]", FontFamily -> "Courier"],
    " \[LongDash] Noisy expectation at noise scale \[Lambda]\n",
    StyleBox["ZNEEstimate[theta, lambdaList, order, opts]", FontFamily -> "Courier"],
    " \[LongDash] Extrapolated (mitigated) estimate\n",
    StyleBox["GenerateSweep[thetaList, lambdaList, order, opts]", FontFamily -> "Courier"],
    " \[LongDash] Full parameter sweep returning Association\n\n",
    StyleBox["Supported Options:\n", FontWeight -> "Bold"],
    "  \"NoiseModel\" \[Rule] \"DepolarizingEnd\" | \"DepolarizingPerGate\"\n",
    "  \"BaseNoise\" \[Rule] 0.02  (base depolarizing probability)\n",
    "  \"Shots\" \[Rule] Infinity  (Infinity = analytic, finite = sampling noise)\n",
    "  \"Seed\" \[Rule] 1234  (RNG seed for shot noise)\n",
    "  \"Observable\" \[Rule] \"PauliZ\"\n",
    "  \"State\" \[Rule] Automatic"
  }], "Text"]
};

(* ===== Assemble Notebook ===== *)
allCells = Join[sec1, sec2, sec3, sec4, sec5, sec6];

nb = Notebook[allCells,
  WindowTitle -> "ZNE Interactive Explorer",
  Saveable -> True,
  WindowSize -> {900, 800},
  StyleDefinitions -> "Default.nb"
];

(* ===== Export ===== *)
outPath = FileNameJoin[{DirectoryName[$InputFileName], "ZNE_Interactive.nb"}];
Print["[build_notebook] Exporting to: " <> outPath];
Export[outPath, nb, "NB"];

Print["[build_notebook] File size: " <> ToString[FileSize[outPath]] <> " bytes"];
Print["[build_notebook] Done!"];
