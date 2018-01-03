function P = cold_appliance_load(number_of_households, ints, POWER, on, off)

% Initialize P
P = zeros(number_of_households, ints);

% Loop through all households
for j = 1:number_of_households

    % Create initial cycle
    cycle_energy = on(ceil(rand(1)*length(on)));
    delta_t = off(ceil(rand(1)*length(off)));
    time_on  = round(cycle_energy/100*60);
    time_off = delta_t;
    cycle_time = time_on + time_off;
    P_cycle = [ones(1,time_on)*POWER zeros(1,time_off)];

    % Initial cycle interval
    cycle_ind = ceil(rand(1)*cycle_time);
    
    for i = 1:ints

        if cycle_ind <= cycle_time
            P(j,i) = P_cycle(1,cycle_ind);
        else
            cycle_ind = 1;
            cycle_energy = on(ceil(rand(1)*length(on)));
            delta_t = off(ceil(rand(1)*length(off)));
            time_on  = round(cycle_energy/100*60);
            time_off = delta_t;
            cycle_time = time_on + time_off;
            P_cycle = [ones(1,time_on)*POWER zeros(1,time_off)];
            P(j,i) = P_cycle(1,cycle_ind);
        end
        cycle_ind = cycle_ind + 1;

    end

end