function output = spaceHeating(buildingParam, HVACParam, controlParam, weatherData, Pint, Toutdata_lag, T0, degreemin0)

%Allt k�rs p� dygnsbasis med minutuppl�sning

%INDATA
%buildingParam, HVACParam, controlParam, weatherData, Pint, Toutdata_lag, T0
 
%UTDATA
%Psh, Php, Pdh och Tin

%Antagande:
%1. Systemet k�rs enbart efter utomhustemperaturer och anv�der integralmetoden
%f�r att styra on/off VP.
%2. Fj�rrv�rmen regleras kontinuerligt givet utomhustemp.

%Givet:

%Systemets dimensionering
% mono eller bivalent system. Dimensionerad v�rmepumpseffekt samt
% dimensionerad toppeffekt med sekund�rtsystem

%Styrlogik; 
%1. n�r k�rs ingen v�rme (Tstar > Theat)
%2. n�r enbart v�rmepump (Tstar < Theat & Tstar > Thp)
%3. n�r v�rmepump k�r max i kombination med sekund�rt v�rmesystem (Tstar <
%Thp & Tstar > Tdut
%4. n�r b�de v�rmepump och sekund�rt v�rmesystem k�r max (Tstar > TDUT)

%Processen:
%1. Ta in info om systemkonfiguration (mono eller bivalent)
%2. Ber�kna energibalansen f�r varje minut �ver dygnet;
%transmissionsf�rluster - internal gains fr�n solstr�lning +
%apparatur/m�nniskor
%2. st�m av de olika driftfallen:
%a. medeletttemp > Theat => ingen uppv�rmning, Psh, Php, Pdh = 0, T f�r
%variera fritt
%om medeltemp < Theat har vi tre separata driftfall 
%b. Tstar > Thp (v�rmepumpen kan sj�lv t�cka hela v�rmebehovet). Psh =
%Php(Tstar). H�r regleras v�rmepumpen enligt integralmetoden och ber�knat
%v�rmebehov givet Tstar (linj�rt)
%c. Tstar < Thp & Tstar > TDUT: VP k�r max och fj�rrv�rme regleras efter
%Tstar, linj�rt
%d. Tstar < TDUT, VP och fj�rrv�rme k�r max. Psh = Php^ + Pdh ^2

[n, m] = size(weatherData); %minutuppl�st data f�r ett dygn

%Variabler

Qloss = zeros(1,n);
Qheat = zeros(1,n);
Qsh = zeros(1,n); %Total uppv�rmningseffekt VP + DH
Php = zeros(1,n); %V�rmepumpseffekt
Pdh = zeros(1,n); %Fj�rrv�rmeeffekt 
T = zeros(1,n+1); %Inomhustemperatur
T(1) = T0; %starttemperatur
duty = zeros(1,n+1); %tillst�ndet f�r on/off VP
degreemin = zeros(1,n+1); %tillst�ndet f�r on/off VP
degreemin(1) = degreemin0;
hrs = 1; %  %keeps track of the which hour it is
j = 1; %auxiliary variable for getting the average outdoor temp Tstar

%% STEG 1: Ber�kna energibeovet 

Qint = 0.5*Pint;
Qsun = buildingParam.shadow*buildingParam.A_window*weatherData(:,1); %kWh/min

if strcmp(controlParam.controller, 'outdoortemp')
%% STEG 3: Ta in information om systemkonfiguration

%strcmp(system_config, 'bivalent') %Vi antar ett bivalent system just nu

%% Steg 3: Ber�kna medeltemperaturen fr�n det tidgare dygnet

Tmean = mean(Toutdata_lag); %medeltemperaturen fr�n dagen innan

%% STEG 4: St�m av driftfall (r�dande temperatur mot dimensionerande temperaturer) f�r tidpunkt t

% H�r b�rjar looopen

%b�rja med de enklaste fallen, varmt; �ver balanstemp (Theat), kallt, under
%dimensionerande temp (TDUT)
%Uppdatera dessa v�rden

if Tmean < HVACParam.Theat %Annars returneras v�rden noll f�r uppv�rmning
    
    for i = 1:n
        
        if j == 61 %check each new hour
            j = 1;
            hrs = hrs + 1;
        end
        
        %ber�kna Tstar, den laggade utomhustemperaturen
        Tstar = mean(Toutdata_lag(hrs:(hrs+controlParam.Toutlag))); %Den laggade utomhustemperaturen; uppdateras varje minut    
      
        if Tstar >= HVACParam.Thp %V�rmepumpen k�r sj�lv (klarar behovet sj�lvt)
            Pdh(i) = 0;
            [Php(i), duty(i+1), degreemin(i+1)] = heatpump_control(buildingParam, HVACParam, controlParam, Tstar, duty(i), degreemin(i));
            %Psh(i) = Pdh(i) + Php(i);
            %disp('Driftfall a')
        elseif Tstar < HVACParam.Thp && Tstar >= HVACParam.TDUT %VP k�r max, och DH p� dellast
            Php(i) = HVACParam.Php;
            Pdh(i) = controlParam.calibration*buildingParam.lambda*(HVACParam.Thp-Tstar);
            %disp('Driftfall b')
            
        elseif Tstar < HVACParam.TDUT %VP och DH k�r fullast (max)
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

%% H�r kan man simulera en enklare inomhustempertur-styrning
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
        
        if T(i+1) > HVACParam.Tmax %h�r �ppnar man f�nster eller s� drar elementdonen ner fl�det automatiskt
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