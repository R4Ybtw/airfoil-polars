%% make_inputs.m — generate all geometry and XFOIL inputs for both airfoils
%
% Run once from the project folder:  run('src/make_inputs.m')
% Writes into cad/ (SolidWorks curves) and data/xfoil/ (XFOIL inputs).

clear; clc;
here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
addpath(here);

% Chords that give each experiment's Re at Mach 0.15 (see flow_conditions.m)
F12 = flow_conditions(6.0e6);   c0012 = F12.chord;
F44 = flow_conditions(1.52e6);  c4412 = F44.chord;
fprintf('Chords: NACA 0012 %.4f m, NACA 4412 %.4f m, U = %.2f m/s\n', c0012, c4412, F12.U);

a12 = naca4('0012', 161, 'scaled');   % exactly the NASA TMR NACA 0012
a44 = naca4('4412', 161, 'closed');   % the NASA TMR NACA 4412 (0.1036 term)

write_airfoil_files(a12, fullfile(root, 'cad'), c0012, 'naca0012');
write_airfoil_files(a44, fullfile(root, 'cad'), c4412, 'naca4412');
copyfile(fullfile(root, 'cad', 'naca0012.dat'), fullfile(root, 'data', 'xfoil'));
copyfile(fullfile(root, 'cad', 'naca4412.dat'), fullfile(root, 'data', 'xfoil'));

old = cd(fullfile(root, 'data', 'xfoil'));
xfoil_deck('naca0012.dat', 6.0e6,  0.15, -4:1:20,          'forced', 'polar_0012_forced.txt', [0 10 15]);
movefile('deck_naca0012.txt', 'deck_naca0012_forced.txt');
xfoil_deck('naca0012.dat', 6.0e6,  0.15, -4:1:20,          'free',   'polar_0012_free.txt',   []);
movefile('deck_naca0012.txt', 'deck_naca0012_free.txt');
xfoil_deck('naca4412.dat', 1.52e6, 0.15, [-6:1:13 13.87 14:1:18], 'forced', 'polar_4412_forced.txt', 13.87);
movefile('deck_naca4412.txt', 'deck_naca4412_forced.txt');
cd(old);

fprintf('Max thickness: 0012 %.4f c (TMR quotes 11.894%%), 4412 %.4f c\n', ...
        max(a12.yu - interp1(a12.xl, a12.yl, a12.xu)), max(a44.yu - interp1(a44.xl, a44.yl, a44.xu)));
per = @(a) sum(sqrt(diff(a.x).^2 + diff(a.y).^2));
fprintf('Perimeters (for the span check): 0012 %.4f m, 4412 %.4f m\n', per(a12)*c0012, per(a44)*c4412);
fprintf('Done. Geometry in cad/, XFOIL decks in data/xfoil/.\n');
