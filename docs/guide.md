# Airfoil polars: step-by-step guide

## The question

How well does SolidWorks Flow Simulation predict an airfoil's lift, drag and moment? And where does it fail? Two NASA validation cases with published wind-tunnel data provide the references:

| Case | Conditions | Reference data (in `data/reference/`) |
|---|---|---|
| NACA 0012 | Re 6.0 million, Mach 0.15, −4° to 20° | Ladson, NASA TM-4074 (tripped boundary layer: 80/120/180 grit); Abbott & von Doenhoff; NASA CFL3D results with the SA and SST turbulence models |
| NACA 4412 | Re 1.52 million, 13.87° | Coles & Wadcock surface pressure. The flow separates near the trailing edge, a known hard case |

All reference files come from NASA's Turbulence Modeling Resource (TMR), which publishes them for exactly this purpose.

You'll compare four predictions of increasing physical fidelity:

1. **Panel method (yours, in MATLAB):** inviscid. Gives the lift slope, the zero-lift angle and the moment; no drag, no stall.
2. **XFOIL:** the same inviscid core plus a boundary-layer model. It's excellent until stall.
3. **Flow Simulation:** RANS CFD, using a k–ε turbulence model with wall functions on a Cartesian cut-cell mesh.
4. **Experiment.**

The differences between them are the findings. Panel versus experiment shows the effect of viscosity. XFOIL versus experiment shows what an integral boundary layer captures. Flow Simulation versus NASA's CFD shows what its mesh and turbulence model cost.

## Answers to expect (write your prediction in the run log first)

| Quantity | Value | Source |
|---|---|---|
| NACA 0012 lift slope | ≈ 0.106 /deg | Ladson, from 0° to 10° |
| Panel-method lift slope | 0.1205 /deg | Inviscid, about 14% high. The boundary layer reduces it |
| NACA 0012 CL at 10° | 1.0707 (at 10.12°) | Ladson, 80 grit |
| NACA 0012 CL / CD at 10° | 1.0909 / 0.01231 | NASA CFL3D, SA model |
| NACA 0012 CD at 0° | ≈ 0.0081 | Ladson, tripped |
| NACA 0012 CLmax | ≈ 1.6 near 17° | Ladson. The experiments disagree near stall, and none is truly 2D there |
| NACA 4412 zero-lift angle | −4.29° (panel); thin-airfoil theory −4.15° | |
| NACA 4412 Cm(c/4) | −0.110 (panel); thin-airfoil theory −0.106 | |
| Thick symmetric airfoil Cm(c/4), inviscid | Slightly negative and growing with α | Real physics: the aerodynamic centre sits a little behind c/4. The tests check this against the exact solution |

## Stage A: MATLAB and XFOIL (no SolidWorks needed)

1. **Run the tests:** `addpath tests; test_airfoil`. All of them must pass before you trust anything else.
   - The key test runs your panel method on a Kármán–Trefftz airfoil, whose exact solution comes from conformal mapping. Lift agrees within 0.02% at 201 points, and the error falls fourfold each time the points double (second-order convergence).
   - One trap the tests document: on a *cusped* cambered trailing edge (the Joukowski airfoil), this panel method's Kutta condition degenerates and the error stalls at 1.4%. NACA sections have a finite trailing-edge angle, so it doesn't affect your results. It's a good example of why a code is verified on the case it will actually be used for.
2. **`run('src/make_inputs.m')`** writes the geometry curves to `cad/` and the XFOIL inputs to `data/xfoil/`.
3. **`run('src/run_panel_polars.m')`** writes the inviscid polars.
4. **XFOIL.**
   - Download XFOIL 6.99 for Windows from Mark Drela's MIT page (web.mit.edu/drela/Public/web/xfoil). Put `xfoil.exe` in `data/xfoil/`.
   - Open a command prompt there and run `xfoil.exe < deck_naca0012_forced.txt`. Repeat for the other two decks.
   - These decks are untested; XFOIL wouldn't run in my workspace. If one stops partway, type the same commands by hand once (they're plain text) to see which prompt differs.
   - Non-converged angles are skipped. Near stall that's normal.
5. **`run('src/compare_polars.m')`** and **`run('src/compare_cp.m')`** draw everything you have so far.

Stage A is complete by itself. If SolidWorks stays broken, "inviscid panel method vs XFOIL vs NASA data" is already a legitimate study.

## Stage B: Flow Simulation

The cases are 2D, so they're light enough for the old machine. Cells scale with the mesh levels below, and each run should take minutes, not hours. Time the first one and write it down.

### B1. Geometry

Either:
- **File → Open** `cad/naca0012_2d.step`. It's already positioned with the quarter chord at the origin, chord 1766.5 mm, extruded 10 mm in +Z. Or
- **Build it yourself:** set units to mm, then Insert → Curve → Curve Through XYZ Points with `naca0012_upper_mm.txt` and then `naca0012_lower_mm.txt`. Convert both curves into a sketch on the Front Plane and extrude 10 mm. Measure the chord: it must be 1766.5 mm.

Also insert the upper and lower curves as **reference curves**, even if you opened the STEP. Flow Simulation uses them for the Cp plots in B6.

The NACA 4412 is the same with `naca4412_*` files and a 447.5 mm chord.

### B2. Wizard

| Setting | Value |
|---|---|
| Units | SI |
| Analysis | External, **steady** (no time dependence) |
| Fluid | Air. Flow type **Turbulent only**: Ladson tripped his boundary layer, and NASA's CFD is fully turbulent, so laminar regions would make the comparison unfair |
| Initial conditions | Velocity X and Y from `plan_airfoil_runs.m` (for example 10°: Vx = 50.707, Vy = 8.941 m/s), 101325 Pa, 293.2 K |
| Turbulence | Intensity 0.1%. Leave the length scale at its default and record it |

**Check Re:** read air's density and viscosity at 293.2 K from the Engineering Database. Put them in `src/flow_conditions.m` and rerun `make_inputs.m`. If the chord changes noticeably, rescale the part.

### B3. Domain and mesh

- **Computational domain:** 2D simulation, XY plane. X from −10c to +20c, Y ±10c. For the NACA 0012 that's X −17.67 to 35.33 m and Y ±17.67 m. `plan_airfoil_runs.m` prints the values for both airfoils.
- **Global mesh:** Manual, basic mesh 60 × 40 cells, so each cell is c/2.
- **Local mesh 1, near field:** a box from −0.5c to 1.5c in x and ±0.5c in y. Refine fluid cells to the "box" level below.
- **Local mesh 2, airfoil surface:** select the airfoil faces and refine partial (cut) cells to the "surface" level. Add equidistant refinement of about 0.05c if your version has it.
- **Local mesh 3, wake:** a box from 1.5c to 4c in x and ±0.3c in y, one level below the box level.
- **Turn off solution-adaptive refinement.**

| Mesh | Surface level → cell size | Box level → cell size |
|---|---|---|
| coarse | 5 → c/64 | 3 → c/16 |
| medium | 6 → c/128 | 4 → c/32 |
| fine | 7 → c/256 | 5 → c/64 |

Each level halves the cell size. For scale: at Re 6 million the turbulent boundary layer at the trailing edge is only about 1.6% of the chord thick. Even the fine mesh puts few cells across it, so Flow Simulation leans on its wall functions. That's a limitation to state in the write-up, not to hide.

### B4. Goals and the span

- **Surface goals** on the airfoil's curved faces (not the flat ±Z ends): **Force (X)**, **Force (Y)** and **Torque (Z)** about the global origin, which is the quarter chord.
- **Find the span** before trusting any coefficient. Tools → Flow Simulation → Tools → Surface Parameters on the same faces gives an area. Divide it by the perimeter:
  - NACA 0012: 3.6019 m perimeter
  - NACA 4412: 0.9165 m perimeter
  
  The result is the depth Flow Simulation integrated over. Enter it as `SPAN` in `compare_polars.m`. (The cylinder project's CD check settles the same question another way.)

### B5. Runs

1. **The first run is α = 10° on the coarse mesh.** CL should come out within roughly 10% of 1.07. If it's off by a large factor, the span or the force rotation is wrong, not the physics.
2. **Mesh study at 10°:** run coarse, medium and fine. Record the cell counts. Pick the mesh where CL changes by less than about 1% from the next finer one.
3. **Domain study at 10°** on that mesh, with ±20c instead of ±10c. NASA puts its far field 500c away because lift is sensitive to it: the lifting airfoil's circulation disturbs the flow a long way out. The change you measure goes into your error budget.
4. **The sweep:** −4° to 20° in 2° steps. Use **Parametric Study** (what-if mode) with Velocity X and Velocity Y as the varied inputs and one scenario per angle. If your version lacks that, clone the project per angle and use **Batch Run**.
5. **Note where the goals stop converging** and start oscillating. That angle is NASA's α_max for a steady RANS solution, and it's a result in itself.
6. **NACA 4412:** the same procedure, but the angle that matters is 13.87° (Vx = 49.986, Vy = 12.344 m/s). Add 0°, 4° and 8° for the lift curve.

Put the forces from each mesh in `data/results/flowsim_0012_<mesh>.csv`, one row per angle:

```
alpha,Fx,Fy,Mz
10,123.4,1234.5,-12.3
```

### B6. Surface pressure

- At 0°, 10° and 15° (NACA 0012) and 13.87° (NACA 4412), make an **XY Plot** of Pressure along the upper reference curve, and another along the lower curve, against Model X. Export each to Excel.
- In MATLAB:
  ```matlab
  F = flow_conditions(6e6);
  [xc, cp] = flowsim_cp('data/flowsim_exports/0012_a10_upper.xlsx', F.chord, F.p, F.rho, F.U);
  writematrix([xc cp], 'data/results/fs_cp_0012_a10_upper.csv')
  ```
- `compare_cp.m` picks the files up automatically.
- Ladson's Cp data were taken at Mach 0.3 and the airfoil-model aspect ratio was only 1.33, so treat small differences with suspicion. The bigger value of this plot is seeing *where* on the airfoil Flow Simulation departs from the data.

## Stage C: analysis and write-up

Answer these in `docs/run_log.md`, then in the note:

1. **Lift slope.** Fit 0–8° for every source. Rank them and explain the differences: viscous decambering, then the wall-function model.
2. **Drag at 0° and 10°.** Express the error in counts (1 count = 0.0001). Drag is where cut-cell CFD with wall functions usually struggles most, so measure how badly rather than assume.
3. **Stall.** What do the panel method, XFOIL, Flow Simulation and the experiment each predict, and why can a steady RANS solution not capture stall properly?
4. **NACA 4412 at 13.87°.** Does Flow Simulation show the flat upper-surface Cp near the trailing edge, the signature of separation? The panel method can't, by construction.
5. **Error budget at 10°.** Mesh error from the study, domain error, and remaining model error (the gap to NASA's CFD). Which dominates?

## Exercises (your own work)

1. In `naca4.m`, change the cosine spacing to uniform spacing and rerun the panel convergence test. Explain the change in accuracy near the leading edge.
2. Write a constant-source plus constant-vortex panel method (Hess–Smith) from scratch. Use it as a second independent code and run it through the same Kármán–Trefftz tests.
3. Add a Prandtl–Glauert compressibility correction to the panel results, and estimate how much Mach 0.15 versus Mach 0.3 matters for Ladson's Cp data.

## Sources

- NASA Turbulence Modeling Resource: 2D NACA 0012 validation (2DN00) and NACA 4412 trailing-edge separation (2DN44). The data files are from the TMR GitHub repository (tmbwg/turbmodels).
- Ladson, C. L., NASA TM-4074 (1988); Ladson, Hill & Johnson, NASA TM-100526 (1987).
- Abbott & von Doenhoff, *Theory of Wing Sections*, Dover.
- Coles & Wadcock, AIAA Journal 17(4), 1979.
- Kuethe & Chow, *Foundations of Aerodynamics*, panel method formulation.
