function [Php, Ppeak] = heatingDimensioning(HVACParam, buildingParam)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if strcmp(HVACParam.supply, 'mono')
    Ppeak = 0;
    Php = buildingParam.lambda*(HVACParam.Tref - HVACParam.TDUT)/HVACParam.COP;
    
elseif strcmp(HVACParam.supply, 'bivalent')   
    Php = buildingParam.lambda*(HVACParam.Tref - HVACParam.Thp)/HVACParam.COP;
    Ppeak = buildingParam.lambda*(HVACParam.Tref - HVACParam.TDUT) - Php;
end

end

