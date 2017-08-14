function P = cold_appliance_load(POWER, on, off)

% Initialize P
P = zeros(1, 1440); %the power consumed by the freezers of
%the different households

% Loop through all households

% Create initial cycle
cycle_energy = on(ceil(rand(1)*length(on)));
delta_t = off(ceil(rand(1)*length(off)));
time_on  = round(cycle_energy/100*60);
time_off = delta_t;
cycle_time = time_on + time_off;
P_cycle = [ones(1,time_on)*POWER zeros(1,time_off)];

% Initial cycle interval
cycle_ind = ceil(rand(1)*cycle_time);

for i = 1:1440 %go through the time period
    
    if cycle_ind <= cycle_time
        P(i) = P_cycle(1,cycle_ind);
    else
        cycle_ind = 1;
        %begin new duty cycle
        cycle_energy = on(ceil(rand(1)*length(on)));
        delta_t = off(ceil(rand(1)*length(off)));
        time_on  = round(cycle_energy/100*60);
        time_off = delta_t;
        cycle_time = time_on + time_off;
        P_cycle = [ones(1,time_on)*POWER zeros(1,time_off)];
        P(i) = P_cycle(1,cycle_ind);
    end
    cycle_ind = cycle_ind + 1;
    
end
end

