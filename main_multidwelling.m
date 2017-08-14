clc, clear all, close all

%main script for simulating load profiles in multifamily houses

path = 'C:\Users\claessan\Dropbox\Projektlista\Samspel\Modeller\Flerbostadshusmodell\Data';

%% Parametervärden

simParam.dt = 1/60; % time resolution of simulations. 1/1 = hourly, 1/15 = quarterly, 1/60 = minutewise, etc. 
simParam.n = 24; %24 h = 1 dygn

%byggndsparametrar
buildingParam.NrApartments = 5;
buildingParam.NR_of_persons = 2; %en slumpfunktion i nästa steg, hur stort hushållet är baseras på 
buildingParam.Totpersons = buildingParam.NrApartments*buildingParam.NR_of_persons;
buildingParam.Afloor = 35; %Total uppvärmd yta per person i m2
[lambda, A_window] = thermoParameters( buildingParam.Afloor); %termodynamiska parametrar för byggnaden
buildingParam.lambda = lambda*buildingParam.Totpersons;
buildingParam.A_window = A_window*buildingParam.Totpersons;
buildingParam.tau = 24;

%hvac-systemsparametrar
HVACParam.Tref = 21; 
HVACParam.T0 = HVACParam.Tref;
HVACParam.COP = 3;
HVACParam.TDUT = -12.2; %Boverkets öppna data
HVACParam.Psh = buildingParam.lambda*(HVACParam.Tref-HVACParam.TDUT)/HVACParam.COP; %Värmepumpens dimensionering
HVACParam.controller = 'outdoortemp'; %[outdoortemp, indoortemp] Could either be outdoor temp controlled, or indoor temp controlled heating system
HVACParam.calibration = 0.80; % [%] the relation between heat output and outdoor temperature. Should not be one to one as some energy comes for free from internal gains,etc.
HVACParam.delta = 0.25; %[C] the temperature range of the indoor temp heuristic controller
HVACParam.Tbreak = 0; %[C] the break temperature where the electric heater kicks in
%[Php, Ppeak] = HVACdimensioning(HVACParam);

%DHW parametrar
DHWParam.Vtank = buildingParam.Totpersons*150;
DHWParam.Ptap = buildingParam.Totpersons*1;
DHWParam.Tref = 70;
DHWParam.T0 = DHWParam.Tref-10;
DHWParam.delta = 2;

% flexibilitetsparametrar
%hvac
flexParamHVAC.deltaT = 0; %[C] +- temperature deviation from the indoor temp reference
flexParamHVAC.priceMax = 400; %max(priceData);
flexParamHVAC.priceMean = 200;
%dhw
flexParamDHW.deltaT = 0; %[C] +- tank temperature deviation from the tank temp reference
flexParamDHW.priceMax = 400;
flexParamDHW.priceMean = 200;
%ev
flexParamEV.minSOC = 1; %minSOC allowed for electric vehicle
flexParamEV.priceMax = 400; %SEK/mwh
flexParamEV.priceMean = 200; %SEK/mwh

%% Ladda data

data = csvread(strcat(path, '\HerrljungaWeatherData2015.csv'));
dtype = csvread(strcat(path, '\weekdayweekends.csv'));
priceData = csvread(strcat(path, '\elprices2015.csv')); 
simData = [data(:,2)/1000 data(:,3) dtype(:,end) priceData]; %simuleringsdata

%% Simulations

N = 20;
total_base = zeros(N,simParam.n);
total_flex = zeros(N,simParam.n);

for j = 1:1
tic
ind = (24*(j-1)+1):(24*j);

weatherData.Tout = simData(ind,2); weatherData.Psun = simData(ind,1);
daytype = simData(ind(1),3); priceData = simData(ind,4); 
%interpolate data to fit simulation time resolution

weatherData.Psun = interp1(1:simParam.n, weatherData.Psun', linspace(1,simParam.n,simParam.n/simParam.dt));
weatherData.Tout = interp1(1:simParam.n, weatherData.Tout', linspace(1,simParam.n,simParam.n/simParam.dt));
priceData = interp1(1:simParam.n, priceData', linspace(1,simParam.n,simParam.n/simParam.dt));
    
%appliances
behaviorData.app_data = behavior_func(buildingParam.Totpersons , daytype, path, 'appliances');
outputApp = appliance_usage_func(behaviorData.app_data, buildingParam.Totpersons, weatherData.Psun, path);

%DHW
behaviorData.tap_data = behavior_func(buildingParam.Totpersons, daytype, path,'tap');
DHWconsData = hotwater_usage_func(behaviorData.tap_data);
outputDHW = DHW_control(simParam, DHWParam, flexParamDHW, DHWconsData, priceData);

%space heating
outputSH = SH_control(simParam, buildingParam, HVACParam, flexParamHVAC, weatherData, priceData, outputApp);

%total = outputApp.Preg + outputDHW

%total_base(j,:) = hourly_average(sum([outputApp.Preg;outputDHW.Preg]),24);
%;outputEV.Preg ;outputSH.Preg]
%total_flex(j,:) = hourly_average(sum([outputApp.Preg;outputDHW.Pregshadow;outputSH.Pregshadow]),24);
toc
end

%% 
subplot(2,2,1)
plot(outputApp.Preg);
subplot(2,2,2)
plot(outputDHW.Preg )
subplot(2,2,3)
plot(outputApp.Preg + outputDHW.Preg)
subplot(2,2,4)
plot(outputApp.Preg + outputDHW.Preg + outputSH.Preg )
% 
% subplot(1,2,1)
% plot(outputSH.Preg)
% subplot(1,2,2)
% %yyaxis left
% plot(outputSH.T) 
% %yyaxis right
%plot(DHWconsData)