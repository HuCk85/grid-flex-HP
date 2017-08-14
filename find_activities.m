function A = find_activities( activities, M )
Atemp = zeros(size(M,1), size(M,2));
for i = 1:length(activities)
    Atemp = Atemp + (M == activities(i));
end
A = (Atemp > 0);