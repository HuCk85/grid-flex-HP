function [lambda, A_window] = thermoParameters( A_floor )

% This function outputs the thermodynamical properties of the building and apartment,
% i.e, the isolation lambda,  time constant and window constant for solar
% radiation

%Fördelning byggnadstyper i aggregering, ska vi ha ett antal arketyper

%Befintligt flerbostadshus från 1970 med fjärrvärme, klimatzon III (FbA1970FjvIII)

%Heat loss through conduction
hight = 2.5; %Takhöjd
%A_floor = 130; %Total uppvärmd yta per person
U_floor = 0.379; %U-värde för platta/mark
U_roof = 0.16; %U-värde för tak
A_roof = A_floor; %Total takarea
A_window = 0.15*A_floor; %Total fönsterarea
U_window = 1.9; %U-värde för fönster (tvåstegsfönster
U_door = 2; %U-värde för dörrar
A_door = 0.12; %Total dörrarea
A_wall = 4*hight*sqrt(A_floor) - A_window - A_door; %Total väggarea
U_wall = 0.249; %U-värde för fasad

lambda_trans =  (U_window*A_window+U_door*A_door+U_wall*A_wall+U_roof*A_roof+U_floor*A_floor)/1000;

%Heat loss through ventilation
Cpair = 0.28/1000; % Luftens specika värmekoefficeint kWh/m3C
vent = 0.34/1000; %Ventilation rate in [m3/m2s]
V = A_floor*hight; %Total inre volym
N = 3600*(vent*A_floor)/V; %antalet luftomsättningar per timma

alpha_recycle = 0.0; %Värmeåtervinnings
lambda_vent = Cpair*N*V*(1-alpha_recycle); %värmeförlust genom ventilation

lambda = lambda_trans + lambda_vent;

%solar_absorb = 0.3*A_window ;

end

