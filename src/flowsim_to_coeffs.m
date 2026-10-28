function C = flowsim_to_coeffs(alpha_deg, Fx, Fy, Mz, rho, U, chord, span)
%FLOWSIM_TO_COEFFS  Turn Flow Simulation body-axis forces into CL, CD, Cm.
%
%   C = flowsim_to_coeffs(alpha_deg, Fx, Fy, Mz, rho, U, chord, span)
%
%   The airfoil is fixed and the inflow comes in at angle alpha:
%   V = U (cos a, sin a). Flow Simulation reports forces along ITS X and Y
%   axes, but lift is defined perpendicular to the oncoming flow and drag
%   along it, so rotate by alpha:
%       L =  Fy cos a - Fx sin a
%       D =  Fx cos a + Fy sin a
%   At 15 degrees, forgetting this rotation puts about a quarter of the lift
%   into "drag" — the classic mistake with this setup.
%
%   Mz   Torque (Z) about the origin, which write_airfoil_files puts at the
%        quarter chord. The leading edge points to -x, so a nose-up moment is
%        clockwise, i.e. negative Mz: Cm = -Mz / (q c^2 span).
%   span depth the 2D solver integrated over (Flow Simulation surface area / airfoil perimeter).

    a  = alpha_deg(:)*pi/180;
    Fx = Fx(:); Fy = Fy(:); Mz = Mz(:);
    q  = 0.5*rho*U^2;
    L  = Fy.*cos(a) - Fx.*sin(a);
    D  = Fx.*cos(a) + Fy.*sin(a);
    C.alpha = alpha_deg(:);
    C.cl = L/(q*chord*span);
    C.cd = D/(q*chord*span);
    C.cm = -Mz/(q*chord^2*span);
end
