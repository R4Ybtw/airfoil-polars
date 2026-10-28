function Z = read_tecplot_dat(file)
%READ_TECPLOT_DAT  Read the simple Tecplot-style ASCII files NASA TMR provides.
%
%   Z = read_tecplot_dat('data/reference/CLCD_Ladson_expdata.dat')
%   Z(k).title  zone title, e.g. '80 grit' ('' if the file has no zones)
%   Z(k).data   numeric matrix, one column per variable
%   Z(k).vars   variable names from the 'variables=' line
%
%   Handles '#' comment lines, a 'variables=' line, 'zone, t="..."' lines
%   and whitespace-separated numbers.

    txt = fileread(file);
    lines = regexp(txt, '\r?\n', 'split');
    vars = {};
    Z = struct('title', {}, 'data', {}, 'vars', {});
    cur = 0;
    for k = 1:numel(lines)
        s = strtrim(lines{k});
        if isempty(s) || s(1) == '#', continue; end
        if strncmpi(s, 'variables', 9)
            vars = regexp(s, '"([^"]*)"', 'tokens');
            vars = cellfun(@(c) c{1}, vars, 'UniformOutput', false);
            continue
        end
        if strncmpi(s, 'zone', 4)
            t = regexp(s, 't\s*=\s*"([^"]*)"', 'tokens', 'once');
            cur = cur + 1;
            Z(cur).title = ''; if ~isempty(t), Z(cur).title = t{1}; end
            Z(cur).data = []; Z(cur).vars = vars;
            continue
        end
        v = sscanf(s, '%f')';
        if isempty(v), continue; end
        if cur == 0
            cur = 1; Z(1).title = ''; Z(1).data = []; Z(1).vars = vars;
        end
        Z(cur).data(end+1, 1:numel(v)) = v;
    end
end
