function D = read_numeric(file)
%READ_NUMERIC  Numeric rows of a text file (e.g. an XFOIL CPWR dump), skipping
%   '#' comment lines and any text header lines.
    L = regexp(fileread(file), '\r?\n', 'split'); D = [];
    for k = 1:numel(L)
        if ~isempty(strfind(L{k}, '#')), continue; end
        v = sscanf(L{k}, '%f')';
        if ~isempty(v), D(end+1, 1:numel(v)) = v; end %#ok<AGROW>
    end
end
