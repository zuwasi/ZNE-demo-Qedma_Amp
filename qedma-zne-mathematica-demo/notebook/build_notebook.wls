(* Build ZNE_Demo.nb as a raw Notebook expression — no front end needed *)

nbDir = DirectoryName[$InputFileName];
nbPath = FileNameJoin[{nbDir, "ZNE_Demo.nb"}];

nbExpr = Notebook[{

  (* ===== TITLE ===== *)
  Cell["Zero-Noise Extrapolation (ZNE) Interactive Demo", "Title"],
  Cell["An end-to-end demonstrator for ZNE error mitigation.\nInspired by Temme, Bravyi & Gambetta (arXiv:1612.02058).\nBuilt with Mathematica 14.3 and Wolfram QuantumFramework.", "Subtitle"],

  (* ===== REFERENCES ===== *)
  Cell[CellGroupData[{
    Cell["References", "Section"],
    Cell["1. Temme, Bravyi, Gambetta \[Dash] \"Error Mitigation for Short-Depth Quantum Circuits\" (arXiv:1612.02058)\n   https://arxiv.org/pdf/1612.02058\n\n2. Kandala et al. \[Dash] \"Error mitigation extends the computational reach...\" (arXiv:1805.04492)\n   https://arxiv.org/abs/1805.04492", "Text"]
  }, Open]],

  (* ===== ENVIRONMENT ===== *)
  Cell[CellGroupData[{
    Cell["Environment", "Section"],
    Cell[BoxData[
      RowBox[{"Print", "[", 
        RowBox[{"\"Mathematica Version: \"", ",", "$VersionNumber"}], 
      "]"}]
    ], "Input"],
    Cell[BoxData[
      RowBox[{"Print", "[", 
        RowBox[{"\"System: \"", ",", "$SystemID"}], 
      "]"}]
    ], "Input"],
    Cell[BoxData[
      RowBox[{"Print", "[", 
        RowBox[{"\"QuantumFramework: \"", ",", 
          RowBox[{"PacletFind", "[", "\"Wolfram/QuantumFramework\"", "]"}]
        }], 
      "]"}]
    ], "Input"]
  }, Open]],

  (* ===== LOAD PACKAGE ===== *)
  Cell[CellGroupData[{
    Cell["Load ZNE Package", "Section"],
    Cell[BoxData[
      RowBox[{
        RowBox[{"Get", "[", 
          RowBox[{"FileNameJoin", "[", 
            RowBox[{"{", 
              RowBox[{
                RowBox[{"NotebookDirectory", "[", "]"}], 
                ",", "\"..\"", 
                ",", "\"src\"", 
                ",", "\"ZNEDemo.wl\""
              }], 
            "}"}], 
          "]"}], 
        "]"}],
        ";",
        RowBox[{"Print", "[", "\"ZNE package loaded.\"", "]"}]
      }]
    ], "Input"]
  }, Open]],

  (* ===== INTERACTIVE DEMO ===== *)
  Cell[CellGroupData[{
    Cell["Interactive ZNE Demo", "Section"],
    Cell["Use the controls below to explore how ZNE mitigates depolarizing noise on a Ry(\[Theta]) circuit.\n\nThree plots are shown:\n  1. Main: Ideal vs Noisy vs ZNE expectation curves\n  2. Error: Absolute error of Noisy and ZNE vs Ideal\n  3. Fit: Local polynomial extrapolation at the probe angle", "Text"],
    Cell[BoxData[
      RowBox[{"Manipulate", "[", "\n",
        RowBox[{
          RowBox[{"Module", "[", 
            RowBox[{
              RowBox[{"{", "sweepResult, idealPts, znePts, mainPlot, errorPlot, noisyErrors, zneErrors, fitPlot, fitData, fitLambdas, fitMeans, polyOrder2, fit, lam, extrapolated", "}"}],
              ",", "\n",
              RowBox[{
                RowBox[{"sweepResult", "=", 
                  RowBox[{"ZNE`GenerateSweep", "[", "\n",
                    RowBox[{
                      RowBox[{"N", "[", RowBox[{"Range", "[", RowBox[{"0", ",", RowBox[{"2", " ", "Pi"}], ",", RowBox[{"2", " ", RowBox[{"Pi", "/", "nPts"}]}]}], "]"}], "]"}],
                      ",", "lambdaList", ",", "polyOrd", ",", "\n",
                      RowBox[{"\"NoiseModel\"", "->", "noiseModel"}], ",",
                      RowBox[{"\"BaseNoise\"", "->", "p0"}], ",",
                      RowBox[{"\"Shots\"", "->", "Infinity"}]
                    }],
                  "]"}]
                }], ";", "\n",

                RowBox[{"idealPts", "=", RowBox[{"sweepResult", "[", "\"IdealData\"", "]"}]}], ";",
                RowBox[{"znePts", "=", RowBox[{"sweepResult", "[", "\"ZNEData\"", "]"}]}], ";", "\n",

                (* Main Plot *)
                RowBox[{"mainPlot", "=", 
                  RowBox[{"Show", "[", "\n",
                    RowBox[{
                      RowBox[{"ListLinePlot", "[", 
                        RowBox[{
                          RowBox[{"Prepend", "[", RowBox[{RowBox[{"Values", "[", RowBox[{"sweepResult", "[", "\"NoisyData\"", "]"}], "]"}], ",", "idealPts"}], "]"}], ",", "\n",
                          RowBox[{"PlotLegends", "->", RowBox[{"Prepend", "[", RowBox[{RowBox[{"Table", "[", RowBox[{RowBox[{"\"\\[Lambda]=\"", "<>", RowBox[{"ToString", "[", "l", "]"}]}], ",", RowBox[{"{", RowBox[{"l", ",", "lambdaList"}], "}"}]}], "]"}], ",", "\"Ideal\""}], "]"}]}], ",", "\n",
                          RowBox[{"PlotLabel", "->", "\"ZNE: Expectation vs \\[Theta]\""}], ",",
                          RowBox[{"AxesLabel", "->", RowBox[{"{", RowBox[{"\"\\[Theta]\"", ",", "\"\\[LeftAngleBracket]Z\\[RightAngleBracket]\""}], "}"}]}], ",",
                          RowBox[{"ImageSize", "->", "600"}], ",",
                          RowBox[{"PlotStyle", "->", RowBox[{"{", RowBox[{RowBox[{"{", RowBox[{"Thick", ",", "Black"}], "}"}], ",", "Automatic"}], "}"}]}]
                        }],
                      "]"}], ",", "\n",
                      RowBox[{"ListLinePlot", "[", RowBox[{"znePts", ",", RowBox[{"PlotStyle", "->", RowBox[{"{", RowBox[{"Thick", ",", "Red", ",", "Dashed"}], "}"}]}], ",", RowBox[{"PlotLegends", "->", RowBox[{"{", "\"ZNE\"", "}"}]}]}], "]"}]
                    }],
                  "]"}]
                }], ";", "\n",

                (* Error Plot *)
                RowBox[{"noisyErrors", "=", 
                  RowBox[{"MapThread", "[", 
                    RowBox[{
                      RowBox[{"Function", "[", RowBox[{RowBox[{"{", RowBox[{"ideal", ",", "noisy"}], "}"}], ",", RowBox[{"{", RowBox[{RowBox[{"ideal", "[", RowBox[{"[", "1", "]"}], "]"}], ",", RowBox[{"Abs", "[", RowBox[{RowBox[{"noisy", "[", RowBox[{"[", "2", "]"}], "]"}], "-", RowBox[{"ideal", "[", RowBox[{"[", "2", "]"}], "]"}]}], "]"}]}], "}"}]}], "]"}], ",", "\n",
                      RowBox[{"{", RowBox[{"idealPts", ",", RowBox[{"sweepResult", "[", RowBox[{"\"NoisyData\"", ",", RowBox[{"First", "[", "lambdaList", "]"}]}], "]"}]}], "}"}]
                    }],
                  "]"}]
                }], ";",
                RowBox[{"zneErrors", "=", 
                  RowBox[{"MapThread", "[", 
                    RowBox[{
                      RowBox[{"Function", "[", RowBox[{RowBox[{"{", RowBox[{"ideal", ",", "zne"}], "}"}], ",", RowBox[{"{", RowBox[{RowBox[{"ideal", "[", RowBox[{"[", "1", "]"}], "]"}], ",", RowBox[{"Abs", "[", RowBox[{RowBox[{"zne", "[", RowBox[{"[", "2", "]"}], "]"}], "-", RowBox[{"ideal", "[", RowBox[{"[", "2", "]"}], "]"}]}], "]"}]}], "}"}]}], "]"}], ",",
                      RowBox[{"{", RowBox[{"idealPts", ",", "znePts"}], "}"}]
                    }],
                  "]"}]
                }], ";", "\n",

                RowBox[{"errorPlot", "=", 
                  RowBox[{"ListLinePlot", "[", 
                    RowBox[{
                      RowBox[{"{", RowBox[{"noisyErrors", ",", "zneErrors"}], "}"}], ",", "\n",
                      RowBox[{"PlotLegends", "->", RowBox[{"{", RowBox[{"\"Noisy (\\[Lambda]=1)\"", ",", "\"ZNE\""}], "}"}]}], ",",
                      RowBox[{"PlotLabel", "->", "\"Absolute Error vs \\[Theta]\""}], ",",
                      RowBox[{"AxesLabel", "->", RowBox[{"{", RowBox[{"\"\\[Theta]\"", ",", "\"|Error|\""}], "}"}]}], ",",
                      RowBox[{"ImageSize", "->", "600"}], ",",
                      RowBox[{"PlotStyle", "->", RowBox[{"{", RowBox[{RowBox[{"{", RowBox[{"Thick", ",", "Orange"}], "}"}], ",", RowBox[{"{", RowBox[{"Thick", ",", "Red", ",", "Dashed"}], "}"}]}], "}"}]}]
                    }],
                  "]"}]
                }], ";", "\n",

                (* Local Fit *)
                RowBox[{"fitLambdas", "=", RowBox[{"N", "[", "lambdaList", "]"}]}], ";",
                RowBox[{"fitMeans", "=", 
                  RowBox[{"Table", "[", 
                    RowBox[{
                      RowBox[{"ZNE`NoisyExpectation", "[", RowBox[{"thetaProbe", ",", "l", ",", RowBox[{"\"NoiseModel\"", "->", "noiseModel"}], ",", RowBox[{"\"BaseNoise\"", "->", "p0"}]}], "]"}], ",",
                      RowBox[{"{", RowBox[{"l", ",", "fitLambdas"}], "}"}]
                    }],
                  "]"}]
                }], ";",
                RowBox[{"fitData", "=", RowBox[{"Transpose", "[", RowBox[{"{", RowBox[{"fitLambdas", ",", "fitMeans"}], "}"}], "]"}]}], ";",
                RowBox[{"polyOrder2", "=", RowBox[{"Min", "[", RowBox[{"polyOrd", ",", RowBox[{RowBox[{"Length", "[", "fitLambdas", "]"}], "-", "1"}]}], "]"}]}], ";",
                RowBox[{"fit", "=", RowBox[{"Fit", "[", RowBox[{"fitData", ",", RowBox[{"Table", "[", RowBox[{RowBox[{"lam", "^", "k"}], ",", RowBox[{"{", RowBox[{"k", ",", "0", ",", "polyOrder2"}], "}"}]}], "]"}], ",", "lam"}], "]"}]}], ";",
                RowBox[{"extrapolated", "=", RowBox[{"fit", "/.", RowBox[{"lam", "->", "0"}]}]}], ";", "\n",

                RowBox[{"fitPlot", "=", 
                  RowBox[{"Show", "[", "\n",
                    RowBox[{
                      RowBox[{"ListPlot", "[", RowBox[{"fitData", ",", RowBox[{"PlotStyle", "->", RowBox[{"{", RowBox[{"PointSize", "[", "0.02", "]"}], "}"}]}], ",", RowBox[{"PlotLabel", "->", RowBox[{"\"Local Fit at \\[Theta]=\"", "<>", RowBox[{"ToString", "[", RowBox[{"NumberForm", "[", RowBox[{"thetaProbe", ",", "3"}], "]"}], "]"}]}]}], ",", RowBox[{"AxesLabel", "->", RowBox[{"{", RowBox[{"\"\\[Lambda]\"", ",", "\"E(\\[Lambda])\""}], "}"}]}], ",", RowBox[{"ImageSize", "->", "500"}]}], "]"}], ",", "\n",
                      RowBox[{"Plot", "[", RowBox[{"fit", ",", RowBox[{"{", RowBox[{"lam", ",", "0", ",", RowBox[{"Max", "[", "fitLambdas", "]"}]}], "}"}], ",", RowBox[{"PlotStyle", "->", RowBox[{"{", RowBox[{"Red", ",", "Dashed"}], "}"}]}]}], "]"}], ",", "\n",
                      RowBox[{"ListPlot", "[", RowBox[{RowBox[{"{", RowBox[{"{", RowBox[{"0", ",", "extrapolated"}], "}"}], "}"}], ",", RowBox[{"PlotStyle", "->", RowBox[{"{", RowBox[{"Red", ",", RowBox[{"PointSize", "[", "0.03", "]"}]}], "}"}]}]}], "]"}], ",", "\n",
                      RowBox[{"Epilog", "->", RowBox[{"{", RowBox[{"Text", "[", RowBox[{RowBox[{"\"ZNE = \"", "<>", RowBox[{"ToString", "[", RowBox[{"NumberForm", "[", RowBox[{"extrapolated", ",", "4"}], "]"}], "]"}]}], ",", RowBox[{"{", RowBox[{"0.5", ",", "extrapolated"}], "}"}]}], "]"}], "}"}]}]
                    }],
                  "]"}]
                }], ";", "\n",

                RowBox[{"Column", "[", RowBox[{RowBox[{"{", RowBox[{"mainPlot", ",", "errorPlot", ",", "fitPlot"}], "}"}], ",", RowBox[{"Spacings", "->", "2"}]}], "]"}]
              }]
            }],
          "]"}],

          (* Controls *)
          ",", "\n",
          RowBox[{"{", RowBox[{RowBox[{"{", RowBox[{"p0", ",", "0.02", ",", "\"Base Noise\""}], "}"}], ",", "0", ",", "0.1", ",", "0.005"}], "}"}], ",",
          RowBox[{"{", RowBox[{RowBox[{"{", RowBox[{"noiseModel", ",", "\"DepolarizingEnd\"", ",", "\"Noise Model\""}], "}"}], ",", RowBox[{"{", RowBox[{"\"DepolarizingEnd\"", ",", "\"DepolarizingPerGate\""}], "}"}]}], "}"}], ",",
          RowBox[{"{", RowBox[{RowBox[{"{", RowBox[{"lambdaList", ",", RowBox[{"{", RowBox[{"1", ",", "2", ",", "3", ",", "4"}], "}"}], ",", "\"\\[Lambda] List\""}], "}"}], ",", RowBox[{"{", RowBox[{RowBox[{RowBox[{"{", RowBox[{"1", ",", "2", ",", "3", ",", "4"}], "}"}], "->", "\"{1,2,3,4}\""}], ",", RowBox[{RowBox[{"{", RowBox[{"1", ",", "1.5", ",", "2", ",", "2.5", ",", "3"}], "}"}], "->", "\"{1,1.5,2,2.5,3}\""}]}], "}"}]}], "}"}], ",",
          RowBox[{"{", RowBox[{RowBox[{"{", RowBox[{"polyOrd", ",", "2", ",", "\"Poly Order\""}], "}"}], ",", RowBox[{"{", RowBox[{"1", ",", "2", ",", "3"}], "}"}]}], "}"}], ",",
          RowBox[{"{", RowBox[{RowBox[{"{", RowBox[{"nPts", ",", "30", ",", "\"Theta Points\""}], "}"}], ",", "10", ",", "80", ",", "5"}], "}"}], ",",
          RowBox[{"{", RowBox[{RowBox[{"{", RowBox[{"thetaProbe", ",", "1.0", ",", "\"Probe \\[Theta]\""}], "}"}], ",", "0.1", ",", "6.0", ",", "0.1"}], "}"}]
        }],
      "]"}]
    ], "Input"]
  }, Open]],

  (* ===== VALIDATION ===== *)
  Cell[CellGroupData[{
    Cell["Validation Checks", "Section"],
    Cell["Automated pass/fail acceptance checks.", "Text"],
    Cell[BoxData[
      RowBox[{"Module", "[", 
        RowBox[{
          RowBox[{"{", "thetaTest, lambdas", "}"}], ",", "\n",
          RowBox[{
            RowBox[{"thetaTest", "=", RowBox[{"N", "[", RowBox[{"Range", "[", RowBox[{"0.1", ",", RowBox[{"2", " ", "Pi"}], ",", "0.3"}], "]"}], "]"}]}], ";",
            RowBox[{"lambdas", "=", RowBox[{"{", RowBox[{"1", ",", "2", ",", "3", ",", "4"}], "}"}]}], ";", "\n",

            RowBox[{"Module", "[", RowBox[{RowBox[{"{", RowBox[{"sweep", ",", "maxErr"}], "}"}], ",",
              RowBox[{
                RowBox[{"sweep", "=", RowBox[{"ZNE`GenerateSweep", "[", RowBox[{"thetaTest", ",", "lambdas", ",", "2", ",", RowBox[{"\"BaseNoise\"", "->", "0.001"}]}], "]"}]}], ";",
                RowBox[{"maxErr", "=", RowBox[{"Max", "[", RowBox[{"Abs", "[", RowBox[{RowBox[{"sweep", "[", RowBox[{"\"ZNEData\"", ",", "All", ",", "2"}], "]"}], "-", RowBox[{"sweep", "[", RowBox[{"\"IdealData\"", ",", "All", ",", "2"}], "]"}]}], "]"}], "]"}]}], ";",
                RowBox[{"Print", "[", RowBox[{"\"Check 1 (low noise): max|ZNE-Ideal| = \"", ",", "maxErr", ",", RowBox[{"If", "[", RowBox[{RowBox[{"maxErr", "<", "0.01"}], ",", "\" PASS\"", ",", "\" FAIL\""}], "]"}]}], "]"}]
              }]
            }], "]"}], ";", "\n",

            RowBox[{"Module", "[", RowBox[{RowBox[{"{", RowBox[{"sweep", ",", "noisyErr", ",", "zneErr", ",", "improvement"}], "}"}], ",",
              RowBox[{
                RowBox[{"sweep", "=", RowBox[{"ZNE`GenerateSweep", "[", RowBox[{"thetaTest", ",", "lambdas", ",", "2", ",", RowBox[{"\"BaseNoise\"", "->", "0.05"}]}], "]"}]}], ";",
                RowBox[{"noisyErr", "=", RowBox[{"Mean", "[", RowBox[{"Abs", "[", RowBox[{RowBox[{"sweep", "[", RowBox[{"\"NoisyData\"", ",", "1", ",", "All", ",", "2"}], "]"}], "-", RowBox[{"sweep", "[", RowBox[{"\"IdealData\"", ",", "All", ",", "2"}], "]"}]}], "]"}], "]"}]}], ";",
                RowBox[{"zneErr", "=", RowBox[{"Mean", "[", RowBox[{"Abs", "[", RowBox[{RowBox[{"sweep", "[", RowBox[{"\"ZNEData\"", ",", "All", ",", "2"}], "]"}], "-", RowBox[{"sweep", "[", RowBox[{"\"IdealData\"", ",", "All", ",", "2"}], "]"}]}], "]"}], "]"}]}], ";",
                RowBox[{"improvement", "=", RowBox[{RowBox[{"(", RowBox[{"noisyErr", "-", "zneErr"}], ")"}], "/", "noisyErr"}]}], ";",
                RowBox[{"Print", "[", RowBox[{"\"Check 2: Noisy MAE=\"", ",", RowBox[{"NumberForm", "[", RowBox[{"noisyErr", ",", "4"}], "]"}], ",", "\" | ZNE MAE=\"", ",", RowBox[{"NumberForm", "[", RowBox[{"zneErr", ",", "4"}], "]"}], ",", "\" | \"", ",", RowBox[{"NumberForm", "[", RowBox[{RowBox[{"100", " ", "improvement"}], ",", "3"}], "]"}], ",", "\"%\"", ",", RowBox[{"If", "[", RowBox[{RowBox[{"zneErr", "<", "noisyErr"}], ",", "\" PASS\"", ",", "\" FAIL\""}], "]"}]}], "]"}]
              }]
            }], "]"}], ";", "\n",

            RowBox[{"Module", "[", RowBox[{RowBox[{"{", RowBox[{"sweepE", ",", "sweepP", ",", "endErr", ",", "pgErr"}], "}"}], ",",
              RowBox[{
                RowBox[{"sweepE", "=", RowBox[{"ZNE`GenerateSweep", "[", RowBox[{"thetaTest", ",", "lambdas", ",", "2", ",", RowBox[{"\"NoiseModel\"", "->", "\"DepolarizingEnd\""}], ",", RowBox[{"\"BaseNoise\"", "->", "0.03"}]}], "]"}]}], ";",
                RowBox[{"sweepP", "=", RowBox[{"ZNE`GenerateSweep", "[", RowBox[{"thetaTest", ",", "lambdas", ",", "2", ",", RowBox[{"\"NoiseModel\"", "->", "\"DepolarizingPerGate\""}], ",", RowBox[{"\"BaseNoise\"", "->", "0.03"}]}], "]"}]}], ";",
                RowBox[{"endErr", "=", RowBox[{"Mean", "[", RowBox[{"Abs", "[", RowBox[{RowBox[{"sweepE", "[", RowBox[{"\"NoisyData\"", ",", "1", ",", "All", ",", "2"}], "]"}], "-", RowBox[{"sweepE", "[", RowBox[{"\"IdealData\"", ",", "All", ",", "2"}], "]"}]}], "]"}], "]"}]}], ";",
                RowBox[{"pgErr", "=", RowBox[{"Mean", "[", RowBox[{"Abs", "[", RowBox[{RowBox[{"sweepP", "[", RowBox[{"\"NoisyData\"", ",", "1", ",", "All", ",", "2"}], "]"}], "-", RowBox[{"sweepP", "[", RowBox[{"\"IdealData\"", ",", "All", ",", "2"}], "]"}]}], "]"}], "]"}]}], ";",
                RowBox[{"Print", "[", RowBox[{"\"Check 3: End MAE=\"", ",", RowBox[{"NumberForm", "[", RowBox[{"endErr", ",", "4"}], "]"}], ",", "\" | PerGate MAE=\"", ",", RowBox[{"NumberForm", "[", RowBox[{"pgErr", ",", "4"}], "]"}], ",", RowBox[{"If", "[", RowBox[{RowBox[{"pgErr", ">", "endErr"}], ",", "\" PASS\"", ",", "\" Equal (single gate)\""}], "]"}]}], "]"}]
              }]
            }], "]"}]
          }]
        }],
      "]"}]
    ], "Input"]
  }, Open]],

  (* ===== EXPORT ===== *)
  Cell[CellGroupData[{
    Cell["Export Artifacts", "Section"],
    Cell["Run the cell below to export figures and PDF.", "Text"],
    Cell[BoxData[
      RowBox[{"Module", "[", 
        RowBox[{
          RowBox[{"{", "exportDir, figDir, sweep, mainFig, errorFig", "}"}], ",", "\n",
          RowBox[{
            RowBox[{"exportDir", "=", RowBox[{"FileNameJoin", "[", RowBox[{"{", RowBox[{RowBox[{"NotebookDirectory", "[", "]"}], ",", "\"exports\""}], "}"}], "]"}]}], ";",
            RowBox[{"figDir", "=", RowBox[{"FileNameJoin", "[", RowBox[{"{", RowBox[{"exportDir", ",", "\"figures\""}], "}"}], "]"}]}], ";",
            RowBox[{"If", "[", RowBox[{RowBox[{"!", RowBox[{"DirectoryQ", "[", "figDir", "]"}]}], ",", RowBox[{"CreateDirectory", "[", RowBox[{"figDir", ",", RowBox[{"CreateIntermediateDirectories", "->", "True"}]}], "]"}]}], "]"}], ";", "\n",

            RowBox[{"sweep", "=", RowBox[{"ZNE`GenerateSweep", "[", RowBox[{RowBox[{"N", "[", RowBox[{"Range", "[", RowBox[{"0", ",", RowBox[{"2", " ", "Pi"}], ",", RowBox[{"2", " ", RowBox[{"Pi", "/", "40"}]}]}], "]"}], "]"}], ",", RowBox[{"{", RowBox[{"1", ",", "2", ",", "3", ",", "4"}], "}"}], ",", "2", ",", RowBox[{"\"BaseNoise\"", "->", "0.03"}]}], "]"}]}], ";", "\n",

            RowBox[{"mainFig", "=", RowBox[{"Show", "[",
              RowBox[{
                RowBox[{"ListLinePlot", "[", RowBox[{RowBox[{"Prepend", "[", RowBox[{RowBox[{"Values", "[", RowBox[{"sweep", "[", "\"NoisyData\"", "]"}], "]"}], ",", RowBox[{"sweep", "[", "\"IdealData\"", "]"}]}], "]"}], ",", RowBox[{"PlotLegends", "->", RowBox[{"Prepend", "[", RowBox[{RowBox[{"Table", "[", RowBox[{RowBox[{"\"\\[Lambda]=\"", "<>", RowBox[{"ToString", "[", "l", "]"}]}], ",", RowBox[{"{", RowBox[{"l", ",", RowBox[{"{", RowBox[{"1", ",", "2", ",", "3", ",", "4"}], "}"}]}], "}"}]}], "]"}], ",", "\"Ideal\""}], "]"}]}], ",", RowBox[{"PlotLabel", "->", "\"ZNE: Ideal vs Noisy vs Mitigated\""}], ",", RowBox[{"ImageSize", "->", "700"}], ",", RowBox[{"PlotStyle", "->", RowBox[{"{", RowBox[{RowBox[{"{", RowBox[{"Thick", ",", "Black"}], "}"}], ",", "Automatic"}], "}"}]}]}], "]"}], ",",
                RowBox[{"ListLinePlot", "[", RowBox[{RowBox[{"sweep", "[", "\"ZNEData\"", "]"}], ",", RowBox[{"PlotStyle", "->", RowBox[{"{", RowBox[{"Thick", ",", "Red", ",", "Dashed"}], "}"}]}], ",", RowBox[{"PlotLegends", "->", RowBox[{"{", "\"ZNE\"", "}"}]}]}], "]"}]
              }],
            "]"}]}], ";", "\n",

            RowBox[{"errorFig", "=", RowBox[{"ListLinePlot", "[",
              RowBox[{
                RowBox[{"{",
                  RowBox[{
                    RowBox[{"MapThread", "[", RowBox[{RowBox[{"Function", "[", RowBox[{RowBox[{"{", RowBox[{"i", ",", "n"}], "}"}], ",", RowBox[{"{", RowBox[{RowBox[{"i", "[", RowBox[{"[", "1", "]"}], "]"}], ",", RowBox[{"Abs", "[", RowBox[{RowBox[{"n", "[", RowBox[{"[", "2", "]"}], "]"}], "-", RowBox[{"i", "[", RowBox[{"[", "2", "]"}], "]"}]}], "]"}]}], "}"}]}], "]"}], ",", RowBox[{"{", RowBox[{RowBox[{"sweep", "[", "\"IdealData\"", "]"}], ",", RowBox[{"sweep", "[", RowBox[{"\"NoisyData\"", ",", "1"}], "]"}]}], "}"}]}], "]"}], ",",
                    RowBox[{"MapThread", "[", RowBox[{RowBox[{"Function", "[", RowBox[{RowBox[{"{", RowBox[{"i", ",", "z"}], "}"}], ",", RowBox[{"{", RowBox[{RowBox[{"i", "[", RowBox[{"[", "1", "]"}], "]"}], ",", RowBox[{"Abs", "[", RowBox[{RowBox[{"z", "[", RowBox[{"[", "2", "]"}], "]"}], "-", RowBox[{"i", "[", RowBox[{"[", "2", "]"}], "]"}]}], "]"}]}], "}"}]}], "]"}], ",", RowBox[{"{", RowBox[{RowBox[{"sweep", "[", "\"IdealData\"", "]"}], ",", RowBox[{"sweep", "[", "\"ZNEData\"", "]"}]}], "}"}]}], "]"}]
                  }],
                "}"}], ",",
                RowBox[{"PlotLegends", "->", RowBox[{"{", RowBox[{"\"Noisy (\\[Lambda]=1)\"", ",", "\"ZNE\""}], "}"}]}], ",",
                RowBox[{"PlotLabel", "->", "\"Absolute Error Comparison\""}], ",",
                RowBox[{"ImageSize", "->", "700"}]
              }],
            "]"}]}], ";", "\n",

            RowBox[{"Export", "[", RowBox[{RowBox[{"FileNameJoin", "[", RowBox[{"{", RowBox[{"figDir", ",", "\"zne_main_plot.png\""}], "}"}], "]"}], ",", "mainFig", ",", RowBox[{"ImageResolution", "->", "150"}]}], "]"}], ";",
            RowBox[{"Export", "[", RowBox[{RowBox[{"FileNameJoin", "[", RowBox[{"{", RowBox[{"figDir", ",", "\"zne_error_plot.png\""}], "}"}], "]"}], ",", "errorFig", ",", RowBox[{"ImageResolution", "->", "150"}]}], "]"}], ";",
            RowBox[{"Print", "[", RowBox[{"\"Figures exported to: \"", ",", "figDir"}], "]"}], ";", "\n",
            RowBox[{"NotebookPrint", "[", RowBox[{RowBox[{"EvaluationNotebook", "[", "]"}], ",", RowBox[{"FileNameJoin", "[", RowBox[{"{", RowBox[{"exportDir", ",", "\"ZNE_Demo.pdf\""}], "}"}], "]"}]}], "]"}], ";",
            RowBox[{"Print", "[", "\"PDF exported.\"", "]"}]
          }]
        }],
      "]"}]
    ], "Input"]
  }, Open]],

  (* ===== RUNBOOK ===== *)
  Cell[CellGroupData[{
    Cell["Reproducibility Runbook", "Section"],
    Cell["Follow these steps to reproduce results on another machine:\n\n1. Install Mathematica 14.3 (or compatible version).\n2. Install the QuantumFramework paclet:\n     PacletInstall[\"Wolfram/QuantumFramework\"]\n3. Open this notebook (notebook/ZNE_Demo.nb) in Mathematica.\n4. Evaluate All Cells (Evaluation menu).\n5. Interactive demo appears in the ZNE Demo section.\n6. Export artifacts by running the Export section.\n\nDefault parameters for exports:\n  - BaseNoise: 0.03\n  - NoiseModel: DepolarizingEnd\n  - LambdaList: {1, 2, 3, 4}\n  - Polynomial Order: 2\n  - Theta points: 40\n  - Shots: Infinity (analytic)", "Text"]
  }, Open]]

},
WindowSize -> {1000, 750},
WindowMargins -> {{100, Automatic}, {Automatic, 50}},
StyleDefinitions -> "Default.nb"
];

(* Write to file *)
Export[nbPath, nbExpr, "NB"];
Print["Notebook written to: ", nbPath];
