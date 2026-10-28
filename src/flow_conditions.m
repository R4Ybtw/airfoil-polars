function F = flow_conditions(Re)
%FLOW_CONDITIONS  Air properties, speed and chord for a target Reynolds number.
%
%   F = flow_conditions(6e6)   ->  F.rho, F.mu, F.nu, F.a, F.U, F.M, F.q, F.chord, F.p, F.T
%
%   Single source of truth for every script in this project. Mach is fixed
%   at 0.15 ("essentially incompressible", as NASA TMR recommends) and the
%   chord is chosen to give the requested Re.
%
%   EDIT the property values below to match Flow Simulation's Engineering
%   Database (Gases > Air at 293.2 K), so the Re you report is the Re it solved.

    F.T   = 293.2;            % K
    F.p   = 101325;           % Pa
    Rgas  = 287.05;           % J/(kg K)
    gam   = 1.4;
    F.mu  = 1.825e-5;         % Pa s
    F.rho = F.p/(Rgas*F.T);
    F.nu  = F.mu/F.rho;
    F.a   = sqrt(gam*Rgas*F.T);
    F.M   = 0.15;
    F.U   = F.M*F.a;
    F.q   = 0.5*F.rho*F.U^2;
    F.Re  = Re;
    F.chord = Re*F.nu/F.U;
end
