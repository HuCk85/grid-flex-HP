function P = wet_and_dry_load(act, ACTIVITY, num_of_members, CYCLE_LOAD_PROFILE)

act_hh = persons_to_households(act == ACTIVITY, num_of_members);

households = size(act_hh,1);
intervals  = size(act_hh,2);

P = zeros(households, intervals);

for i = 1:households
    
    is_on = false;
    act_performed = false;
    
    for j = 1:intervals
        
        if act_hh(i,j) > 0 % Activity is performed...
            if act_performed == false
                act_performed = true;
            end
        else % Activity is not performed...
            if act_performed == true % ...but was so in the previous step!
                cycle_ind = 1;
                is_on = true;
                act_performed = false;
            end
        end
        
        if is_on == true % Appliance is on
            if cycle_ind <= length(CYCLE_LOAD_PROFILE) == true % Cycle end not reached
                P(i,j) = CYCLE_LOAD_PROFILE(cycle_ind);
                cycle_ind = cycle_ind + 1;
            else % Cycle end reached
                is_on = false;
            end
        end
        
    end
end 
            
    
    
