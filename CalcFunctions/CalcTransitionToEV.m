function [KMTraveledByElectricVehicle, UpdatedTranportationConsumption] = CalcTransitionToEV(TrasnporationConsumption,TransitionToEV)
% Calculates the number of kilometers traveled by electric vehicles (EV)
% and the remaining transportation consumption after the EV transition.
% Inputs:
%   TrasnporationConsumption - Total transportation distance or consumption (e.g., in kilometers)
%   TransitionToEV - Fraction (0 to 1) of the transportation that shifts to electric vehicles
% Outputs:
%   KMTraveledByElectricVehicle - Distance now traveled by electric vehicles
%   UpdatedTranportationConsumption - Remaining transportation distance not yet transitioned to EV

% Calculate the distance traveled by electric vehicles
%KMTraveledByElectricVehicle = TrasnporationConsumption*TransitionToEV;
% Lidor's updates:

KMTraveledByElectricVehicle = TrasnporationConsumption*(TransitionToEV - 1);


% If the electric vehicle distance exceeds or equals the total consumption,
% set all transportation to be electric and remaining consumption to zero
if(KMTraveledByElectricVehicle >= TrasnporationConsumption)
    KMTraveledByElectricVehicle = TrasnporationConsumption;
    UpdatedTranportationConsumption = 0;
else
    % Otherwise, subtract the EV distance from the total to get the remaining consumption
    UpdatedTranportationConsumption = TrasnporationConsumption - KMTraveledByElectricVehicle;
end
end