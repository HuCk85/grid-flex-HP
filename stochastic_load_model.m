function [Papp, Pdhw, Wdhw, Pint, num_of_members, act, P, occup] = stochastic_load_model(S, A, L, daylight, dtype)

% STOCHASTIC_LOAD_MODEL (updated by Joakim Widén 170905)
%
% Generates stochastic load profiles with the models described in the
% papers:
%
%   J. Widén & E. Wäckelgård (2010), A high-resolution stochastic
% model of domestic activity pattern and electricity demand, Applied Energy
% 87: 1880-1892.
%
%   J. Widén et al. (2009), A combined Markov-chain and bottom-up approach
% to modelling of domestic lighting demand, Energy and Buildings 41: 1001-
% 1012.
%
% The function takes the following structs as inputs:
%
%   S: Simulation parameters
%   A: Appliance and hot water parameters
%   L: Lighting parameters
%
% These structs can be generated with default_parameters_houses.m and
% default_parameters_apartments.m.
%
% The following structs are given as outputs:
%
%   P: Power consumption [W] for each appliance type as matrices with
%      dimensions Nh x T, where Nh is the number of households and T is
%      the number of 1-min time steps.
%
%   W: DHW consumption [litres] for bathing and showering on the same
%      format as P above.
%
%   act: Activity matrix with dimensions Np x T, where Np is the total 
%        number of persons. The states are numbered 1-10, corresponding
%        to the activities:
%
%        1 away
%        2 sleeping
%        3 cooking
%        4 dishwashing
%        5 washing
%        6 drying
%        7 tv/vcr/dvd
%        8 computer
%        9 audio
%        10 bathing 
%        11 showering
%        12 other
%
%        (Note that this is one state more than in the paper 
%        Widén & Wäckelgård (2010) above.)
%
%   num_of_members: Number of members in each household, relating Nh and 
%                   Np.
%

%% Import data

% Transition matrices
%M_wd_det  = importdata([S.path 'M_det_wd.mat']);  % Weekday transition matrix
%M_wed_det = importdata([S.path 'M_det_wed.mat']); % Weekend day transition matrix
M_wd_ap   = importdata([S.path 'M_ap_wd.mat']);  % Weekday transition matrix
M_wed_ap  = importdata([S.path 'M_ap_wed.mat']); % Weekend day transition matrix

% Appliance duration data
fridge_on_load       = importdata([S.path 'fridge_on_load.mat']);
fridge_off_duration  = importdata([S.path 'fridge_off_duration.mat']); 
freezer_on_load      = importdata([S.path 'freezer_on_load.mat']);
freezer_off_duration = importdata([S.path 'freezer_off_duration.mat']);

% Daylight data
%L_year = importdata([S.path 'daylight_year.mat']);

L_year = daylight;

%% Adjust for daylight saving time

% % Time-keeping parameters
% days = [1 31 28 31 30 31 30 31 31 30 31 30 31];
% days_cum = cumsum(days);
% 
% % Shift daylight data if required
% if S.DST
%     [Y,MS,DS,h,m,s] = datevec(S.DSTStart);
%     [Y,ME,DE,h,m,s] = datevec(S.DSTEnd);
%     hour_shift_day_1 = days_cum(MS) + DS - 1;
%     hour_shift_day_2 = days_cum(ME) + DE - 1;
%     hour_shift_ind_1 = (hour_shift_day_1-1)*24*60 + 1;
%     hour_shift_ind_2 = hour_shift_day_2*24*60;
%     L_final = L_year;
%     L_final(hour_shift_ind_1 + 60 : hour_shift_ind_2 + 60) = L_year(hour_shift_ind_1:hour_shift_ind_2);
% else
%     L_final = L_year;
% end


%% Generate synthetic time-use data

% Transition matrices for the household type
if S.householdType == 1
    M_wd = M_wd_det;
    M_wed = M_wed_det;
else 
    M_wd = M_wd_ap;
    M_wed = M_wed_ap;
end

% Create vector with randomly generated number of members
num_of_members = zeros(1,S.numberOfHouseholds);
household_size_dist = [];
for i = 1:length(S.householdSizes)
    household_size_dist = [household_size_dist ones(1,S.householdSizes(i))*i];
end
for i = 1:S.numberOfHouseholds
    ind = ceil(rand(1)*length(household_size_dist));
    num_of_members(i) = household_size_dist(ind);
end

% Total number of persons in the synthetic data
number_of_persons = sum(num_of_members); 


days = 1:length(S.startDate:hours(24):S.endDate);
INTERVALS = length(dtype) * 1440;
% Subset of simulated days
% [Y,MS,DS,h,m,s] = datevec(S.startDate);
% [Y,ME,DE,h,m,s] = datevec(S.endDate);
% startDay = days_cum(MS) + DS - 1;
% endDay = days_cum(ME) + DE - 1;
% days = S.days(startDay:endDay);

% Subset of daylight data
% startMin = (startDay-1)*24*60 + 1;
% endMin = endDay*24*60;
% L_subset = L_final(startMin:endMin);
% 
% % Total number of 1-min intervals
% 
% 
% % Display status
% if S.householdType == 1
%     typeStr = 'detached houses';
% else
%     typeStr = 'apartments';
% end
%disp(' ')
%disp('Stochastic load model')
%disp('---------------------')
%disp(' ')
%disp(['Generating data for ' num2str(S.numberOfHouseholds) ' ' typeStr ' over ' num2str(length(days)) ' days (' num2str(DS) '/' num2str(MS) '-' num2str(DE) '/' num2str(ME) ')'])

% Generate synthetic activity data for the households
%disp(' ')
%disp(['Total number of randomly sampled persons: ' num2str(number_of_persons)])
act = synth_act_data_general(number_of_persons, M_wd, M_wed, dtype);

[n_act m_act] = size(act);
occup = zeros(1,m_act);

for i = 1:n_act
    for j = 1:m_act
        if act(i,j) ~= 1 %Alla aktiviter där de är hemma
            occup(j) = occup(j) + 1;
        end
    end
end


%% Calculate end-use-specific load curves

%disp(' ')
%disp('Calculating load profiles...')

% Randomly sample lighting parameter set
a = rand(1);
if a < L.fractions(1)
    lighting_param = L.param1;
elseif a < L.fractions(2)
    lighting_param = L.param2;
else
    lighting_param = L.param3;
end

% Cold appliances
fridge  = cold_appliance_load(S.numberOfHouseholds, INTERVALS, A.FRIDGE_POWER, fridge_on_load, fridge_off_duration);
freezer = cold_appliance_load(S.numberOfHouseholds, INTERVALS, A.FREEZER_POWER, freezer_on_load, freezer_off_duration);
P.cold_appliances = fridge + freezer; 

% Cooking
P.cooking = cooking_load(act, num_of_members, A.COOKING_POWER);

% Washing
WASHING_CYCLE_LOAD_PROFILE = [ones(1,A.WASHING_T1)*A.WASHING_P1 ones(1,A.WASHING_T2)*A.WASHING_P2];
P.washing = wet_and_dry_load(act, 5, num_of_members, WASHING_CYCLE_LOAD_PROFILE);

% Dishwashing
DISHWASHING_CYCLE_LOAD_PROFILE = [ones(1,A.DISHWASHING_T1)*A.DISHWASHING_P1 ones(1,A.DISHWASHING_T2)*A.DISHWASHING_P2 ones(1,A.DISHWASHING_T3)*A.DISHWASHING_P3];
P.dishwashing = wet_and_dry_load(act, 4, num_of_members, DISHWASHING_CYCLE_LOAD_PROFILE);

% TV
P.tv = entertainment_appliance_load(act, 7, num_of_members, A.TV_POWER_ACTIVE, A.TV_POWER_STANDBY, 'shared');

% Computer
P.computer = entertainment_appliance_load(act, 8, num_of_members, A.COMPUTER_POWER_ACTIVE, A.COMPUTER_POWER_STANDBY, 'unshared');

% Audio
P.audio = entertainment_appliance_load(act, 9, num_of_members, A.AUDIO_POWER_ACTIVE, A.AUDIO_POWER_STANDBY, 'unshared');

% Lighting
P.lighting = 0;%lighting_load(act, L_year, num_of_members, lighting_param);

% Additional
P.add = num_of_members' * ones(1,INTERVALS) * A.ADDITIONAL;

% Total load
Papp = (P.cold_appliances + P.cooking + P.washing + P.dishwashing + P.tv + P.computer + P.audio + P.lighting + P.add);
Papp = sum(Papp)/1000;

Pmet = 0.09; %energy loss due to metabolism
Pint = Papp + occup*Pmet; 

% % Showering
% SHOWERING_LOAD_PROFILE = A.SHOWER_FLOW_RATE * ones(1,A.SHOWER_TIME);
% showering = bathing_load(act, 11, num_of_members, SHOWERING_LOAD_PROFILE);
% 
% % Bathing
% BATHING_LOAD_PROFILE = A.BATH_FLOW_RATE * ones(1,A.BATH_TIME); % 16 litres per minute for 6 minutes acc to mail from Chris 170904!
% W.bathing = bathing_load(act, 10, num_of_members, BATHING_LOAD_PROFILE); % Starts load profile when bathing activity starts!
% 
% % Adjust showering
% ADJUSTMENT_PERIOD = A.SHOWER_ADJUSTMENT_TIME; % Minutes to adjust forth and back
% showeringAdjusted = showering;
% bathingIncidence = bathing_load(act, 10, num_of_members, 1);
% for j = 1:size(bathingIncidence,1) % loop through all households
%     for i = 1:size(bathingIncidence,2) % Loop through all time steps
%         if bathingIncidence(j,i) == 1
%             if i < ADJUSTMENT_PERIOD
%                 showeringAdjusted(j,1:i+ADJUSTMENT_PERIOD) = 0;
%             elseif size(bathingIncidence,2) - i < ADJUSTMENT_PERIOD
%                 showeringAdjusted(j,i-ADJUSTMENT_PERIOD:end) = 0;
%             else
%                 showeringAdjusted(j,i-ADJUSTMENT_PERIOD : i+ADJUSTMENT_PERIOD) = 0;
%             end
%         end
%     end
% end
% 
% W.showering = showeringAdjusted;
% 
% % Additional DHW load
% ADDITIONAL_LOAD_PROFILE = 4*ones(1,2);
% indAct = find(act > 2); % Find all indices in act where people are active
% indAdd = indAct( randperm(length(indAct), ceil(A.ADD_INCIDENCE*length(indAct))) ); % Randomly chosen indices for start of additional use
% addAct = zeros(size(act));
% addAct(indAdd) = 1; % Activity matrix with ones where additional DHW use starts
% W.additional = bathing_load(addAct, 1, num_of_members, ADDITIONAL_LOAD_PROFILE);

% Total DHW

% Showering
SHOWERING_LOAD_PROFILE = A.SHOWER_FLOW_RATE * ones(1,A.SHOWER_TIME);
showering = bathing_load(act, 11, num_of_members, SHOWERING_LOAD_PROFILE);

% Bathing
BATHING_LOAD_PROFILE = A.BATH_FLOW_RATE * ones(1,A.BATH_TIME); % 16 litres per minute for 6 minutes acc to mail from Chris 170904!
W.bathing = bathing_load(act, 10, num_of_members, BATHING_LOAD_PROFILE); % Starts load profile when bathing activity starts!

% Adjust showering
ADJUSTMENT_PERIOD = A.SHOWER_ADJUSTMENT_TIME; % Minutes to adjust forth and back
showeringAdjusted = showering;
bathingIncidence = bathing_load(act, 10, num_of_members, 1);
for j = 1:size(bathingIncidence,1) % loop through all households
    for i = 1:size(bathingIncidence,2) % Loop through all time steps
        if bathingIncidence(j,i) == 1
            if i < ADJUSTMENT_PERIOD
                showeringAdjusted(j,1:i+ADJUSTMENT_PERIOD) = 0;
            elseif size(bathingIncidence,2) - i < ADJUSTMENT_PERIOD
                showeringAdjusted(j,i-ADJUSTMENT_PERIOD:end) = 0;
            else
                showeringAdjusted(j,i-ADJUSTMENT_PERIOD : i+ADJUSTMENT_PERIOD) = 0;
            end
        end
    end
end
W.showering = showeringAdjusted;

% Additional DHW load
ADDITIONAL_LOAD_PROFILE = 4*ones(1,2);
indAct = find(act > 2); % Find all indices in act where people are active
indAdd = indAct( randperm(length(indAct), ceil(A.ADD_INCIDENCE*length(indAct))) ); % Randomly chosen indices for start of additional use
addAct = zeros(size(act));
addAct(indAdd) = 1; % Activity matrix with ones where additional DHW use starts
W.additional = bathing_load(addAct, 1, num_of_members, ADDITIONAL_LOAD_PROFILE);

% Total DHW
Wdhw = W.bathing + W.showering + W.additional;

DeltaT = 30; %temperaturskillnad mellan in och utvattnet från tanken
Cp_water = 1.17/1000; %[kWh/KgC4.18;% %the heating capacity value of water kJ/kgC (; %in kWh/kgC %;)
Pdhw = DeltaT * Cp_water * sum(Wdhw);


end
