function [ output ] = hourly_average(input, n)
%Converts minute values to hourly averages n = 24 for hourly average

output = zeros(1,n);
int = length(input)/n;

for i = 1:n
    output(i) = mean(input(int*(i-1)+1:int*i));
end

end

