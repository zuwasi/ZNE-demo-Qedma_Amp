# Qedma ZNE Mathematica Demo

An end-to-end reproducible Mathematica 14.3 demonstrator for **Zero-Noise Extrapolation (ZNE)** inspired by Temme–Bravyi–Gambetta ([arXiv:1612.02058](https://arxiv.org/abs/1612.02058)). Provides an interactive visual demo comparing ideal, noisy, and ZNE-mitigated quantum expectation values.

---

## Requirements

| Requirement | Version |
|---|---|
| Windows | 11 |
| Wolfram Mathematica | 14.3 |
| Paclet | `Wolfram/QuantumFramework` |

## Repository Layout

```
qedma-zne-mathematica-demo/
├── README.md
├── notebook/
│   └── ZNE_Demo.nb
├── docs/
│   └── references.md
└── output/
    ├── ZNE_Demo.pdf
    └── figures/
        └── *.png
```

## How to Run

1. **Install the paclet** (if not already installed):

   ```mathematica
   PacletInstall["Wolfram/QuantumFramework"]
   ```

2. **Open the notebook** — launch `notebook/ZNE_Demo.nb` in Mathematica.

3. **Evaluate All Cells** — select *Evaluation → Evaluate All Cells* from the menu bar.

4. **Use interactive controls** — adjust noise scale factors, circuit depth, and extrapolation order via the embedded `Manipulate` controls.

## How to Export Artifacts

Run the **Export** section at the bottom of the notebook to produce:

- `output/ZNE_Demo.pdf` — a print-ready PDF of the full notebook.
- `output/figures/*.png` — individual PNG figures for each plot.

## References

- K. Temme, S. Bravyi, J. M. Gambetta, *"Error mitigation for short-depth quantum circuits,"* [arXiv:1612.02058](https://arxiv.org/abs/1612.02058)
- A. Kandala _et al._, *"Error mitigation extends the computational reach of a noisy quantum processor,"* [arXiv:1805.04492](https://arxiv.org/abs/1805.04492)
