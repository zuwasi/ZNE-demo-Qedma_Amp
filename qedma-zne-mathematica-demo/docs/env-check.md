# Environment Check Results

**Date:** Wed 11 Feb 2026 21:27:50

## Mathematica Version

| Field   | Value            |
|---------|------------------|
| Version | **14.3**         |
| System  | Windows-x86-64   |

## QuantumFramework Paclet

| Field   | Value |
|---------|-------|
| Status  | **Already installed** |
| Name    | `Wolfram/QuantumFramework` |
| Version | **1.6.5** |
| License | MIT |
| Location | `C:\Users\danie\AppData\Roaming\Wolfram\Paclets\Repository\Wolfram__QuantumFramework-1.6.5` |

## Automation Results

| Step                         | Result     |
|------------------------------|------------|
| PacletFind                   | ✅ PASSED  |
| Needs["Wolfram\`QuantumFramework\`"] | ✅ PASSED  |
| QuantumState[0] smoke test   | ✅ PASSED  |

**All checks passed. The environment is ready for the Qedma ZNE demo.**

---

## Manual Fallback Steps (if automation fails)

If `wolframscript` fails or the paclet is not found, follow these steps manually:

1. **Open Mathematica** (version 14.3 or later)

2. **Install the QuantumFramework paclet:**
   ```mathematica
   PacletInstall["Wolfram/QuantumFramework"]
   ```

3. **Load the paclet:**
   ```mathematica
   Needs["Wolfram`QuantumFramework`"]
   ```

4. **Verify with a smoke test:**
   ```mathematica
   QuantumState[0]
   ```
   You should see a `QuantumState[...]` object with a 2-element sparse array (the |0⟩ computational basis state).

5. If `PacletInstall` fails behind a proxy/firewall, download manually from the [Wolfram Paclet Repository](https://resources.wolframcloud.com/PacletRepository/resources/Wolfram/QuantumFramework/) and install with:
   ```mathematica
   PacletInstall["path/to/Wolfram__QuantumFramework-x.y.z.paclet"]
   ```
