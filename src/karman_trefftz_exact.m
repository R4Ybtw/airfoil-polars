function J = karman_trefftz_exact(mx, my, tau_deg, alpha_deg, n)
%KARMAN_TREFFTZ_EXACT  Exact inviscid flow over a Karman-Trefftz airfoil (test oracle).
%
%   J = karman_trefftz_exact(mx, my, tau_deg, alpha_deg, n)
%
%   Flow around a circle is known exactly. A conformal map carries the circle
%   (centre (-mx, my), passing through zeta = 1) into an airfoil, and carries
%   the flow with it, so the airfoil's lift and surface pressure are known exactly.
%     mx   ~ thickness   (0.1 gives roughly 12%)
%     my   ~ camber      (0.05 gives roughly 2.5%)
%     tau  trailing-edge angle in degrees. tau -> 0 is the Joukowski airfoil
%          (a cusp); use tau > 0 for panel-code tests — see note below.
%   n  number of surface points.
%
%   Output: J.x, J.y (closed loop, XFOIL order: TE -> upper -> LE -> lower -> TE)
%           J.cl (exact), J.chord, J.cp (exact surface Cp at the points, NaN at TE)
%
%   NOTE on cusps: with tau = 0 AND camber, the two trailing-edge panels are
%   parallel and the panel method's Kutta condition becomes degenerate; it then
%   stalls at ~1.4% error however many panels you use. With tau = 10 deg it
%   converges at second order. Real NACA sections have a finite TE angle.

    al = alpha_deg*pi/180;  b = 1;
    z0 = -mx + 1i*my;
    a  = abs(b - z0);                     % circle passes through zeta = b
    be = asin(my/a);
    k  = 2 - tau_deg/180;                 % map exponent (2 = Joukowski)
    th = linspace(-be, -be + 2*pi, n)';
    zeta = z0 + a*exp(1i*th);
    zp = (zeta + b).^k;  zm = (zeta - b).^k;
    z  = k*b*(zp + zm)./(zp - zm);

    Gam = 4*pi*a*sin(al + be);            % Kutta condition at the TE
    W   = exp(-1i*al) - a^2*exp(1i*al)./(zeta - z0).^2 + 1i*Gam./(2*pi*(zeta - z0));
    dzdzeta = 4*k^2*b^2*(zeta - b).^(k-1).*(zeta + b).^(k-1)./(zp - zm).^2;
    w   = W./dzdzeta;
    cp  = 1 - abs(w).^2;
    cp([1 end]) = NaN;                    % 0/0 at the trailing edge

    x = real(z); y = imag(z); x(end) = x(1); y(end) = y(1);
    J.x = x; J.y = y; J.cp = cp;
    J.chord = max(x) - min(x);
    J.cl = 2*Gam/J.chord;                 % L = rho*U*Gamma with U = 1
end
