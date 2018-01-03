function [ Php, duty, degreemin] = heatpump_control(buildingParam, HVACParam, controlParam, Tstar, duty, degreemin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

Qdrop = controlParam.calibration*buildingParam.lambda*(HVACParam.Tref-Tstar); %The energy loss seen by the building

if duty == 1
    
    Php = HVACParam.Php;
    Qreg = HVACParam.COP*Php;
    Tdiff = (1/(buildingParam.lambda*buildingParam.tau))*(Qreg-Qdrop)*(1/60);
    degreemin = degreemin + Tdiff;
    
    if degreemin >= controlParam.deltaOutdoor %when it is too warm, the heat pump is turned off
        duty = 0;
    end
    
else
    
    Php = 0;
    Tdiff = (1/(buildingParam.lambda*buildingParam.tau))*(-Qdrop)*(1/60);
    degreemin = degreemin + Tdiff;
    
    if degreemin < -controlParam.deltaOutdoor %when it is too cold, the heat pump is turned on
        duty = 1;
    end
    
end


end

