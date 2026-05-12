 function ElectricityForWaterConsumption = CalcElectricityForWater(Data, WaterConsumption, ElectricityConsumptionCoefficients)

 % Description:
%   Calculates total electricity consumption (in KWh) required for different types of water sources,
%   including drilling water, desalinated water, reclaimed wastewater, and reservoir/brackish water.
%   The calculation is based on water consumption and predefined electricity consumption coefficients.

% Inputs:
%   WaterConsumption              - Table or cell array with water consumption values by source.
%   ElectricityConsumptionCoefficients - Vector of electricity consumption coefficients (KWh per cubic meter).

% Output:
%   ElectricityForWaterConsumption - Table with total electricity consumption for each water source (in KWh).

 %% Inputs 
 % {'Drilling Water', 'Desalinated Water', 'Moving Reclaimed Wastewater', 'Reclaimed Wastewater','Moving Brackish water, fresh and non-fresh reservoir water', 'Total'}
 Water_Electricity_Types = Data.Water_DataBase.Water_Electricity_Types;
 LossRatio = Data.Water_DataBase.LossRatio;
 
 % Water consumption (miliom m^3)
 DrillingWater = WaterConsumption{1,5};
 DesalinatedWater = WaterConsumption{1,8};
 ReclaimedWastewater = WaterConsumption{1,6};


 %% Calculate Electricity consumption - milionm^3*Kwh/m^3 = milion Kwh
 DrillingWaterElectrcity = (ElectricityConsumptionCoefficients(2) + ElectricityConsumptionCoefficients(6))* DrillingWater;
 DesalinatedElectricity = DesalinatedWater*(ElectricityConsumptionCoefficients(1) + ElectricityConsumptionCoefficients(2));
 MovingReclaimedWastewaterElectricity = ElectricityConsumptionCoefficients(4)*ReclaimedWastewater;
 ReclaimedWastewaterElectricity = ReclaimedWastewater*ElectricityConsumptionCoefficients(5);
 MovingBrackishandReservoirWater = WaterConsumption{1,7}*ElectricityConsumptionCoefficients(2);


 %% Output

 %RowNames = {'Water From Nature', 'Total Urban Consumption', 'Diselinated Water', 'Treated Waste Water', 'Sewege', 'Total'};
 ElectricityForWaterConsumption = array2table(zeros(numel(Water_Electricity_Types),1), 'RowNames', Water_Electricity_Types);
 ElectricityForWaterConsumption.Properties.VariableNames = {'Total KWH'};

 % Here we also convert it to be Kwh
 ElectricityForWaterConsumption{1,1} = DrillingWaterElectrcity*LossRatio*1000000;
 ElectricityForWaterConsumption{2,1} = DesalinatedElectricity*LossRatio*1000000;
 ElectricityForWaterConsumption{3,1} = MovingReclaimedWastewaterElectricity*LossRatio*1000000;
 ElectricityForWaterConsumption{4,1} = ReclaimedWastewaterElectricity*LossRatio*1000000;
 ElectricityForWaterConsumption{5,1} = MovingBrackishandReservoirWater*LossRatio*1000000;
 ElectricityForWaterConsumption{6,1} = sum(ElectricityForWaterConsumption{1:5,1}); %to compare to a cubic meter
 
end

