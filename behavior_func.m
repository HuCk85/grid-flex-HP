function synth_act = behavior_func(NUM_OF_PERSONS, daytype, path, type)

%function synth_act = synth_act_data_general(NUM_OF_PERSONS, days, M_wd, M_wed)

%NUM_OF_DAYS = length(days);
NUM_OF_INTERVALS = 1440; %minute resolution

% Initialize synthetic activity matrix
synth_act = zeros(NUM_OF_PERSONS, NUM_OF_INTERVALS);

if daytype == 0
    if strcmp(type,'appliances')
        file = 'M_ap_wd.mat';
    end
    if strcmp(type,'tap')
        file = 'M_ap_tap_wd.mat'; %heter M
    end
    fname=fullfile(path,file);
    load(fname);
    M_exp = M_ap_wd;
else
    if strcmp(type,'appliances')
        file = 'M_ap_wed.mat'; %ok
    end
    if strcmp(type,'tap')
        file = 'M_ap_tap_wed.mat'; %heter M
    end
    fname=fullfile(path,file);
    load(fname);
    M_exp = M_ap_wed;
end

if strcmp(type,'appliances')
    v = 10; %size of markov matrices apps
else
    v = 5; %size of markov matrices dhw
end

% Loop through all persons
for j = 1:NUM_OF_PERSONS
    
    % Determine initial state of person
    if rand(1) < 0.1 %varför 10% sannolikhet?
        current_state = 1; %absent
    else
        current_state = 2; %active
    end
    
    % Set first activity interval
    synth_act(j, 1) = current_state;
    
    % Loop through all days for the current person
    
    % Loop through all intervals of the current day
    for i = 1:1440 %all minutes of the 24 hours
        
        r = rand(1); %slumpa ut värden hela tiden
        
        for m = 1:v %statesen
            p(m) = M_exp(current_state, m, i);
        end
        
        for m = 1:v
            pcum = [0 cumsum(p)];
            if r > pcum(m) && r <= pcum(m+1)
                synth_act(j, i) = m;
                current_state = m;
            end
            
        end
        
    end
    
end

end
