function write_airfoil_files(af, outdir, chord_m, tag)
%WRITE_AIRFOIL_FILES  Export an airfoil for XFOIL and SolidWorks.
%
%   write_airfoil_files(af, outdir, chord_m, tag)
%
%   af       struct from naca4() with chord 1
%   chord_m  chord for the SolidWorks files, in metres (XFOIL file stays chord 1)
%   tag      file name stem, e.g. 'naca0012'
%
%   Writes:
%   <tag>.dat               XFOIL format: name line, then x y, chord 1,
%                           TE -> upper -> LE -> lower -> TE
%   <tag>_upper_mm.txt      upper surface, X Y Z in millimetres, for
%   <tag>_lower_mm.txt      SolidWorks Insert > Curve > Curve Through XYZ Points.
%   <tag>_loop_mm.txt       Whole closed outline.
%
%   SolidWorks: the airfoil is shifted so the QUARTER CHORD sits at the origin.
%   Then Flow Simulation's Torque (Z) about the origin is the quarter-chord
%   moment directly. Set the part's units to millimetres before inserting
%   the curves, then measure the chord to confirm the units were read correctly.

    if ~exist(outdir, 'dir'), mkdir(outdir); end

    fid = fopen(fullfile(outdir, [tag '.dat']), 'w');
    fprintf(fid, '%s\n', af.name);
    fprintf(fid, '%12.8f %12.8f\n', [af.x af.y]');
    fclose(fid);

    s = 1000*chord_m;                 % chord-1 coordinates -> mm
    x0 = 0.25;                        % quarter chord to the origin
    put(fullfile(outdir, [tag '_upper_mm.txt']), s*(af.xu - x0), s*af.yu);
    put(fullfile(outdir, [tag '_lower_mm.txt']), s*(af.xl - x0), s*af.yl);
    put(fullfile(outdir, [tag '_loop_mm.txt']),  s*(af.x  - x0), s*af.y);
end

function put(file, x, y)
    fid = fopen(file, 'w');
    fprintf(fid, '%.6f\t%.6f\t0\n', [x(:) y(:)]');
    fclose(fid);
end
