function [TotalTransportationManufacturingEmissions, TotalFuelAmounts] = CalcTransportationManufacturing(Data, CurrentYearTransportationConsumption,VehicleAmount, KMByEV)
% Description:
%   This function calculates the annual manufacturing emissions related to transportation,
%   including upstream emissions from fuel production (e.g., extraction, refining, delivery)
%   and emissions from electric vehicle (EV) battery manufacturing.

% Inputs:
%   CurrentYearTransportationConsumption - Vector of total kilometers traveled per vehicle type.
%   VehicleAmount                    - Matrix containing the amount of vehicles per type.
%   KMByEV                           - Total kilometers traveled by electric vehicles in the current year.

% Outputs:
%   TotalTransportationManufacturingEmissions - Table with emissions from manufacturing, per fuel type and emission type.
%   TotalFuelAmounts                          - Table with total fuel consumption by type, excluding crude oil, natural gas, and batteries.

% Notes:
%   - Emissions are calculated using predefined coefficients (tons per fuel unit).
%   - Fuel consumption is derived from both distance traveled and number of vehicles.
%   - Battery manufacturing emissions are proportional to the kilometers traveled by EVs.

    %% Inputs 
    
    NumOfDailyTrips = Data.Trans_DataBase.RidesPerDay;
    FuelConsumptionCoefficients = Data.Trans_DataBase.FuelConsumptionCoefficients; % g/Km
    VehicleType = FuelConsumptionCoefficients.Properties.VariableNames;
    TrainFuelConsumptionCoefficints =Data.Trans_DataBase.TrainFuelConsumptionCoefficints;
    InflationCoefficient = Data.Trans_DataBase.InflationCoefficient;
    Conversion_Liter_To_Kg = Data.Conversion_Liter_To_Kg;
    TransEnergy_type = Data.Trans_DataBase.TransEnergy_type;
    CrudeOilToFuelRatio = Data.Electricity_DataBase.CrudeOilToFuelRatio;
    NaturalGasForFuelRefining = Data.Trans_DataBase.NaturalGasForFuelRefining;
    TransEmission_Manu_type = Data.Trans_DataBase.TransEmission_Manu_type;
    EmissionsCoefficientsUpstream = Data.Trans_DataBase.EmissionsCoefficientsUpstream; %% array(6,7) Kg/Ton
    EmissionsCoefficientsFromBatteryManufacturing = Data.Electricity_DataBase.EmissionsCoefficientsFromBatteryManufacturing; % gCo2/km

    %% Motor Vehicle Fuel Consumption - tons

    % Define the vehicle type {'Bus', 'Car', 'Minibus', 'Motorcycle', 'Truck', 'LCV', 'Train'};
    TotalFuelConsumptionForMV = array2table(zeros(1, numel(VehicleType)));
    TotalFuelConsumptionForMV.Properties.VariableNames = VehicleType;

    for i=1:width(TotalFuelConsumptionForMV)-1
        TotalFuelConsumptionForMV{1,i} = (FuelConsumptionCoefficients{1,i}*CurrentYearTransportationConsumption(i) +  FuelConsumptionCoefficients{2,i}*VehicleAmount(5,i))/1000000;
    end
    
   %% Train fuel consumption - tons
    
    TotalKMBYTrain = CurrentYearTransportationConsumption(7:8)';
    %%EngineeringToolsFuelConsumption = readtable(Data,'Sheet','FuelProductionEmissionsForTrans','Range','O68:O68','ReadVariableNames',false);
    %%EngineeringToolsFuelConsumption = EngineeringToolsFuelConsumption{1,1};
    temp = TrainFuelConsumptionCoefficints.*TotalKMBYTrain*Conversion_Liter_To_Kg;
    TotalFuelConsumptionForMV{1,7} = ((sum(temp))/1000)*InflationCoefficient; %%+EngineeringToolsFuelConsumption)*InflationCoefficient; %% fuel consumption is in litters - 0.85 is conversion coefficint from litter to KG
    

    %% All vehicles fuel consumption - Tons

    %FuelForOtherUses = table2array(readtable(Data,'Sheet','FuelProductionEmissionsForTrans','Range','B33:F33','ReadVariableNames',false));
    TotalFuelConsumption = array2table(zeros(1,numel(TransEnergy_type)));
    % {'Mazut', 'Diesel', 'Kerosene', 'Gasoline','Liquefied Petroleum Gas', 'Crude Oil', 'Natural Gas', 'Battery Manufacturing'}
    TotalFuelConsumption.Properties.VariableNames = TransEnergy_type;
    %MazutConsumption = readtable(Data,'Sheet','FuelProductionEmissionsForTrans','Range','B30:B30','ReadVariableNames',false);
    %TotalFuelConsumption{1,1} = MazutConsumption{1,1} + FuelForOtherUses(1);
    %ShipInternationalConsumption = readtable(Data,'Sheet','FuelProductionEmissionsForTrans','Range','C30:C30','ReadVariableNames',false);
    %ShipInternationalConsumption = ShipInternationalConsumption{1,1};
    
    TotalFuelConsumption{1,2} = TotalFuelConsumptionForMV{1,1}+TotalFuelConsumptionForMV{1,3}+TotalFuelConsumptionForMV{1,5}+TotalFuelConsumptionForMV{1,6}+TotalFuelConsumptionForMV{1,7}; %+ ShipInternationalConsumption +FuelForOtherUses(2);%+sum(ShipAndPlaneFuelConsumption{:,2});
    %KeroseneConsumption = table2array(readtable(Data,'Sheet','FuelProductionEmissionsForTrans','Range','D31:D32','ReadVariableNames',false));
    %TotalFuelConsumption{1,3} = sum(KeroseneConsumption) + FuelForOtherUses(3);
    TotalFuelConsumption{1,4} = TotalFuelConsumptionForMV{1,2} + TotalFuelConsumptionForMV{1,4};% + FuelForOtherUses(4);
    %LiquefiedPetroleumGasConsumption = readtable(Data,'Sheet','FuelProductionEmissionsForTrans','Range','F29:F29','ReadVariableNames',false);
    %TotalFuelConsumption{1,5} = LiquefiedPetroleumGasConsumption{1,1};
    TotalFuelConsumption{1,6} = sum(TotalFuelConsumption{1,1:5})*CrudeOilToFuelRatio;
    TotalFuelConsumption{1,7} = NaturalGasForFuelRefining;
    
    %% total emissions per year
    RowNames = TransEnergy_type;
    TotalEmissionsPerCurrentYear = array2table(zeros(numel(TransEnergy_type),numel(TransEmission_Manu_type)), 'RowNames', RowNames);
    % {'CH4', 'CO2','Hydroflour Carbon','Air Pollutants','Mining Waste','Waste Water','CO2E'}
    TotalEmissionsPerCurrentYear.Properties.VariableNames = TransEmission_Manu_type;
    for i=1:height(TotalEmissionsPerCurrentYear)-1 %% 1-7
        for j=1:width(TotalEmissionsPerCurrentYear) %%1-7
            TotalEmissionsPerCurrentYear{i,j} = EmissionsCoefficientsUpstream(i,j)*TotalFuelConsumption{1,i}/1000; % tons
        end    
    end
    TotalFuelAmounts = removevars(TotalFuelConsumption, {'Crude Oil', 'Natural Gas', 'Battery Manufacturing'});
    
    %% Emissions from EV manufacturing
    TotalEmissionsPerCurrentYear{8,7} = EmissionsCoefficientsFromBatteryManufacturing*KMByEV/1000000; % tons
    
    TotalTransportationManufacturingEmissions = TotalEmissionsPerCurrentYear;

end

