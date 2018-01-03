function synth_act = synth_act_data_general(NUM_OF_PERSONS, M_wd, M_wed, dtype)

NUM_OF_DAYS = length(dtype);%length(days);
NUM_OF_INTERVALS = NUM_OF_DAYS*1440;

% Initialize synthetic activity matrix
synth_act = zeros(NUM_OF_PERSONS,NUM_OF_INTERVALS);

%tic

% Loop through all persons
for j = 1:NUM_OF_PERSONS
    
 disp(j)
    
    % Determine initial state of person
    if rand(1) < 0.1
        current_state = 1;
    else
        current_state = 2;
    end
    
    % Set first activity interval
    synth_act(j, 1) = current_state;
    
    % Loop through all days for the current person
    for k = 1:NUM_OF_DAYS
        
        % Choose matrix type (1 = weekday, else weekend day)
        if dtype(k) == 0;
            M_exp = M_wd;
        else 
            M_exp = M_wed;
        end
        
        % Loop through all intervals of the current day
        for l = 1:1440
            
            % Interval index
            i = (k-1)*1440 + l;
            
            r = rand(1);
            ind = rem(i,1440);
            if ind == 0
                ind = 1440;
            end
            for m = 1:size(M_exp,1)
                p(m) = M_exp(current_state, m, ind);
            end
            for m = 1:size(M_exp,1)
                pcum = [0 cumsum(p)];    
                if r > pcum(m) && r <= pcum(m+1)
                    synth_act(j, i) = m;
                    current_state = m;
                end
            end
        end
    end
end

