function [ Psh, Paux ] = HVACdimensioning(buildingParam, HVACParam, coverage, supply )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

peak_demand = buildingParam.lambda*(HVACParam.Tref-HVACParam.TDUT);

if strcmp(supply, 'mono')
    Paux = 0;
    Psh = coverage*peak_demand/HVACParam.COP;
    
elseif strcmp(supply, 'mono-energetic') %hela energibehovet täcks med 
    Paux = (1-coverage)*peak_demand;
    Psh = coverage*peak_demand/HVACParam.COP;
    
elseif strcmp(supply, 'bivalent')
    Paux = (1-coverage)*peak_demand;
    Psh = coverage*peak_demand/HVACParam.COP;

end

%HVACParam.COP

end
