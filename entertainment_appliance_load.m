function P = entertainment_appliance_load(act, ACTIVITY, num_of_members, POWER_ACTIVE, POWER_STANDBY, co_use)

act_hh = persons_to_households(act == ACTIVITY, num_of_members);

% Take sharing into account
if strcmp(co_use, 'shared')
    act_hh = act_hh > 0;
end

% Standby power as default
P = ones(size(act_hh))*POWER_STANDBY;

% Active use
P = P + act_hh * POWER_ACTIVE;

