function P = lighting_load(synth_act, L, num_of_members, param)

% Length of L must be equal to that of synth_act!

P_ideal = zeros(size(synth_act));
P = zeros(size(synth_act));

% Adjust for window transmittance...

L = L * 0.74;

% Parameters
L_lim = param(1); %limiting daylight level (measured in Lux)
P_away = param(2); %minimuim lightning demand when away
P_min = param(3); %minimum lightning demand when in active state (depends on L(k))
P_max = param(4); %maximum lightning demand when in active state (depends on L(k))
Q_adj = param(5); %probability of lightning level be adapted with deltaP according to L(k) 
P_incr = param(6); %increamental lightning increase
P_sleeping = param(7); %lightning demand when sleeping

for i = 1:size(synth_act,1) % Loop through persons
    
    % Set initial lighting levels
    P_current = 0;
    P_add = 0;
        
    for j = 1:size(synth_act,2) % Loop through time intervals
                
        % Set ideal lighting level
        if synth_act(i,j) == 1 % Person is away
            P_ideal(i,j) = P_away;
        elseif synth_act(i,j) == 2 % Person is sleeping
            P_ideal(i,j) = P_sleeping;
        else % Person is active
            if L(j) < L_lim
                P_ideal(i,j) = P_min + (1 - L(j)/L_lim) * (P_max - P_min);
            else
                P_ideal(i,j) = P_min;
            end
        end
           
        % Additional lighting
        %if synth_act(i,j) == 3 && rand(1) < 0.05
        %    P_add = 40;
        %else
        %    P_add = 0;
        %end
        
        % Adjustment of lighting level
        a = rand(1);
        if a <= Q_adj % Level is adjusted
            if (P_current - P_ideal(i,j)) > 0 && abs(P_current - P_incr - P_ideal(i,j)) < abs(P_current - P_ideal(i,j)) 
                P_current = P_current - P_incr;
            elseif (P_current - P_ideal(i,j)) < 0 && abs(P_current + P_incr - P_ideal(i,j)) < abs(P_current - P_ideal(i,j))
                P_current = P_current + P_incr;
            end
            %P_current = P_current; %+ P_add;
        end
        
        if synth_act(i,j) == 1 || synth_act(i,j) == 2
            P(i,j) = P_ideal(i,j);
            P_current = P_ideal(i,j);
        else
            P(i,j) = P_current;           
        end        
    end
end

P = persons_to_households(P, num_of_members);
