%% compare_polars.m — NACA 0012 at Re 6 million: every source on one set of axes
%
% Sources (missing files are skipped, so you can run this at any stage):
%   Experiment  Ladson, NASA TM-4074 (tripped: 80/120/180 grit), Abbott & von Doenhoff
%   NASA CFD    CFL3D on the 897x257 grid, SA and SST models (NASA TMR)
%   Ours        panel method (inviscid), XFOIL (forced/free transition),
%               Flow Simulation (data/results/flowsim_0012_<mesh>.csv)
%
% Flow Simulation results file, one row per angle (forces straight from the goals):
%   alpha,Fx,Fy,Mz
%   0,1.234,0.001,-0.02
% Set SPAN below to the depth Flow Simulation integrated over (docs/guide.md).

clear; clc;
here = fileparts(mfilename('fullpath')); addpath(here);
root = fullfile(here, '..');
ref  = fullfile(root, 'data', 'reference');
SPAN = 0.010;                          % m  <-- CHECK (Surface Parameters area / perimeter)
F    = flow_conditions(6.0e6);

L  = read_tecplot_dat(fullfile(ref, 'CLCD_Ladson_expdata.dat'));
Ab = read_tecplot_dat(fullfile(ref, '0012.abbottdata.cl.dat'));
Ac = read_tecplot_dat(fullfile(ref, '0012.abbottdata.cd.dat'));
SA = read_tecplot_dat(fullfile(ref, 'n0012clcd_cfl3d_sa.dat'));
SS = read_tecplot_dat(fullfile(ref, 'n0012clcd_cfl3d_sst.dat'));

figure('Position', [100 100 1100 420]);
subplot(1,3,1); hold on; grid on; title('Lift curve'); xlabel('\alpha [deg]'); ylabel('C_L');
subplot(1,3,2); hold on; grid on; title('Drag polar'); xlabel('C_D'); ylabel('C_L');
subplot(1,3,3); hold on; grid on; title('Quarter-chord moment'); xlabel('\alpha [deg]'); ylabel('C_m');
mk = {'o', 's', '^'};
for k = 1:numel(L)
    d = L(k).data;
    subplot(1,3,1); plot(d(:,1), d(:,2), mk{k}, 'DisplayName', ['Ladson ' L(k).title]);
    subplot(1,3,2); plot(d(:,3), d(:,2), mk{k}, 'DisplayName', ['Ladson ' L(k).title]);
end
subplot(1,3,1); plot(Ab.data(:,1), Ab.data(:,2), 'k.', 'DisplayName', 'Abbott & von Doenhoff');
subplot(1,3,2); plot(Ac.data(:,2), Ac.data(:,1), 'k.', 'DisplayName', 'Abbott & von Doenhoff');
for S = {SA, 'CFL3D SA'; SS, 'CFL3D SST'}'
    d = S{1}.data;
    subplot(1,3,1); plot(d(:,1), d(:,2), 'p', 'MarkerSize', 10, 'DisplayName', S{2});
    subplot(1,3,2); plot(d(:,3), d(:,2), 'p', 'MarkerSize', 10, 'DisplayName', S{2});
end

pf = fullfile(root, 'data', 'results', 'panel_0012.csv');
if exist(pf, 'file')
    P = dlmread(pf, ',', 1, 0);
    subplot(1,3,1); plot(P(:,1), P(:,2), 'k--', 'DisplayName', 'Panel method (inviscid)');
    subplot(1,3,3); plot(P(:,1), P(:,3), 'k--', 'DisplayName', 'Panel method (inviscid)');
end
for xf = {'polar_0012_forced.txt', 'XFOIL forced trip'; 'polar_0012_free.txt', 'XFOIL free (N=9)'}'
    f = fullfile(root, 'data', 'xfoil', xf{1});
    if exist(f, 'file')
        X = read_xfoil_polar(f);
        subplot(1,3,1); plot(X.alpha, X.cl, '-', 'DisplayName', xf{2});
        subplot(1,3,2); plot(X.cd, X.cl, '-', 'DisplayName', xf{2});
        subplot(1,3,3); plot(X.alpha, X.cm, '-', 'DisplayName', xf{2});
    end
end
meshes = {'coarse', 'medium', 'fine'};
for m = 1:3
    f = fullfile(root, 'data', 'results', sprintf('flowsim_0012_%s.csv', meshes{m}));
    if ~exist(f, 'file'), continue; end
    R = dlmread(f, ',', 1, 0);
    C = flowsim_to_coeffs(R(:,1), R(:,2), R(:,3), R(:,4), F.rho, F.U, F.chord, SPAN);
    nm = ['Flow Sim ' meshes{m}];
    subplot(1,3,1); plot(C.alpha, C.cl, '-x', 'LineWidth', 1.5, 'DisplayName', nm);
    subplot(1,3,2); plot(C.cd, C.cl, '-x', 'LineWidth', 1.5, 'DisplayName', nm);
    subplot(1,3,3); plot(C.alpha, C.cm, '-x', 'LineWidth', 1.5, 'DisplayName', nm);
    % error table against Ladson 80 grit (interpolated to the CFD angles, attached range)
    d  = L(1).data; d = d(d(:,1) < 17.5, :);
    ok = C.alpha >= min(d(:,1)) & C.alpha <= max(d(:,1));
    clx = interp1(d(:,1), d(:,2), C.alpha(ok));
    cdx = interp1(d(:,1), d(:,3), C.alpha(ok));
    fprintf('\n%s mesh vs Ladson 80 grit:\n%7s %8s %8s %8s %9s %9s\n', meshes{m}, 'alpha', 'CL', 'CL exp', ...
            'dCL %', 'CD', 'CD exp');
    fprintf('%7.2f %8.4f %8.4f %+8.1f %9.5f %9.5f\n', ...
            [C.alpha(ok) C.cl(ok) clx 100*(C.cl(ok) - clx)./max(abs(clx), 0.05) C.cd(ok) cdx]');
end
subplot(1,3,1); legend('Location', 'northwest'); xlim([-5 21]);
subplot(1,3,2); xlim([0 0.04]);
subplot(1,3,3); ylim([-0.05 0.05]);
