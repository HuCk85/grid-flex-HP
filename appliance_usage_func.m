function output = appliance_usage_func(behavior_data, num_of_members, L, path)

const.FRIDGE_POWER = 50/1000; const.FREEZER_POWER = 80/1000; const.COOKING_POWER = 1500/1000;
const.WASHING_P1 = 1800/1000;  const.WASHING_T1 = 20; const.WASHING_P2 = 150/1000;
const.WASHING_T2 = 90; const.DISHWASHING_P1 = 1944/1000; const.DISHWASHING_T1 = 17;
const.DISHWASHING_P2 = 120/1000; const.DISHWASHING_T2 = 40; const.DISHWASHING_P3 = 1920/1000;
const.DISHWASHING_T3 = 16; const.TV_POWER_ACTIVE = 100/1000; const.TV_POWER_STANDBY = 20/1000;
const.COMPUTER_POWER_ACTIVE = 100/1000; const.COMPUTER_POWER_STANDBY = 40/1000; const.AUDIO_POWER_ACTIVE = 30/1000; const.AUDIO_POWER_STANDBY = 6/1000; 
const.add_det = 53.2/1000; const.lighting_param = [1000 40/1000 80/1000 200/1000 0.1 40/1000 40/1000]; %L_lim, P_away, P_min, P_max, Qadj, dP, P_sleep

file = 'fridge_on_load.mat';
fname = fullfile(path,file);
load(fname);
file = 'fridge_off_duration.mat';
fname = fullfile(path,file);
load(fname);
file = 'freezer_on_load.mat';
fname = fullfile(path,file);
load(fname);
file = 'freezer_off_duration.mat';
fname = fullfile(path,file);
load(fname);

[n,m] = size(behavior_data);
occup = zeros(1,m);
EVusage = zeros(1,m);

%Get the occupancy in an array
for i = 1:n
    for j = 1:m
        if behavior_data(i,j) ~= 1 %Alla aktiviter där de är hemma
            EVusage(j) = 1;
            occup(j) = occup(j) + 1;
        end
    end
end

%Fride and freezer
fridge  = cold_appliance_load(const.FRIDGE_POWER, fridge_on_load, fridge_off_duration);
freezer = cold_appliance_load(const.FREEZER_POWER, freezer_on_load, freezer_off_duration);
cold_appliances = fridge + freezer; 

%Cooking
cooking = cooking_load(behavior_data, num_of_members, const.COOKING_POWER);

% Dishwashing
DISHWASHING_CYCLE_LOAD_PROFILE = [ones(1,const.DISHWASHING_T1)*const.DISHWASHING_P1 ones(1,const.DISHWASHING_T2)*const.DISHWASHING_P2 ones(1,const.DISHWASHING_T3)*const.DISHWASHING_P3];
dishwashing = wet_and_dry_load(behavior_data, 4, num_of_members, DISHWASHING_CYCLE_LOAD_PROFILE);

% Washing
WASHING_CYCLE_LOAD_PROFILE = [ones(1,const.WASHING_T1)*const.WASHING_P1 ones(1,const.WASHING_T2)*const.WASHING_P2];
washing = wet_and_dry_load(behavior_data, 5, num_of_members, WASHING_CYCLE_LOAD_PROFILE);

%TV
tv = entertainment_appliance_load(behavior_data, 7, num_of_members, const.TV_POWER_ACTIVE, const.TV_POWER_STANDBY, 'shared');
 
% Computer
computer = entertainment_appliance_load(behavior_data, 8, num_of_members, const.COMPUTER_POWER_ACTIVE, const.COMPUTER_POWER_STANDBY, 'unshared');

% Audio
audio = entertainment_appliance_load(behavior_data, 9, num_of_members, const.AUDIO_POWER_ACTIVE, const.AUDIO_POWER_STANDBY, 'unshared');

% Lighting 
lighting = lighting_load(behavior_data, L, num_of_members, const.lighting_param);

total = cold_appliances+ cooking + washing + dishwashing + tv + computer + audio + lighting + const.add_det;

Pmet = 0.09; %Förlustvärme från ockupanter i kW/person
Pint = cold_appliances + tv + computer + audio + lighting + const.add_det + Pmet*occup; %just some of heat losses of appliances are absorbed by the environmnet

%hourly_average(total, 24) + Pmet*hourly_average(occup, 24);

%total = cold_appliances + cooking + washing + dishwashing + tv + computer + audio + lighting + add;

output.Preg = total;
output.Pint = Pint;
output.EVusage = EVusage;

end

