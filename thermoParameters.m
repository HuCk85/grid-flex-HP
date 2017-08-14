function [lambda, A_window] = thermoParameters( A_floor )

% This function outputs the thermodynamical properties of the building and apartment,
% i.e, the isolation lambda,  time constant and window constant for solar
% radiation

%F�rdelning byggnadstyper i aggregering, ska vi ha ett antal arketyper

%Befintligt flerbostadshus fr�n 1970 med fj�rrv�rme, klimatzon III (FbA1970FjvIII)

%Heat loss through conduction
hight = 2.5; %Takh�jd
%A_floor = 130; %Total uppv�rmd yta per person
U_floor = 0.379; %U-v�rde f�r platta/mark
U_roof = 0.16; %U-v�rde f�r tak
A_roof = A_floor; %Total takarea
A_window = 0.15*A_floor; %Total f�nsterarea
U_window = 1.9; %U-v�rde f�r f�nster (tv�stegsf�nster
U_door = 2; %U-v�rde f�r d�rrar
A_door = 0.12; %Total d�rrarea
A_wall = 4*hight*sqrt(A_floor) - A_window - A_door; %Total v�ggarea
U_wall = 0.249; %U-v�rde f�r fasad

lambda_trans =  (U_window*A_window+U_door*A_door+U_wall*A_wall+U_roof*A_roof+U_floor*A_floor)/1000;

%Heat loss through ventilation
Cpair = 0.28/1000; % Luftens specika v�rmekoefficeint kWh/m3C
vent = 0.34/1000; %Ventilation rate in [m3/m2s]
V = A_floor*hight; %Total inre volym
N = 3600*(vent*A_floor)/V; %antalet luftoms�ttningar per timma

alpha_recycle = 0.0; %V�rme�tervinnings
lambda_vent = Cpair*N*V*(1-alpha_recycle); %v�rmef�rlust genom ventilation

lambda = lambda_trans + lambda_vent;

%solar_absorb = 0.3*A_window ;

end

