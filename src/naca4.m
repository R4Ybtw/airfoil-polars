function af = naca4(code, n, te, chord)
%NACA4  Coordinates of a NACA 4-digit airfoil.
%
%   af = naca4('4412')                     160 points per surface, closed TE, chord 1
%   af = naca4(code, n, te, chord)
%
%   code   4-digit string, e.g. '0012', '4412'
%   n      points per surface (upper and lower each), cosine-spaced so they
%          bunch up at the leading and trailing edges where curvature is high
%   te     trailing-edge option:
%            'open'    original NACA thickness (0.1015 x^4 term) -> blunt TE,
%                      about 0.25% chord thick
%            'closed'  0.1036 x^4 term -> sharp TE at x = 1. Tiny shape change;
%                      this is what NASA TMR uses for its NACA 4412 case
%            'scaled'  original formula run to x = 1.008930411365, where it
%                      closes, then scaled back to chord 1. Exactly the NASA TMR
%                      definition of the NACA 0012 (symmetric airfoils only)
%   chord  chord length (any unit; the output uses the same unit)
%
%   Output struct af:
%     .x, .y     closed loop in XFOIL order: TE -> upper surface -> LE ->
%                lower surface -> TE (counter-clockwise). First and last
%                points are both the trailing edge.
%     .xu,.yu    upper surface, LE -> TE
%     .xl,.yl    lower surface, LE -> TE
%     .xc,.yc    camber line
%     .name      e.g. 'NACA 4412 (closed TE)'
%
%   Formulas (Abbott & von Doenhoff, Theory of Wing Sections, sec. 6.4):
%     thickness  yt = 5t(0.2969 sqrt(x) - 0.1260x - 0.3516x^2 + 0.2843x^3 - k4 x^4)
%     camber     yc = m/p^2 (2px - x^2)              for x <  p
%                yc = m/(1-p)^2 ((1-2p) + 2px - x^2) for x >= p
%     Thickness is laid off PERPENDICULAR to the camber line, not vertically.

    if nargin < 2 || isempty(n),     n = 160; end
    if nargin < 3 || isempty(te),    te = 'closed'; end
    if nargin < 4 || isempty(chord), chord = 1; end
    if ~ischar(code) || numel(code) ~= 4
        error('code must be a 4-character string such as ''0012''.');
    end
    m = str2double(code(1))/100;      % max camber
    p = str2double(code(2))/10;       % location of max camber
    t = str2double(code(3:4))/100;    % thickness

    beta = linspace(0, pi, n)';
    x = 0.5*(1 - cos(beta));          % cosine spacing, 0..1

    switch lower(te)
        case 'open',   k4 = 0.1015; xs = 1;
        case 'closed', k4 = 0.1036; xs = 1;
        case 'scaled'
            if m ~= 0, error('''scaled'' TE is defined for symmetric airfoils only.'); end
            k4 = 0.1015; xs = 1.008930411365;
        otherwise, error('te must be ''open'', ''closed'' or ''scaled''.');
    end
    xe = x*xs;                         % evaluate the formula on the stretched range
    yt = 5*t*(0.2969*sqrt(xe) - 0.1260*xe - 0.3516*xe.^2 + 0.2843*xe.^3 - k4*xe.^4)/xs;

    yc = zeros(size(x)); dyc = zeros(size(x));
    if m > 0
        f = x < p;
        yc(f)   = m/p^2*(2*p*x(f) - x(f).^2);
        dyc(f)  = 2*m/p^2*(p - x(f));
        yc(~f)  = m/(1-p)^2*((1 - 2*p) + 2*p*x(~f) - x(~f).^2);
        dyc(~f) = 2*m/(1-p)^2*(p - x(~f));
    end
    th = atan(dyc);

    xu = x - yt.*sin(th);  yu = yc + yt.*cos(th);
    xl = x + yt.*sin(th);  yl = yc - yt.*cos(th);
    if strcmpi(te, 'closed') || strcmpi(te, 'scaled')
        yu(end) = yc(end); yl(end) = yc(end);   % remove round-off at the sharp TE
    end

    af.xu = chord*xu; af.yu = chord*yu;
    af.xl = chord*xl; af.yl = chord*yl;
    af.xc = chord*x;  af.yc = chord*yc;
    % XFOIL order: TE -> upper -> LE -> lower -> TE (LE point not duplicated)
    af.x = [flipud(af.xu); af.xl(2:end)];
    af.y = [flipud(af.yu); af.yl(2:end)];
    af.name = sprintf('NACA %s (%s TE)', code, lower(te));
    af.chord = chord;
end
