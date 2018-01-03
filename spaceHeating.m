function output = spaceHeating(buildingParam, HVACParam, controlParam, weatherData, Pint, Toutdata_lag, T0, degreemin0)

%Allt körs på dygnsbasis med minutupplösning

%INDATA
%buildingParam, HVACParam, controlParam, weatherData, Pint, Toutdata_lag, T0
 
%UTDATA
%Psh, Php, Pdh och Tin

%Antagande:
%1. Systemet körs enbart efter utomhustemperaturer och anväder integralmetoden
%för att styra on/off VP.
%2. Fjärrvärmen regleras kontinuerligt givet utomhustemp.

%Givet:

%Systemets dimensionering
% mono eller bivalent system. Dimensionerad värmepumpseffekt samt
% dimensionerad toppeffekt med sekundärtsystem

%Styrlogik; 
%1. när körs ingen värme (Tstar > Theat)
%2. när enbart värmepump (Tstar < Theat & Tstar > Thp)
%3. när värmepump kör max i kombination med sekundärt värmesystem (Tstar <
%Thp & Tstar > Tdut
%4. när både värmepump och sekundärt värmesystem kör max (Tstar > TDUT)

%Processen:
%1. Ta in info om systemkonfiguration (mono eller bivalent)
%2. Beräkna energibalansen för varje minut över dygnet;
%transmissionsförluster - internal gains från solstrålning +
%apparatur/människor
%2. stäm av de olika driftfallen:
%a. medeletttemp > Theat => ingen uppvärmning, Psh, Php, Pdh = 0, T får
%variera fritt
%om medeltemp < Theat har vi tre separata driftfall 
%b. Tstar > Thp (värmepumpen kan själv täcka hela värmebehovet). Psh =
%Php(Tstar). Här regleras värmepumpen enligt integralmetoden och beräknat
%värmebehov givet Tstar (linjärt)
%c. Tstar < Thp & Tstar > TDUT: VP kör max och fjärrvärme regleras efter
%Tstar, linjärt
%d. Tstar < TDUT, VP och fjärrvärme kör max. Psh = Php^ + Pdh ^2

[n, m] = size(weatherData); %minutupplöst data för ett dygn

%Variabler

Qloss = zeros(1,n);
Qheat = zeros(1,n);
Qsh = zeros(1,n); %Total uppvärmningseffekt VP + DH
Php = zeros(1,n); %Värmepumpseffekt
Pdh = zeros(1,n); %Fjärrvärmeeffekt 
T = zeros(1,n+1); %Inomhustemperatur
T(1) = T0; %starttemperatur
duty = zeros(1,n+1); %tillståndet för on/off VP
degreemin = zeros(1,n+1); %tillståndet för on/off VP
degreemin(1) = degreemin0;
hrs = 1; %  %keeps track of the which hour it is
j = 1; %auxiliary variable for getting the average outdoor temp Tstar

%% STEG 1: Beräkna energibeovet 

Qint = 0.5*Pint;
Qsun = buildingParam.shadow*buildingParam.A_window*weatherData(:,1); %kWh/min

if strcmp(controlParam.controller, 'outdoortemp')
%% STEG 3: Ta in information om systemkonfiguration

%strcmp(system_config, 'bivalent') %Vi antar ett bivalent system just nu

%% Steg 3: Beräkna medeltemperaturen från det tidgare dygnet

Tmean = mean(Toutdata_lag); %medeltemperaturen från dagen innan

%% STEG 4: Stäm av driftfall (rådande temperatur mot dimensionerande temperaturer) för tidpunkt t

% Här börjar looopen

%börja med de enklaste fallen, varmt; över balanstemp (Theat), kallt, under
%dimensionerande temp (TDUT)
%Uppdatera dessa värden

if Tmean < HVACParam.Theat %Annars returneras värden noll för uppvärmning
    
    for i = 1:n
        
        if j == 61 %check each new hour
            j = 1;
            hrs = hrs + 1;
        end
        
        %beräkna Tstar, den laggade utomhustemperaturen
        Tstar = mean(Toutdata_lag(hrs:(hrs+controlParam.Toutlag))); %Den laggade utomhustemperaturen; uppdateras varje minut    
      
        if Tstar >= HVACParam.Thp %Värmepumpen kör själv (klarar behovet självt)
            Pdh(i) = 0;
            [Php(i), duty(i+1), degreemin(i+1)] = heatpump_control(buildingParam, HVACParam, controlParam, Tstar, duty(i), degreemin(i));
            %Psh(i) = Pdh(i) + Php(i);
            %disp('Driftfall a')
        elseif Tstar < HVACParam.Thp && Tstar >= HVACParam.TDUT %VP kör max, och DH på dellast
            Php(i) = HVACParam.Php;
            Pdh(i) = controlParam.calibration*buildingParam.lambda*(HVACParam.Thp-Tstar);
            %disp('Driftfall b')
            
        elseif Tstar < HVACParam.TDUT %VP och DH kör fullast (max)
            Php(i) = HVACParam.Php; Pdh(i) = HVACParam.Ppeak;
            %Psh(i) = Php(i) + Pdh(i);Qsh(i) = COPhp*Php(i) + COPdh*Pdh(i);
            %disp('Driftfall c')
        end
         
        %Update space heating usage 
        Qsh(i) = HVACParam.COP*Php(i) + Pdh(i);
        
        j = j + 1;
        
    end
    
end

%% STEG 5: simulera termodynamik i byggnaden plus inomhustemperatur T(i+1)

for i = 1:n
    
    Qloss(i) = buildingParam.lambda*(T(i) - weatherData(i,2));
    Qheat(i) = Qloss(i) - (Qsun(i) + Qint(i)); 
    
    T(i+1) = T(i) + (1/(buildingParam.lambda*buildingParam.tau))*(Qsh(i) - Qheat(i))*(1/60);
    
    if T(i+1) > HVACParam.Tmax
        T(i+1) = T(i);
    end
end

%% ----------------------------------------------- %%

%% Här kan man simulera en enklare inomhustempertur-styrning
elseif strcmp(controlParam.controller, 'indoortemp')
    
    for i = 1:n
        
        if mean(weatherData(:,2)) < HVACParam.Thp
           %The secondary heating system kicks in when it is too cold
            Pheat_tot = buildingParam.lambda*(HVACParam.Tref - mean(weatherData(:,2)));
        else
            COP = HVACParam.COP; %The heat pump is running at an assumed COP
            Pheat_tot = HVACParam.COP*HVACParam.Php;
        end
        
        if T(i) > HVACParam.Tref + controlParam.deltaIndoor/2
            %Qreg(i) = 0;
            %Preg(i) = 0;
            Qsh(i) = 0;
            
        elseif T(i) < HVACParam.Tref - controlParam.deltaIndoor/2
            Qsh(i) = Pheat_tot; 
             
        else
            if i > 1
                Qsh(i) = Qsh(i-1);
  
            else
                Qsh(i) = 0;
            end
            
        end
        
        Qloss(i) = buildingParam.lambda*(T(i)-weatherData(:,2));
        Qheat(i) = Qloss(i) - (Qsun(i) + Pint(i)); %
        
        T(i+1) = T(i) + (1/(buildingParam.lambda*buildingParam.tau))*(Qsh(i) - Qheat(i))*(1/60);
        
        if T(i+1) > HVACParam.Tmax %här öppnar man fönster eller så drar elementdonen ner flödet automatiskt
            T(i+1) = T(i);
        end
        
    end
    
    
end

%% STEG 6: Spara undan variablerna

output.Php = Php;
output.Pdh = Pdh;
output.Qsh = Qsh;
output.T = T(1:end-1);
output.Qsun = Qsun;
output.Pint = Qint;
output.Qloss = Qloss;
output.degreemin = degreemin;


end