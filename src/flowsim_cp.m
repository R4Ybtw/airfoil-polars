function [xc, cp] = flowsim_cp(file, chord, p_inf, rho, U, x_key, p_key)
%FLOWSIM_CP  Surface Cp from a Flow Simulation XY-plot export (MATLAB only).
%
%   [xc, cp] = flowsim_cp('data/flowsim_exports/0012_a10_upper.xlsx', 1.766, 101325, 1.204, 51.5)
%
%   Export one XY plot per surface (upper and lower curves) with Pressure
%   against Model X. The curves sit with the quarter chord at the origin, so
%   x/c = X/chord + 0.25.
%   Cp = (p - p_inf) / (0.5 rho U^2), where p_inf is the AMBIENT pressure
%   set in the wizard (static, not total).
%
%   x_key, p_key: text that identifies the two columns (defaults 'X', 'Pressure').

    if nargin < 6 || isempty(x_key), x_key = 'X'; end
    if nargin < 7 || isempty(p_key), p_key = 'Pressure'; end
    T = readtable(file, 'VariableNamingRule', 'preserve');
    names = T.Properties.VariableNames;
    ix = find(contains(names, x_key), 1);
    ip = find(contains(names, p_key), 1);
    if isempty(ix) || isempty(ip)
        fprintf('Headers: %s\n', strjoin(names, ' | '));
        error('Could not find the X or pressure column; pass x_key / p_key.');
    end
    X = T{:, ix}; p = T{:, ip};
    ok = ~isnan(X) & ~isnan(p);
    X = X(ok); p = p(ok);
    if max(abs(X)) > 10*chord, X = X/1000; end     % exported in mm
    xc = X/chord + 0.25;
    cp = (p - p_inf)/(0.5*rho*U^2);
    [xc, i] = sort(xc); cp = cp(i);
end
