function [ output ] = hourly_sum( input, n )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

output = zeros(1,n);
int = length(input)/n;

for i = 1:n
    output(i) = sum(input(int*(i-1)+1:int*i));
end


end

