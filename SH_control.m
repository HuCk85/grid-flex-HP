function output = SH_control(simParam, buildingParam, HVACParam, flexParam, weatherData, priceData, outputApp)

n = simParam.n/simParam.dt;

Qloss = buildingParam.lambda*(HVACParam.Tref-weatherData.Tout);
Qsun =  0.5*buildingParam.A_window*weatherData.Psun;
Pint = outputApp.Pint;
Qheat = Qloss - (Pint + Qsun);

%Variabler
Preg = zeros(1,n); Qreg = zeros(1,n);
T = zeros(1,n); T(1) = HVACParam.T0;%+normrnd(0,0.5);

Tshadow = zeros(1,n); Tshadow(1) = HVACParam.Tref;
Pshadow = zeros(1,n); Trefshadow = zeros(1,n);
Qregshadow = zeros(1,n);

if mean(weatherData.Tout) < 15
    
    if strcmp(HVACParam.controller, 'outdoortemp')
        
        for i = 1:n
            
            if weatherData.Tout(i) < HVACParam.Tbreak
                COP = 1; %Elspets kör när det är för kallt
            else
                COP = HVACParam.COP; %värmepumpen kör
            end
            
            Qreg(i) = HVACParam.calibration*Qloss(i);
            
            if Qreg(i) > COP*HVACParam.Psh
                Qreg(i) = COP*HVACParam.Psh;
            end
            
            T(i+1) = T(i) + (1/(buildingParam.lambda*buildingParam.tau))*(Qreg(i) - Qheat(i))*simParam.dt;
            
            if T(i+1) > 25
                T(i+1) = T(i);
            end
            
            Preg(i) = Qreg(i)/COP;
            
            alpha = -flexParam.deltaT/(flexParam.priceMax - flexParam.priceMean);
            beta = (-flexParam.deltaT + HVACParam.Tref) - flexParam.priceMax*alpha;
            
            if priceData(i) >= flexParam.priceMax
                Trefshadow(i) = HVACParam.Tref - flexParam.deltaT;
            elseif priceData(i) <= (1/alpha)*(HVACParam.Tref + flexParam.deltaT)
                Trefshadow(i) = HVACParam.Tref + flexParam.deltaT;
            else
                Trefshadow(i) = alpha*priceData(i) + beta;
            end
            
            Qlossshadow = buildingParam.lambda*(Trefshadow(i)-weatherData.Tout(i));
            
            Qregshadow = HVACParam.calibration*Qlossshadow;
            
            if Qregshadow > COP*HVACParam.Psh
                Qregshadow = COP*HVACParam.Psh;
            end
            
            Pshadow(i) = Qregshadow/COP;
            Tshadow(i+1) = Tshadow(i) + (1/(buildingParam.lambda*buildingParam.tau))*(Qregshadow - Qheat(i))*simParam.dt;
            
        end
        
    end
    
    if strcmp(HVACParam.controller, 'indoortemp')
        
        for i = 1:n
            
            if weatherData.Tout(i) < HVACParam.Tbreak
                COP = 1;
            else
                COP = HVACParam.COP;
            end
            
            if T(i) > HVACParam.Tref + HVACParam.delta/2
                Qreg(i) = 0;
                Preg(i) = 0;
                
            elseif T(i) < HVACParam.Tref - HVACParam.delta/2
                Qreg(i) = COP*HVACParam.Psh;
                Preg(i) = HVACParam.Psh;
                
            else
                if i > 1
                    Qreg(i) = Qreg(i-1);
                    Preg(i) = Preg(i-1);
                else
                    Qreg(i) = 0;
                    Preg(i) = 0;
                end
                
            end
            
            T(i+1) = T(i) + (1/(buildingParam.lambda*buildingParam.tau))*(Qreg(i) - Qheat(i))*simParam.dt;
            
            if T(i+1) > 25
                T(i+1) = T(i);
            end
            
            %Låt oss kolla på flexibiliten
            
            Trefsh = TCflexCharge(HVACParam.Tref, flexParam, priceData(i));
            
            if Tshadow(i) > Trefsh + HVACParam.delta/2
                Qreg(i) = 0;
                Preg(i) = 0;
                
            elseif Tshadow(i) < Trefsh - HVACParam.delta/2
                Qregshadow(i) = COP*HVACParam.Psh;
                Pshadow(i) = HVACParam.Psh;
                
            else
                if i > 1
                    Qregshadow(i) = Qregshadow(i-1);
                    Pshadow(i) = Pshadow(i-1);
                else
                    Pshadow(i) = 0;
                end
                
            end            
            
            Tshadow(i+1) = Tshadow(i) + (1/(buildingParam.lambda*buildingParam.tau))*(Qregshadow(i) - Qheat(i))*simParam.dt;
            Trefshadow(i) = Trefsh;
            
        end
        
    end
    
end

output.Preg = Preg;
output.T = T;
output.Pregshadow = Pshadow;
output.Tshadow = Tshadow;
output.Trefshadow = Trefshadow;


end

