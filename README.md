# Airfoil polars: panel method, XFOIL and Flow Simulation against NASA data

**Question.** How accurately does SolidWorks Flow Simulation predict lift, drag and moment for the NACA 0012 (Re 6 million) and NACA 4412 (Re 1.52 million) validation cases? And how does it rank against an inviscid panel method, XFOIL and NASA's own CFD?

**Status.** MATLAB tools written and verified against an exact solution (`tests/test_airfoil.m`, all passing). XFOIL and Flow Simulation runs not started.

## Contents

| Path | What |
|---|---|
| `src/naca4.m` | NACA 4-digit geometry, including the exact NASA TMR definitions |
| `src/panel_vortex.m` | Linear-strength vortex panel method (inviscid CL, Cp, Cm) |
| `src/karman_trefftz_exact.m` | Exact conformal-map solution, used as the test oracle |
| `src/flow_conditions.m` | Air properties, speed and chord for a target Re (single source of truth) |
| `src/make_inputs.m` | Writes the SolidWorks curves and XFOIL decks |
| `src/xfoil_deck.m`, `read_xfoil_polar.m` | Run XFOIL unattended and read its output |
| `src/flowsim_to_coeffs.m`, `flowsim_cp.m` | Turn Flow Simulation forces and pressures into coefficients |
| `src/compare_polars.m`, `compare_cp.m` | All sources on one plot, with error tables |
| `data/reference/` | NASA TMR experimental and CFD data (public domain, unmodified) |
| `cad/` | STEP bodies and XYZ curves, quarter chord at the origin |
| `docs/guide.md` | Step-by-step instructions |

## Reproduce

```matlab
addpath tests; test_airfoil          % must print ALL TESTS PASS
run('src/make_inputs.m')
run('src/run_panel_polars.m')
% XFOIL: xfoil.exe < deck_naca0012_forced.txt   (in data/xfoil/)
run('src/compare_polars.m'); run('src/compare_cp.m')
```

## Limitations (fill in as you learn them)

- 2D, steady RANS: no unsteady stall or 3D effects. The experiments themselves are not 2D near stall.
- Flow Simulation's wall functions and cut-cell mesh model the boundary layer rather than resolving it.

## Data and tools

Reference data: NASA Turbulence Modeling Resource (turbmodels.larc.nasa.gov; GitHub tmbwg/turbmodels). XFOIL by Mark Drela (MIT). The panel method follows Kuethe & Chow.

Code: MIT licence. Text and figures: CC BY 4.0.
