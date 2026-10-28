function res = panel_vortex(x, y, alpha_deg)
%PANEL_VORTEX  Inviscid lift and pressure by the linear-strength vortex panel method.
%
%   res = panel_vortex(x, y, alpha_deg)
%
%   x, y       closed airfoil loop in XFOIL order (TE -> upper -> LE -> lower -> TE),
%              chord along x. Output of naca4() works directly.
%   alpha_deg  angle(s) of attack in degrees (vector allowed)
%
%   Output struct res (one entry per angle):
%     .alpha   deg
%     .cl      lift coefficient from the circulation (Kutta-Joukowski)
%     .cl_p    lift coefficient from integrating surface pressure (cross-check)
%     .cd_p    pressure drag from the same integral; ~0 (d'Alembert's paradox)
%     .cm      moment coefficient about the quarter chord (nose-up positive)
%     .xc,.yc  control points (panel midpoints)
%     .cp      pressure coefficient at the control points
%
%   Method (Kuethe & Chow, Foundations of Aerodynamics, 5th ed., ch. 5):
%   * The surface is cut into M straight panels. Each panel carries a vortex
%     sheet whose strength varies linearly along it, continuous from panel to
%     panel, so there are M+1 unknown strengths at the panel corners.
%   * At each panel midpoint, the flow normal to the surface must be zero
%     (M equations). The Kutta condition — the flow leaves the sharp trailing
%     edge smoothly, so the strengths at the two TE corners cancel — is the
%     last equation. Solving the linear system gives the strengths; the
%     tangential velocity then gives Cp = 1 - (V/Vinf)^2.
%   * Inviscid: no boundary layer, no drag (pressure drag integrates to ~0,
%     which is itself a check: d'Alembert's paradox), no stall.
%
%   The panel loop must run clockwise for this formulation, so the XFOIL-order
%   input is reversed internally.

    xb = flipud(x(:)); yb = flipud(y(:));          % clockwise: TE -> lower -> LE -> upper -> TE
    if abs(xb(1) - xb(end)) > 1e-12 || abs(yb(1) - yb(end)) > 1e-12
        % open (blunt) trailing edge: close the loop at the mean TE point
        xm = 0.5*(xb(1) + xb(end)); ym = 0.5*(yb(1) + yb(end));
        xb = [xm; xb; xm]; yb = [ym; yb; ym];
    end
    M  = numel(xb) - 1;
    xc = 0.5*(xb(1:M) + xb(2:M+1));
    yc = 0.5*(yb(1:M) + yb(2:M+1));
    dx = diff(xb); dy = diff(yb);
    S  = sqrt(dx.^2 + dy.^2);
    th = atan2(dy, dx);

    % Influence coefficients (geometry only — independent of alpha)
    % Written with whole matrices (row i = control point, column j = panel)
    % instead of a double loop: same formulas, ~100x faster in MATLAB/Octave.
    XI = repmat(xc, 1, M);   YI = repmat(yc, 1, M);      % control point i
    XJ = repmat(xb(1:M)', M, 1); YJ = repmat(yb(1:M)', M, 1);   % start of panel j
    TI = repmat(th, 1, M);   TJ = repmat(th', M, 1);
    SJ = repmat(S', M, 1);
    A = -(XI - XJ).*cos(TJ) - (YI - YJ).*sin(TJ);
    B = (XI - XJ).^2 + (YI - YJ).^2;
    C = sin(TI - TJ);
    D = cos(TI - TJ);
    E = (XI - XJ).*sin(TJ) - (YI - YJ).*cos(TJ);
    F = log(1 + SJ.*(SJ + 2*A)./B);
    G = atan2(E.*SJ, B + A.*SJ);
    P = (XI - XJ).*sin(TI - 2*TJ) + (YI - YJ).*cos(TI - 2*TJ);
    Q = (XI - XJ).*cos(TI - 2*TJ) - (YI - YJ).*sin(TI - 2*TJ);
    CN2 = D + 0.5*Q.*F./SJ - (A.*C + D.*E).*G./SJ;
    CN1 = 0.5*D.*F + C.*G - CN2;
    CT2 = C + 0.5*P.*F./SJ + (A.*D - C.*E).*G./SJ;
    CT1 = 0.5*C.*F - D.*G - CT2;
    d = logical(eye(M));                     % a panel acting on its own midpoint
    CN1(d) = -1; CN2(d) = 1; CT1(d) = pi/2; CT2(d) = pi/2;
    AN = zeros(M+1); AT = zeros(M, M+1);
    AN(1:M,1)   = CN1(:,1);   AN(1:M,M+1) = CN2(:,M);
    AT(:,1)     = CT1(:,1);   AT(:,M+1)   = CT2(:,M);
    AN(1:M,2:M) = CN1(:,2:M) + CN2(:,1:M-1);
    AT(:,2:M)   = CT1(:,2:M) + CT2(:,1:M-1);
    AN(M+1,1) = 1; AN(M+1,M+1) = 1;                 % Kutta condition

    chord = max(xb) - min(xb);
    xle = min(xb);
    res = struct('alpha', {}, 'cl', {}, 'cl_p', {}, 'cd_p', {}, 'cm', {}, 'xc', {}, 'yc', {}, 'cp', {});
    for k = 1:numel(alpha_deg)
        al  = alpha_deg(k)*pi/180;
        rhs = [sin(th - al); 0];
        g   = AN\rhs;                               % strengths, scaled by 2*pi*Vinf
        V   = cos(th - al) + AT*g;                  % surface speed / Vinf
        cp  = 1 - V.^2;

        % Lift from total circulation: Gamma = sum of panel-average strength x length
        Gam = 2*pi*sum(0.5*(g(1:M) + g(2:M+1)).*S);
        cl  = 2*Gam/chord;

        % Cross-check: integrate pressure. Force on panel = -cp * outward normal * S
        nx = -sin(th); ny = cos(th);                % for a clockwise loop this normal points outward
        fx = sum(-cp.*nx.*S)/chord; fy = sum(-cp.*ny.*S)/chord;
        cl_p = fy*cos(al) - fx*sin(al);
        cd_p = fx*cos(al) + fy*sin(al);    % should be ~0: no drag without viscosity
        % moment about c/4: counter-clockwise is nose-DOWN for an airfoil pointing left,
        % so flip the sign to get the usual nose-up-positive Cm
        mz  = -sum(-cp.*S.*((xc - (xle + 0.25*chord)).*ny - yc.*nx))/chord^2;

        res(k).alpha = alpha_deg(k);
        res(k).cl = cl; res(k).cl_p = cl_p; res(k).cd_p = cd_p; res(k).cm = mz;
        res(k).xc = xc; res(k).yc = yc; res(k).cp = cp;
    end
end
