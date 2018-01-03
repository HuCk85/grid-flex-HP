function [S,A,L] = default_parameters_apartments(simParam, buildingParam, path)

% Default parameters for apartments

% Simulation settings (S)
S.path = path;
S.numberOfHouseholds = buildingParam.NrApartments;
S.DST = true;
S.DSTStart = [num2str(year(simParam.Tstart)), '-03-29'];
S.DSTEnd = [num2str(year(simParam.Tstart)), '-10-25'];
S.startDate = simParam.Tstart;
S.endDate = simParam.Tend;
S.days = weekday(simParam.Tstart:hours(24):simParam.Tend);
S.days(find(S.days==1 | S.days==2 | S.days == 3 | S.days == 4 | S.days == 5)) = 1;
S.days(find(S.days==6 | S.days==7)) = 2;

S.householdSizes = [26 27 4 6 1 2];
S.householdType = 2; %detached houses

% Appliance parameters (A)
A.FRIDGE_POWER = 50;
A.FREEZER_POWER = 80;
A.COOKING_POWER = 1500;
A.WASHING_P1 = 1800;
A.WASHING_T1 = 20;
A.WASHING_P2 = 150;
A.WASHING_T2 = 90;
A.DISHWASHING_P1 = 1944;
A.DISHWASHING_T1 = 17;
A.DISHWASHING_P2 = 120;
A.DISHWASHING_T2 = 40;
A.DISHWASHING_P3 = 1920;
A.DISHWASHING_T3 = 16;
A.TV_POWER_ACTIVE = 100;
A.TV_POWER_STANDBY = 20;
A.COMPUTER_POWER_ACTIVE = 100;
A.COMPUTER_POWER_STANDBY = 40;
A.AUDIO_POWER_ACTIVE = 30;
A.AUDIO_POWER_STANDBY = 6;
A.ADDITIONAL = 11;

% DHW parameters
A.BATH_FLOW_RATE = 16; % Litres per minute
A.SHOWER_FLOW_RATE = 10; % Litres per minute
A.ADD_FLOW_RATE = 4; % Litres per minute
A.BATH_TIME = 6; % Minutes
A.SHOWER_TIME = 5; % Minutes
A.ADDITIONAL_TIME = 2; % Minutes
A.ADD_INCIDENCE = 0.01; % Probability for additional tap
A.SHOWER_ADJUSTMENT_TIME = 360; % Time (mins) before and after bath that showering is set to zero

% Lighting parameters (L)
L.param1 = [1000 40 40 120 0.1 40 40];
L.param2 = [1000 0 40 120 0.1 40 0];
L.param3 = [1000 0 40 80 0.1 40 0];
L.fractions = [0.3 0.3 0.4];