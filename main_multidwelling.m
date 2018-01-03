clc, clear all, close all

%% PATHS TO DATA

path = './Data/';

%% SIMULATION OPTIONS

%Simulation related parameters, e.g. time resolution, etc.
simParam.dt = 1/60; % time resolution of simulations. 1/1 = hourly, 1/15 = quarterly, 1/60 = minutewise, etc.
simParam.n = 24; %24 h = 1 dygn

% The start and end times of the simulations
simParam.Tstart = datetime('2016-09-30 00:00:00');
simParam.Tend = datetime('2017-09-18 00:00:00' );

%The simulation time steps 
t = simParam.Tstart:hours(1):(simParam.Tend); t = t(1:end-1);

%% LOADING INPUT DATA

%Load the weather data (solar irradiance and outdoor temperature time series)
load '.\Data\weatherData.mat'

%DAYTYPE (0 = weekday, 1 = weekend)
weekd = weekday(t);
dtype = zeros(length(weekd),1);
dtype(find(weekd == 6 | weekd == 7)) = 1;
dtype_daily = dtype(1:24:end);

%Put all data in a matrix
simData = [weatherData(:,2)/1000 weatherData(:,1) dtype]; %simulation data dtype(:,end), solar radiation, outdoor temp, and day type

%Load appliance and DHW use from earlier simulaton if you think it is too
%slow. If so, comment row X and Y.
load './Data/use case 1/appData.mat'

%% SET THE MODEL PARAMETERS

%----------------- BUILDING PARAMETERS (thermodynamics and end-users) -----------------%

buildingParam.NrApartments = 156; %the number of apartments in the building
%buildingParam.NR_of_persons = 2; %en slumpfunktion i nästa steg, hur stort hushållet är baseras på

%Outputs parameters for appliance and DHW use in apartments
%[S,A,L] = default_parameters_apartments(simParam, buildingParam, path);

%Generate the minute wise appliance use and DHW use for the time period.
%the internal gain and number of members are also output
%[Papp, Pdhw, Wdhw, Pint, num_of_members] = stochastic_load_model(S, A, L, simData(:,1), dtype_daily);

buildingParam.Totpersons = sum(num_of_members); %the total number of people in the building
buildingParam.Afloor = 30; %Total heated space per person in m2
building_age = 'medium'; %Possible values; old, medium, new
[lambda, A_window] = thermoParameters( buildingParam.Afloor, building_age); %The thermodynamic properties of the building per capita
buildingParam.lambda = lambda*buildingParam.Totpersons; %The transmisson loss for the whole building
buildingParam.A_window = A_window*buildingParam.Totpersons; %The total window area of the building
buildingParam.shadow = 0.15; %the shadowing factor for the windows
buildingParam.tau = 100; %The time constant of the building in hours

%----------------- HVAC SYSTEM PARAMETERS (dimensioning) ------------------------------%

HVACParam.Tref = 21; %[C] The reference indoor temp
HVACParam.T0 = HVACParam.Tref; %[C] the inital temperature in the simulation (flytta eventuellt)
HVACParam.COP = 2.5; %The seaonal COP factor of the heat pump. Depends on heat source, e.g ground, air, etc.
HVACParam.TDUT = -16.0; %[C] The winter dimensioning temperature of the heating system. Depends on the geographic area
HVACParam.Theat = 15; %[C] The balance outdoor temperture where no heating is required

HVACParam.Thp = 7; %the outdoor temperature threshold where the base heating unit can cover the whole heating demand
HVACParam.Tmax = 25; %the maximum possible indoor temperature, before people open windows etc.
HVACParam.supply = 'bivalent'; %the config of heating system, possible values: mono (only heat pump), mono-energetic (HP + electric heater), bivalent (HP + district heating)
[HVACParam.Php, HVACParam.Ppeak] = heatingDimensioning(HVACParam, buildingParam); %Dimensions the heating capacity based on building parameters, TDUT and supply concept

%----------------- CONTROL PARAMETERS OF THE SPACE HEATING  ------------------------------%

controlParam.controller = 'outdoortemp'; %[outdoortemp, indoortemp] Could either be outdoor temp controlled, or indoor temp controlled heating system
controlParam.deltaOutdoor = 0.5; %[C] the temperature span for the intregral control method, large span = slower controller (i.e. fewer cycle)
controlParam.Toutlag = 8; % [hrs] the number of hours in the window of the moving average of the outdoor temperature
controlParam.calibration = 0.7; % [%] the relation between heat output and outdoor temperature. Should not be one to one as some energy comes for free from internal gains,etc.
degreemin0 = 0; %the intial value of the integral control
controlParam.probonState = 0.5; %the probability that the heat pump is in an on state at the start of the simulations
controlParam.deltaIndoor = 1; %[C] the dead band of the indoor temperature control

%----------------- DHW PARAMETERS  ------------------------------%

DHWParam.COP = HVACParam.COP;
DHWParam.Vtank = buildingParam.Totpersons*150; %[liters] The hot water tank in liters for whole building
DHWParam.Ptap = (buildingParam.Totpersons*2)/DHWParam.COP; %[kW] The hot water tank in liters for whole building
DHWParam.Tref = 70; %[C] the reference temperature of the hot water tank
DHWParam.T0 = DHWParam.Tref; %the inital temperature of the hot water tank
DHWParam.delta = 2; %The temperature deviation of the heuristic controller

%% OUTPUT DATA THAT WILL BE SAVED. EVERYTHING IS HOURLY

N = length(t)/24; %the number of days in the simulations

%appliance related data
Papp_save = zeros(N,24);
Pint_save = zeros(N,24);

%dhw related data
Pdhw_save = zeros(N,24);
Tdhw_save = zeros(N,24);

%space heating related data
Pbase_save = zeros(N,24);
Ppeak_save = zeros(N,24);
Ptotal_save = zeros(N,24);
TSH_save = zeros(N,24);

%% PERFORM SIMULATIONS FOR SPACE HEATING

for j = 1:N
    
    tic
    ind = (24*(j-1)+1):(24*j);
    minute_ind = (60*(ind(1)-1)+1):(ind(end)*60); %minute wise 
    
    if j > 1
        ind2 = ((ind(1))-controlParam.Toutlag):(ind(end));
    else
        ind2 = [repmat(ind(1),1,controlParam.Toutlag) ind];
    end
    
    %Interpolate the weather data at a minute time resolution

    Toutdata_lag = simData(ind2,2);
    %interpolate data to fit simulation time resolution
    Psun = interp1(1:simParam.n, simData(ind,1)', linspace(1,simParam.n,simParam.n/simParam.dt));
    Tout = interp1(1:simParam.n, simData(ind,2)', linspace(1,simParam.n,simParam.n/simParam.dt));
    weather = [Psun' Tout'];
    
    %Space heating
    
    %The inital indoor temperature. If it's the first iteration, it will be
    %set to the reference, otherwise it is set to the last value from the
    %previous iteration
    
    if j > 1
        T0 = outputSH.T(end);
        
    else
        T0 = HVACParam.Tref;
    end
    
    outputSH = spaceHeating(buildingParam, HVACParam, controlParam, weather, Pint(minute_ind), Toutdata_lag, T0, degreemin0);
    degreemin0 = outputSH.degreemin(end);
    
    %Save the data
    
    %appliance related data
    Papp_save(j,:) = hourly_average(Papp(minute_ind),24);
    Pint_save(j,:) = hourly_average(Pint(minute_ind),24);
    
    %dhw related data
    Pdhw_save(j,:) = hourly_average(Pdhw(minute_ind),24);
    %Tdhw_save = zeros(N,1440);
    
    %space heating related data
    Pbase_save(j,:) = hourly_average(outputSH.Php,24);
    Ppeak_save(j,:) = hourly_average(outputSH.Pdh,24);
    
    TSH_save(j,:) = hourly_average(outputSH.T,24);
    
    %Total load of building
    Ptotal_save(j,:) = Pbase_save(j,:) + Ppeak_save(j,:) + Papp_save(j,:) + Pdhw_save(j,:);
    
    toc
end

%% VISUALIZATION AND ANALYSIS

% CODE HERE

subplot(2,1,1)
plot(Ptotal_save'), title('Daily total load profile for building'), xlabel('Time [hrs]'), ylabel('Load [kW]')

subplot(2,1,2)
plot(TSH_save'), title('Daily indoor temp for building'), xlabel('Time [hrs]'), ylabel('temp [C]')
