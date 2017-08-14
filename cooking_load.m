function P = cooking_load(act, num_of_members, POWER)

% Define activity
COOKING = 3; %state nr 3

% Find occurrence of cooking...
persons_cooking = find_activities(COOKING, act);
persons_cooking_hh = persons_to_households(persons_cooking, num_of_members);

% Calculate energy use
P = (persons_cooking_hh > 0)*POWER;
       