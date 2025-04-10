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
 % Water consumption
 DrillingWater = WaterConsumption{1,5};
 DesalinatedWater = WaterConsumption{1,8};
 ReclaimedWastewater = WaterConsumption{1,6};

 %{
     %% Urban 
     UrbanConsumptionPercentages = Data.UrbanConsumptionPercentages;
     UrbanConsumption_FreshWater = WaterConsumption{1,1}*0.89; %Fresh water for domestic consumption without 11 percent of non-fresh water
     UrbanConsumption = WaterConsumption{1,1};
     Construction = UrbanConsumption_FreshWater*UrbanConsumptionPercentages(6);
     
     Gardening = (WaterConsumption{1,1}*0.11)*UrbanConsumptionPercentages(4);
     Residential =(WaterConsumption{1,1})*UrbanConsumptionPercentages(1);
     UrbanNoConstruction = UrbanConsumption - Construction;
 %}

 %% Calculate Electricity consumption 
 DrillingWaterElectrcity = (ElectricityConsumptionCoefficients(2) + ElectricityConsumptionCoefficients(6))* DrillingWater;
 DesalinatedElectricity = DesalinatedWater*(ElectricityConsumptionCoefficients(1) + ElectricityConsumptionCoefficients(2));
 MovingReclaimedWastewaterElectricity = ElectricityConsumptionCoefficients(4)*ReclaimedWastewater;
 ReclaimedWastewaterElectricity = ReclaimedWastewater*ElectricityConsumptionCoefficients(5);
 MovingBrackishandReservoirWater = WaterConsumption{1,7}*ElectricityConsumptionCoefficients(2);
 
 %{ 
 UrbanElectricity = UrbanNoConstruction*ElectricityConsumptionCoefficients(3);
 FromNatureElectrcity = FromNature*(ElectricityConsumptionCoefficients(2) + ElectricityConsumptionCoefficients(6));
 TreatedWasteWaterElectricity = TreatedWasteWater*ElectricityConsumptionCoefficients(4);
 TotalSewege = UrbanConsumption-Contruction-Gardening-0.15*Residential;
 %}

 %% Output

 %RowNames = {'Water From Nature', 'Total Urban Consumption', 'Diselinated Water', 'Treated Waste Water', 'Sewege', 'Total'};
 ElectricityForWaterConsumption = array2table(zeros(numel(Water_Electricity_Types),1), 'RowNames', Water_Electricity_Types);
 ElectricityForWaterConsumption.Properties.VariableNames = {'Total KWH'};

 ElectricityForWaterConsumption{1,1} = DrillingWaterElectrcity*LossRatio;
 ElectricityForWaterConsumption{2,1} = DesalinatedElectricity*LossRatio;
 ElectricityForWaterConsumption{3,1} = MovingReclaimedWastewaterElectricity*LossRatio;
 ElectricityForWaterConsumption{4,1} = ReclaimedWastewaterElectricity*LossRatio;
 ElectricityForWaterConsumption{5,1} = MovingBrackishandReservoirWater*LossRatio;
 ElectricityForWaterConsumption{6,1} = sum(ElectricityForWaterConsumption{1:5,1})*1000000; %to compare to a cubic meter
 
 %{ 
     ElectricityForWaterConsumption{1,1} = FromNatureElectrcity*LossRatio;
     ElectricityForWaterConsumption{2,1} = UrbanElectricity*LossRatio;
     ElectricityForWaterConsumption{3,1} = DesalinatedElectricity*LossRatio;
     ElectricityForWaterConsumption{4,1} = TreatedWasteWaterElectricity*LossRatio;
     ElectricityForWaterConsumption{5,1} = SewewgeElectricity*LossRatio;
    
     ElectricityForWaterConsumption{6,1} = sum(ElectricityForWaterConsumption{1:5,1});
 %}
end

