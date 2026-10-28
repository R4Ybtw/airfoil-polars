function P = read_xfoil_polar(file)
%READ_XFOIL_POLAR  Read an XFOIL polar save file (PACC output).
%
%   P = read_xfoil_polar('polar_0012.txt')
%   P.alpha, P.cl, P.cd, P.cdp, P.cm, P.xtr_top, P.xtr_bot  (column vectors)
%   P.Re, P.M  read from the header if present
%
%   The file has a text header ending in a row of dashes, then one row per
%   converged angle. Angles that failed to converge are simply missing —
%   check for gaps before you plot.

    txt = fileread(file);
    lines = regexp(txt, '\r?\n', 'split');
    P.Re = NaN; P.M = NaN;
    k0 = 0;
    for k = 1:numel(lines)
        tk = regexp(lines{k}, 'Mach\s*=\s*([-\d.Ee+]+)\s+Re\s*=\s*([\d.\s]+)e\s*([-+]?\s*\d+)', 'tokens', 'once');
        if ~isempty(tk)
            P.M  = str2double(tk{1});
            P.Re = str2double(strrep(tk{2}, ' ', ''))*10^str2double(strrep(tk{3}, ' ', ''));
        end
        if ~isempty(regexp(lines{k}, '^\s*-{5,}', 'once')), k0 = k; end
    end
    if k0 == 0, error('No dashed separator line found — is this an XFOIL polar file?'); end
    D = [];
    for k = k0+1:numel(lines)
        v = sscanf(lines{k}, '%f')';
        if numel(v) >= 7, D(end+1, 1:7) = v(1:7); end %#ok<AGROW>
    end
    if isempty(D), error('Polar file has no converged points.'); end
    [~, i] = sort(D(:,1)); D = D(i,:);
    P.alpha = D(:,1); P.cl = D(:,2); P.cd = D(:,3); P.cdp = D(:,4);
    P.cm = D(:,5); P.xtr_top = D(:,6); P.xtr_bot = D(:,7);
end
