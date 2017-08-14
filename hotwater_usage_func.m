function [Quse, Vflow] = hotwater_usage_func(behavior)

%Varmvattenparametrar

Vbath = 140;  %140 + 140*var*randn(1,1); %Hot water demand for a bath in liters
Vshower = 10; %Hot water demand per shower minute
DeltaT = 30; %temperaturskillnad mellan in och utvattnet från tanken
Cp_water = 1.17/1000; %[kWh/KgC4.18;% %the heating capacity value of water kJ/kgC (; %in kWh/kgC %;)

[n,m] = size(behavior);
Vflow = zeros(n,m);

for i = 1:n
    for j = 1:m
        if behavior(i,j) == 3
            Vflow(i,j) = Vbath;
        end
        if behavior(i,j) == 4
            Vflow(i,j) = Vshower;
        end
        
    end
end

Vflow = sum(Vflow); %varmvattenanvändning över dygnet
Quse = Vflow*DeltaT*Cp_water; %Varmvattenförbrukningsvektorn i kWh/min

end
