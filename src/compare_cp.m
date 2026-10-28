%% compare_cp.m — surface pressure: where the polars' differences come from
%
% Part 1: NACA 0012, Re 6M, alpha = 0, 10, 15  (Ladson free transition; Gregory & O'Reilly)
% Part 2: NACA 4412, Re 1.52M, alpha = 13.87   (Coles & Wadcock; NASA CFL3D SA)
%         The 4412 case separates near the trailing edge — the flat Cp
%         "plateau" on the upper surface near x/c = 1 is the separated region.
%
% Flow Simulation Cp files (optional), one per surface, two columns x/c,cp:
%   data/results/fs_cp_0012_a10_upper.csv  (make them with flowsim_cp.m in MATLAB)
% XFOIL CPWR files in data/xfoil/ are read automatically if present.

clear; clc;
here = fileparts(mfilename('fullpath')); addpath(here);
root = fullfile(here, '..'); ref = fullfile(root, 'data', 'reference');

% ---- Part 1: NACA 0012 ----------------------------------------------------
LC = read_tecplot_dat(fullfile(ref, 'CP_Ladson.dat'));
GC = read_tecplot_dat(fullfile(ref, 'CP_Gregory_expdata.dat'));
af = naca4('0012', 161, 'scaled');
alphas = [0 10 15];
figure('Position', [100 100 1100 380]);
for k = 1:3
    subplot(1,3,k); hold on; grid on; set(gca, 'YDir', 'reverse');
    title(sprintf('NACA 0012, \\alpha = %g^\\circ', alphas(k))); xlabel('x/c'); ylabel('C_p');
    z = LC(k).data;    % zones 1-3 are Re = 6M, free transition
    plot(z(:,1), z(:,end), 'o', 'DisplayName', 'Ladson TM-100526 (Re 6M, M 0.3)');
    g = GC(k).data;
    plot(g(:,1), g(:,2), 's', 'DisplayName', 'Gregory (Re 2.9M, upper)');
    R = panel_vortex(af.x, af.y, alphas(k));
    plot(R.xc, R.cp, 'k-', 'DisplayName', 'Panel method');
    xf = fullfile(root, 'data', 'xfoil', sprintf('cp_naca0012_a%g.txt', alphas(k)));
    if exist(xf, 'file')
        X = read_numeric(xf); plot(X(:,1), X(:,end), 'b-', 'DisplayName', 'XFOIL');
    end
    for s = {'upper', 'lower'}
        f = fullfile(root, 'data', 'results', sprintf('fs_cp_0012_a%g_%s.csv', alphas(k), s{1}));
        if exist(f, 'file')
            D = read_numeric(f); plot(D(:,1), D(:,2), 'r-', 'LineWidth', 1.5, 'DisplayName', ['Flow Sim ' s{1}]);
        end
    end
    if k == 1, legend('Location', 'southeast'); end
end
fprintf('Ladson zone titles used: %s | %s | %s\n', LC(1).title, LC(2).title, LC(3).title);

% ---- Part 2: NACA 4412 at 13.87 deg -------------------------------------
E  = read_tecplot_dat(fullfile(ref, 'naca4412.cp.expt.dat'));
S  = read_tecplot_dat(fullfile(ref, 'n4412_cfl3d_cp_sa.dat'));
a4 = naca4('4412', 161, 'closed');
R  = panel_vortex(a4.x, a4.y, 13.87);
figure; hold on; grid on; set(gca, 'YDir', 'reverse');
title('NACA 4412, \alpha = 13.87^\circ, Re 1.52M'); xlabel('x/c'); ylabel('C_p');
plot(E.data(:,1), E.data(:,3), 'o', 'DisplayName', 'Coles & Wadcock (exp)');
plot(S.data(:,1), S.data(:,2), 'g-', 'DisplayName', 'NASA CFL3D SA');
plot(R.xc, R.cp, 'k--', 'DisplayName', 'Panel (inviscid, attached)');
xf = fullfile(root, 'data', 'xfoil', 'cp_naca4412_a13.87.txt');
if exist(xf, 'file'), X = read_numeric(xf); plot(X(:,1), X(:,end), 'b-', 'DisplayName', 'XFOIL'); end
for s = {'upper', 'lower'}
    f = fullfile(root, 'data', 'results', sprintf('fs_cp_4412_a13.87_%s.csv', s{1}));
    if exist(f, 'file')
        D = read_numeric(f); plot(D(:,1), D(:,2), 'r-', 'LineWidth', 1.5, 'DisplayName', ['Flow Sim ' s{1}]);
    end
end
legend('Location', 'southeast');
fprintf('Panel-method CL at 13.87 deg (no separation): %.3f\n', R.cl);

