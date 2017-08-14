function nr = householdSize(id)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

r = rand(1);

if id == 1
    
    X = [0 0.068+0.38, 0.25, 0.22, 0.058, 0.012, 0.012]; %sannolikhetsfördelning hushållsstorlek i småhus;
    n = length(X);
    y = 2:n;
    v = cumsum(X);
    
    for i = 1:n-1
        if (r >= v(i)) && (r < v(i+1))
            nr = y(i);
        end
        
        if r == 1
            nr = y(end);
        end
    end
    
end
    
end

