%% plan_airfoil_runs.m — conditions and inflow components for every Flow Simulation run
%
% Both validation cases are "essentially incompressible" (Mach 0.15). We keep
% the Mach number fixed and choose the CHORD to hit the experiment's Reynolds
% number, rather than changing the speed (which would add compressibility).
%
% The airfoil stays fixed and the INFLOW is rotated by alpha, so one mesh
% serves every angle. Flow Simulation reports forces along its own X and Y axes;
% src/flowsim_to_coeffs.m rotates them back into lift and drag.

clear; clc;

%% Air properties, speed and chords all come from flow_conditions.m
F0  = flow_conditions(1);
rho = F0.rho; mu = F0.mu; a = F0.a; U = F0.U; M = F0.M; nu = F0.nu;

cases = { 'NACA 0012 vs Ladson (NASA TM-4074)', '0012', 6.0e6, -4:2:20;
          'NACA 4412 vs Coles & Wadcock',       '4412', 1.52e6, [-4:2:12 13.87 14 16] };

fprintf('Air: rho = %.4f kg/m^3, mu = %.4g Pa s, a = %.1f m/s  ->  U = %.2f m/s at M = %.2f\n\n', ...
        rho, mu, a, U, M);
for k = 1:size(cases, 1)
    Re = cases{k,3};
    c  = Re*nu/U;                                  % chord that gives this Re at this U
    q  = 0.5*rho*U^2;
    al = cases{k,4};
    fprintf('%s:  Re = %.3g  ->  chord c = %.4f m,  q = %.1f Pa\n', cases{k,1}, Re, c, q);
    fprintf('  Domain (quarter chord at origin): x from %.2f to %.2f m, y +-%.2f m (-10c..+20c, +-10c)\n', ...
            -10*c, 20*c, 10*c);
    fprintf('  %8s %12s %12s\n', 'alpha', 'Vx [m/s]', 'Vy [m/s]');
    for j = 1:numel(al)
        fprintf('  %8.2f %12.4f %12.4f\n', al(j), U*cosd(al(j)), U*sind(al(j)));
    end
    fprintf('\n');
end
fprintf('Expected (NACA 0012, Ladson 80-grit trip): CL = 1.0707 at 10.12 deg, CD = 0.0081 at 0 deg,\n');
fprintf('CL slope ~0.106 per degree. NASA CFL3D SA reference: CL 1.0909, CD 0.01231 at 10 deg.\n');
