function [ Trefshadow ] = flexEstimator(Tref, flexParam, price)
%This function can quantify a load flexibility based on input prices, and
%provide an alternative load curve which can be compared to the load curve
%only influenced by weather data and static temperature reference

%sensititvity parameters:

alpha = -flexParam.deltaT/(flexParam.priceMax - flexParam.priceMean);
beta = (-flexParam.deltaT + Tref) - flexParam.priceMax*alpha;

if price >= flexParam.priceMax
    Trefshadow = Tref- flexParam.deltaT;
elseif price <= (1/alpha)*(Tref + flexParam.deltaT)
    Trefshadow = Tref + flexParam.deltaT;
else
    Trefshadow = alpha*price + beta;
end

end



