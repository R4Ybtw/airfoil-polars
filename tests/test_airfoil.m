%% test_airfoil.m — verification of everything that doesn't need SolidWorks
%
% Run from the project folder:   addpath tests; test_airfoil
% Each test compares against an answer known exactly or independently.

function test_airfoil()
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'src'));
ok = true;

%% 1. Geometry
a = naca4('0012', 401, 'open');
t = a.yu - a.yl;
ok = chk('0012 open: max thickness = 0.12 c', max(t), 0.12, 2e-3) && ok;
ok = chk('0012 open: TE gap 0.252% c (XFOIL reports 0.00252)', t(end), 0.00252, 2e-2) && ok;
a = naca4('0012', 401, 'scaled');
ok = chk('0012 scaled: max t = 11.894% c (NASA TMR)', max(a.yu - a.yl), 0.11894, 1e-3) && ok;
ok = chk('0012 scaled: sharp TE', abs(a.yu(end)) + 1, 1, 1e-12) && ok;
a = naca4('4412', 401, 'closed');
ok = chk('4412: max camber 0.04 c at 0.4 c', max(a.yc), 0.04, 1e-3) && ok;

%% 2. Panel method against the exact Karman-Trefftz solution
err = zeros(1, 3); ns = [101 201 401];
for k = 1:3
    J = karman_trefftz_exact(0.1, 0.05, 10, 5, ns(k));
    R = panel_vortex(J.x, J.y, 5);
    err(k) = abs(R.cl - J.cl)/J.cl;
end
ok = chk('Panel vs exact CL, 201 points (rel err)', err(2) + 1, 1, 1e-3) && ok;
order = log2(err(1:2)./err(2:3));
fprintf('   observed order of convergence: %.2f, %.2f (expect ~2)\n', order);
ok = chk('Panel convergence order', mean(order), 2, 0.15) && ok;

% Moment: a THICK symmetric airfoil has a small nonzero Cm(c/4) in inviscid
% flow (its aerodynamic centre is slightly aft of c/4). Check against the
% exact moment from integrating the exact pressure.
J = karman_trefftz_exact(0.1, 0, 10, 10, 6001);
x = J.x; y = J.y; cp = J.cp; cp([1 end]) = cp([2 end-1]);
xm = 0.5*(x(1:end-1) + x(2:end)); ym = 0.5*(y(1:end-1) + y(2:end));
cpm = 0.5*(cp(1:end-1) + cp(2:end)); dx = diff(x); dy = diff(y);
Mz = sum((xm - (min(x) + 0.25*J.chord)).*(cpm.*dx) - ym.*(-cpm.*dy));
R = panel_vortex(x(1:10:end), y(1:10:end), 10);
ok = chk('Panel Cm(c/4) vs exact, symmetric KT 10 deg', R.cm, -Mz/J.chord^2, 3e-2) && ok;

%% 3. Physics checks on NACA sections
a = naca4('0012', 161, 'scaled');
R = panel_vortex(a.x, a.y, [0 5]);
ok = chk('Symmetric airfoil at 0 deg: CL = 0', R(1).cl + 1, 1, 1e-6) && ok;
ok = chk('CL by circulation = CL by pressure', R(2).cl_p, R(2).cl, 1e-2) && ok;
ok = chk('d''Alembert: pressure drag ~ 0', abs(R(2).cd_p) + 1, 1, 2e-3) && ok;
slope = (R(2).cl - R(1).cl)/5;
ok = chk('Lift slope ~ 2pi(1+0.77t/c) per rad', slope, 2*pi*(1 + 0.77*0.11894)*pi/180, 1e-2) && ok;
a = naca4('4412', 161, 'closed');
R = panel_vortex(a.x, a.y, 0);
ok = chk('4412 Cm(c/4) near thin-airfoil -0.106', R.cm, -0.106, 0.06) && ok;

%% 4. Body-axis forces -> lift and drag (the alpha rotation)
al = [0 8 15]'; CL = [0.1 0.9 1.5]'; CD = [0.008 0.011 0.02]';
F = flow_conditions(6e6); span = 0.01; qcs = F.q*F.chord*span;
Lf = CL*qcs; Df = CD*qcs;
Fx = Df.*cosd(al) - Lf.*sind(al);         % inverse rotation
Fy = Df.*sind(al) + Lf.*cosd(al);
C = flowsim_to_coeffs(al, Fx, Fy, zeros(3,1), F.rho, F.U, F.chord, span);
ok = chk('Rotation recovers CL at 15 deg', C.cl(3), 1.5, 1e-12) && ok;
ok = chk('Rotation recovers CD at 15 deg', C.cd(3), 0.02, 1e-12) && ok;

%% 5. File readers
f = [tempname '.txt'];
fid = fopen(f, 'w');
fprintf(fid, '\n       XFOIL         Version 6.99\n\n Calculated polar for: NACA 0012\n\n');
fprintf(fid, ' 1 1 Reynolds number fixed          Mach number fixed\n\n');
fprintf(fid, ' xtrf =   0.050 (top)        0.050 (bottom)\n');
fprintf(fid, ' Mach =   0.150     Re =     6.000 e 6     Ncrit =   9.000\n\n');
fprintf(fid, '  alpha    CL        CD       CDp       CM     Top_Xtr  Bot_Xtr\n');
fprintf(fid, ' ------ -------- --------- --------- -------- -------- --------\n');
fprintf(fid, '  0.000   0.0000   0.00812   0.00121   0.0000   0.0500   0.0500\n');
fprintf(fid, ' 10.000   1.0800   0.01200   0.00500   0.0050   0.0500   0.0500\n');
fclose(fid);
P = read_xfoil_polar(f); delete(f);
ok = chk('XFOIL reader: CL at 10 deg', P.cl(2), 1.08, 1e-12) && ok;
ok = chk('XFOIL reader: Re from header', P.Re, 6e6, 1e-12) && ok;
Z = read_tecplot_dat(fullfile(here, '..', 'data', 'reference', 'CLCD_Ladson_expdata.dat'));
ok = chk('Ladson file: 3 zones', numel(Z), 3, 0) && ok;
ok = chk('Ladson 80 grit CL at 10.12 deg', Z(1).data(8,2), 1.0707, 1e-12) && ok;

if ok, fprintf('\nALL TESTS PASS\n'); else, fprintf('\nSOME TESTS FAILED\n'); end
end

function ok = chk(name, got, want, reltol)
    if want == 0, e = abs(got); else, e = abs(got - want)/abs(want); end
    ok = e <= reltol;
    s = 'FAIL'; if ok, s = 'PASS'; end
    fprintf('%-48s got %10.5g  want %10.5g  -> %s\n', name, got, want, s);
end
