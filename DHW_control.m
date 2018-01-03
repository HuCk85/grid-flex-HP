function output = DHW_control(simParam, DHWParam, DHWconsData, priceData)

n = length(DHWconsData);

%Constants
Tinlet = 10; %inletwater
Cp_water = 4.18/3600;%kWh/Cm3

%Variabler
Ttank = zeros(1,n+1); Ttank(1) = DHWParam.Tref;
Etank = zeros(1,n+1);  %Energy content in the hot water tank
Qcharge = zeros(1,n); %Energy supplied to the tank
Ptap = zeros(1,n); %Electric boiler capacity
Etank(1) = DHWParam.Vtank*Cp_water*(DHWParam.Tref-Tinlet)/3600;
Qchargeshadow = zeros(1,n);
Ptapshadow = zeros(1,n);
Etankshadow = zeros(1,n+1);Etank(1) = DHWParam.Vtank*Cp_water*(DHWParam.Tref-Tinlet)/3600;
Ttankshadow = zeros(1,n+1); Ttankshadow(1) = DHWParam.Tref; Trefshadow = zeros(1,n);

for i = 1:n
    
    if Ttank(i) >= DHWParam.Tref + DHWParam.delta/2 %over reference temp
        Qcharge(i) = 0;
        Ptap(i) = 0;
        
        
    elseif Ttank(i) < DHWParam.Tref - DHWParam.delta/2
        Qcharge(i) = DHWParam.COP*DHWParam.Ptap*simParam.dt;
        Ptap(i) = DHWParam.Ptap;
        
    else
        if i > 1
            Qcharge(i) = Qcharge(i-1);
            Ptap(i) = Ptap(i-1);
            
        else
            Qcharge(i) = 0;
            Ptap(i) = 0;
        end
        
    end
    
    Ttank(i+1) = Ttank(i) + (Qcharge(i) - DHWconsData(i))/(DHWParam.Vtank *Cp_water);
    
    if Ttank(i+1) < Tinlet
        Ttank(i+1) = Tinlet;
    end
    
    Etank(i+1) =  DHWParam.Vtank*Cp_water*(Ttank(i+1)-Tinlet);

%flexibilitet
    
%     Trefsh = TCflexCharge(DHWParam.Tref, flexParam, priceData(i));
%     
%     if Ttankshadow(i) >= Trefsh + DHWParam.delta/2 %over reference temp
%         Qchargeshadow(i) = 0;
%         Ptapshadow(i) = 0;
%         
%         
%     elseif Ttankshadow(i) < Trefsh- DHWParam.delta/2
%         Qchargeshadow(i) = DHWParam.Ptap*simParam.dt;
%         Ptapshadow(i) = DHWParam.Ptap;
%         
%     else
%         if i > 1
%             Qchargeshadow(i) = Qchargeshadow(i-1);
%             Ptapshadow(i) = Ptap(i-1);
%             
%         else
%             Qchargeshadow(i) = 0;
%             Ptapshadow(i) = 0;
%         end
%         
%     end
% 
%     Ttankshadow(i+1) = Ttankshadow(i) + (Qchargeshadow(i) - DHWconsData(i))/(DHWParam.Vtank *Cp_water);
%     
%     if Ttankshadow(i+1) < Tinlet
%         Ttankshadow(i+1) = Tinlet;
%     end
%     
%     Etankshadow(i+1) =  DHWParam.Vtank*Cp_water*(Ttankshadow(i+1)-Tinlet);
%     Trefshadow(i) = Trefsh;
%     
end

output.Preg= Ptap;
output.T = Ttank(1:end-1);
output.Tshadow = Ttankshadow(1:end-1);
output.Pregshadow = Ptapshadow;
output.Trefshadow = Trefshadow;

end
