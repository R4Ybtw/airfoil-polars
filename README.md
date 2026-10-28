# Airfoil polars: panel method, XFOIL and CFD against wind-tunnel data

How accurately does SolidWorks Flow Simulation predict the lift, drag, pitching moment and surface pressure of an airfoil, and how does it compare with simpler methods? The study uses two standard validation cases from NASA's Turbulence Modeling Resource:

| Case | Conditions | Reference data |
|---|---|---|
| NACA 0012 | Re = 6 × 10⁶, Mach 0.15, α from −4° to 20° | Ladson's tripped wind-tunnel measurements (NASA TM-4074), Abbott & von Doenhoff, and NASA CFL3D results with the SA and SST turbulence models |
| NACA 4412 | Re = 1.52 × 10⁶, α = 13.87° | Coles & Wadcock surface pressures. A trailing-edge separation case |

Four predictions of increasing physical fidelity are compared with experiment. The differences between them isolate the effect of each modelling step:

1. **Vortex panel method (MATLAB):** inviscid, so no drag and no stall.
2. **XFOIL:** the same kind of inviscid solution coupled to a boundary-layer model.
3. **SolidWorks Flow Simulation:** steady RANS with a k–ε turbulence model on a Cartesian cut-cell mesh.
4. **NASA's reference CFD:** for comparison with a fully resolved solution.

*Work in progress: the MATLAB tools are complete and verified; XFOIL and Flow Simulation results will be added as the runs are completed.*

## Verification of the panel method

The linear-strength vortex panel method (`src/panel_vortex.m`) is tested against the exact conformal-mapping solution for a Kármán–Trefftz airfoil:

- **Lift:** agrees within 0.02% with 201 points, and the error converges at second order (it falls fourfold each time the number of points doubles).
- **Pitching moment:** matches the exact value, including the small negative quarter-chord moment of a thick symmetric section in inviscid flow.
- **Physical checks:** zero lift for a symmetric section at 0°; the same lift from circulation and from integrating pressure; near-zero pressure drag (d'Alembert's paradox); and a lift slope consistent with thin-airfoil theory plus the usual thickness correction.

One documented limitation: on a cusped *and* cambered trailing edge (the Joukowski airfoil), the Kutta condition in this formulation degenerates and the lift error stalls near 1.4%. NACA sections have a finite trailing-edge angle and are unaffected.

## Reference values

| Quantity | Value | Source |
|---|---|---|
| NACA 0012 lift slope | ≈ 0.106 per degree | Ladson, 0–10° |
| NACA 0012 CL at 10.12° | 1.0707 | Ladson, 80-grit trip |
| NACA 0012 CL, CD at 10° | 1.0909, 0.01231 | NASA CFL3D, SA model |
| NACA 0012 CD at 0° | ≈ 0.0081 | Ladson, tripped |
| Inviscid lift slope (NACA 0012) | 0.1205 per degree | Panel method, this repository |
| NACA 4412 zero-lift angle, Cm(c/4) | −4.29°, −0.110 | Panel method, this repository |

## Simulation setup

| Item | Setting |
|---|---|
| Solver | SolidWorks Flow Simulation, 2D (XY plane), external, steady, fully turbulent |
| Conditions | Air at 293.2 K and Mach 0.15. The chord is chosen to give each experiment's Reynolds number: 1.7665 m for the NACA 0012, 0.4475 m for the NACA 4412 |
| Angle of attack | The inflow direction is rotated, so one mesh serves every angle; forces are rotated back into lift and drag |
| Domain | 10 chords upstream, 20 downstream, ±10 chords across. A ±20-chord domain study measures far-field sensitivity |
| Mesh | Base cells c/2. Near-field box refined to c/16, c/32 or c/64 and the airfoil surface to c/64, c/128 or c/256 (coarse / medium / fine); refined wake box |
| Outputs | Force X and Y and torque Z about the quarter chord; surface pressure along the upper and lower surfaces |

The settings actually used for each run are recorded in `docs/run_log.md`.

## Repository layout

| Path | Contents |
|---|---|
| `src/naca4.m` | NACA 4-digit geometry, including the exact NASA TMR definitions |
| `src/panel_vortex.m` | Linear-strength vortex panel method |
| `src/karman_trefftz_exact.m` | Exact conformal-mapping solution (test oracle) |
| `src/flow_conditions.m` | Air properties, speed and chord for a target Reynolds number |
| `src/make_inputs.m` | Generates the CAD curves and the XFOIL command files |
| `src/xfoil_deck.m`, `src/read_xfoil_polar.m` | Unattended XFOIL runs and their output |
| `src/flowsim_to_coeffs.m`, `src/flowsim_cp.m` | Flow Simulation forces and pressures as coefficients |
| `src/compare_polars.m`, `src/compare_cp.m` | All sources on common plots, with error tables |
| `tests/test_airfoil.m` | Verification suite |
| `data/reference/` | NASA TMR experimental and CFD data, unmodified |
| `data/xfoil/` | XFOIL inputs and outputs |
| `cad/` | STEP bodies and XYZ curves (quarter chord at the origin), plus the script that builds them |
| `docs/run_log.md` | Run-by-run record of settings and results |

## Reproducing the analysis

```matlab
addpath tests; test_airfoil       % verification
run('src/make_inputs.m')          % geometry and XFOIL inputs
run('src/run_panel_polars.m')     % inviscid polars
run('src/compare_polars.m')       % lift, drag polar and moment
run('src/compare_cp.m')           % surface pressure
```

XFOIL runs from `data/xfoil/` with `xfoil.exe < deck_naca0012_forced.txt` (and the other decks). The MATLAB code also runs in GNU Octave, except the Excel reader, which needs MATLAB.

## Limitations

- **2D steady RANS:** cannot capture unsteady stall or 3D effects. The experiments themselves are not truly two-dimensional near stall.
- **Wall modelling:** Flow Simulation models the boundary layer with wall functions on a cut-cell mesh rather than resolving it, which mainly affects drag and separation.
- **Ladson's pressure data:** taken at Mach 0.3 on a model of aspect ratio 1.33, so small Cp differences are not conclusive.

## References

- NASA Langley Turbulence Modeling Resource: 2D NACA 0012 airfoil validation case (2DN00) and NACA 4412 trailing-edge separation case (2DN44); data from github.com/tmbwg/turbmodels.
- C. L. Ladson, *Effects of independent variation of Mach and Reynolds numbers on the low-speed aerodynamic characteristics of the NACA 0012 airfoil section*, NASA TM-4074 (1988).
- C. L. Ladson, A. S. Hill and W. G. Johnson, NASA TM-100526 (1987).
- I. H. Abbott and A. E. von Doenhoff, *Theory of Wing Sections*, Dover (1959).
- N. Gregory and C. L. O'Reilly, *Low-speed aerodynamic characteristics of NACA 0012 aerofoil section, including the effects of upper-surface roughness simulating hoar frost*, R&M 3726 (1970).
- D. Coles and A. J. Wadcock, "Flying-hot-wire study of flow past an NACA 4412 airfoil at maximum lift," *AIAA Journal* 17(4), 321–329 (1979).
- M. Drela, "XFOIL: An analysis and design system for low Reynolds number airfoils," in *Low Reynolds Number Aerodynamics*, Springer (1989).
- A. M. Kuethe and C.-Y. Chow, *Foundations of Aerodynamics*, 5th ed., Wiley (1998).


## Licence

Code: MIT (see `LICENSE`). Text and figures: CC BY 4.0. The files in `data/reference/` are redistributed unmodified from NASA's Turbulence Modeling Resource and are not covered by either licence. The original sources are named in each file's header.
