%% run_panel_polars.m — inviscid polars from our own panel method
%
% The panel method has no boundary layer, so it predicts the lift slope and
% zero-lift angle of attached flow, zero drag, and never stalls. Everything
% the viscous results do differently from this line is a viscous effect.

clear; clc;
here = fileparts(mfilename('fullpath'));
addpath(here);
out = fullfile(here, '..', 'data', 'results');

cases = {'0012', 'scaled', -4:1:20; '4412', 'closed', -6:1:18};
for k = 1:size(cases, 1)
    af = naca4(cases{k,1}, 161, cases{k,2});
    al = cases{k,3};
    R  = panel_vortex(af.x, af.y, al);
    cl = [R.cl]'; cm = [R.cm]';
    p  = polyfit(al(abs(al) <= 6)', cl(abs(al) <= 6), 1);
    fprintf('NACA %s: lift slope %.4f /deg (%.3f /rad), zero-lift alpha %.2f deg, Cm(c/4) at 0 deg %.4f\n', ...
            cases{k,1}, p(1), p(1)*180/pi, -p(2)/p(1), cm(al == 0));
    fid = fopen(fullfile(out, sprintf('panel_%s.csv', cases{k,1})), 'w');
    fprintf(fid, 'alpha,cl,cm\n');
    fprintf(fid, '%.3f,%.6f,%.6f\n', [al' cl cm]');
    fclose(fid);
end
fprintf('\nThin-airfoil theory: slope 2*pi/rad = 0.1097 /deg; NACA 4412 zero-lift alpha -4.15 deg,\n');
fprintf('Cm(c/4) -0.106. Thickness raises the slope by roughly (1 + 0.77 t/c), about 9%% at 12%%.\n');
