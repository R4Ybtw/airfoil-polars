function deck = xfoil_deck(datfile, Re, M, alphas, transition, polarfile, cp_alphas)
%XFOIL_DECK  Write an XFOIL command file that computes a polar unattended.
%
%   deck = xfoil_deck('naca0012.dat', 6e6, 0.15, 0:1:18, 'forced', 'polar_0012.txt', [0 10 15])
%
%   Run it on Windows from the folder holding the files:
%       xfoil.exe < deck_naca0012.txt
%
%   transition:  'free'   -> free transition, e^N method with Ncrit = 9
%                           (a typical clean wind tunnel)
%                'forced' -> trip both surfaces at 5% chord (roughly matches a
%                           tripped experiment and "fully turbulent" CFD)
%   cp_alphas:   angles at which to also save the surface Cp (CPWR command)
%
%   How XFOIL works, in one line: an inviscid panel method like ours, coupled
%   to an integral boundary-layer model with transition prediction. Excellent
%   for attached flow; increasingly unreliable at and beyond stall.
%
%   NOTE: written to XFOIL 6.99's documented command syntax but NOT run here
%   (the Linux build available to me crashed). If XFOIL stops, run the same
%   commands by hand once to see which prompt differs. Blank lines matter:
%   each one returns up a menu level.

    if nargin < 7, cp_alphas = []; end
    [~, stem] = fileparts(datfile);
    deck = sprintf('deck_%s.txt', stem);
    L = {};
    L{end+1} = 'PLOP';                    % plotting options
    L{end+1} = 'G';                       % toggle graphics off, so no windows open
    L{end+1} = '';
    L{end+1} = ['LOAD ' datfile];
    L{end+1} = 'PANE';                    % re-panel with XFOIL's own spacing
    L{end+1} = 'OPER';
    L{end+1} = sprintf('VISC %.6g', Re);
    L{end+1} = sprintf('MACH %.4g', M);
    L{end+1} = 'ITER 300';
    L{end+1} = 'VPAR';
    if strcmpi(transition, 'forced')
        L{end+1} = 'XTR 0.05 0.05';
    else
        L{end+1} = 'N 9';
    end
    L{end+1} = '';                        % back to OPER
    L{end+1} = 'PACC';
    L{end+1} = polarfile;                 % polar save file
    L{end+1} = '';                        % no dump file
    % Sweep up from 0 then separately down, so each point starts from a
    % converged neighbour (XFOIL converges far better that way)
    up = alphas(alphas >= 0); dn = fliplr(alphas(alphas < 0));
    for a = up, L{end+1} = sprintf('ALFA %.3f', a); end
    if ~isempty(dn)
        L{end+1} = 'INIT';
        for a = dn, L{end+1} = sprintf('ALFA %.3f', a); end
    end
    L{end+1} = 'PACC';                    % close the polar
    for a = cp_alphas
        L{end+1} = sprintf('ALFA %.3f', a);
        L{end+1} = sprintf('CPWR cp_%s_a%g.txt', stem, a);
    end
    L{end+1} = '';
    L{end+1} = 'QUIT';

    fid = fopen(deck, 'w');
    fprintf(fid, '%s\n', L{:});
    fclose(fid);
    fprintf('Wrote %s  (run: xfoil.exe < %s)\n', deck, deck);
end
