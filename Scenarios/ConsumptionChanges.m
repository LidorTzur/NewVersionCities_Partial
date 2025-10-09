 function [ElectricityConsumptionTable, TransportationConsumptionTable, VehicleAmountsCell, FoodConsumptionCell, WaterConsumptionCell, ConstructionTable, ConstructionFootprintTable, WateAndRecyclingCell, AmountsOfFuelsCells, OrganicWasteAmount] = ConsumptionChanges(Data, ScenariosTable,Years,pop,orderIndex, varargin)
% This function calculates consumption changes based on population growth and predefined coefficients.
% Input:
%   - Data: Structure containing base data for various consumption categories.
%   - ScenariosTable: Table containing scenario multipliers for each year.
%   - Years: Number of years for the simulation.
%   - pop: Population data.
%   - orderIndex: Index indicating scenario execution order.
%   - varargin: Optional additional parameters.
% Output:
%   - Various consumption tables and cells.

%% Variables

global BaseYear

% vehicle quantity
VehicleAmountsCell = Data.Trans_DataBase.VehicleAmountsCell;
VehicleAmounts_RowNames = {'Quantity', 'Gasoline', 'Diesel', 'Drive Per Day', 'Drive Per Year', 'Cars Per Year'};
VehicleAmounts_ColNames = {'Bus','Car','Minibus','Motorcycle', 'Truck', 'LCV'};
VehicleAmounts_Row_Num = numel(VehicleAmounts_RowNames);
VehicleAmounts_Col_Num = numel(VehicleAmounts_ColNames);

% Transportation
TransportationConsumptionTable = Data.Trans_DataBase.TransportationConsumptionTable;

% Food
FoodConsumptionCell = Data.Food_DataBase.FoodConsumptionCell;
RowNames = Data.Food_DataBase.FoodRowName;
ColNames = {'Humans and Other - Local','Animals - Local','Humans and Others - Import','Animals - Import'};
OnlyImportedFoodIndex = [2, 8, 45, 46, 47, 55, 57, 58, 62];
% 1X32 cell, each one conatains a table of consumption for the relevant year.
Initialization = FoodConsumptionCell{1}{:,:}; % data of 2019
food_numRows = size(Initialization, 1);
food_numCols = size(Initialization, 2); 

p = inputParser;
addOptional(p,'ChangesStruct', []);
parse(p,varargin{:});

%% Electricity Consumption

% NEW: Electicity that the industry consumes isn't affected by the population growth.
ElectricityConsumptionTable = Data.Electricity_DataBase.ElectricityConsumptionTable;
% Lidor- Add the loss ratio to the electricity consumption
ElectricityConsumptionTable{:,1} = ElectricityConsumptionTable{:,1}*Data.Electricity_DataBase.ElectricityLossRatio;
IndustryElectricityConsumptionChange = Data.Electricity_DataBase.IndustryElectricityConsumptionChange; % assuming industrial grow by 1.1
ChangeInElectricityConsumptionPercentageIndustry = CalculatePercentageLinear(1, IndustryElectricityConsumptionChange, Years);

for i=2:Years
  %  ElectricityConsumptionTable{:, i} = PrecentegeByTheYears(i)*ElectricityConsumptionTable{:,1};
  ElectricityConsumptionTable{1, i} = ScenariosTable{1,i} * ElectricityConsumptionTable{1,1}; %home
  ElectricityConsumptionTable{2, i} = ScenariosTable{1,i} * ElectricityConsumptionTable{2,1}; %public/commercial
  ElectricityConsumptionTable{4, i} = ScenariosTable{1,i} * ElectricityConsumptionTable{4,1}; %other
  if ScenariosTable{1,1} == ScenariosTable{1,Years}
    ElectricityConsumptionTable{3, i} = ScenariosTable{1,i} * ElectricityConsumptionTable{3,1}; %industrial 
  else
    ElectricityConsumptionTable{3, i} = ChangeInElectricityConsumptionPercentageIndustry(i) * ElectricityConsumptionTable{3,1}; %industrial
  end
end

%% Transportation Consumption
for i=1:Years
    %Growth = ScenariosTable{1,i}*1.011; %% didnt understant why?!?!?!
    Growth = ScenariosTable{1,i};
    TransportationConsumptionTable{1:8, i} = Growth*TransportationConsumptionTable{1:8,1};
    TransportationConsumptionTable{9,i} = sum(TransportationConsumptionTable{1:8,i});
end

%% Vehicle Amoount
for i = 1:Years
    CurrentAmount = array2table(zeros(VehicleAmounts_Row_Num,VehicleAmounts_Col_Num), 'RowNames', VehicleAmounts_RowNames);
    CurrentAmount{:,:} = VehicleAmountsCell{1}{:,:}*(ScenariosTable{1,i});
    CurrentAmount.Properties.VariableNames = VehicleAmounts_ColNames;
    VehicleAmountsCell{i} =  CurrentAmount;
end

%% Food Consumption
% assuming perfect corrrelation between population growth and food consumption.
% SHIRI'S UPDATE:
% adding upper-bound to the growth of local consumption due to area limitation.
UpperBound =  Data.Food_DataBase.TotalGrowthForLocalFood;
if (width(ScenariosTable) == Years) % making sure the table has enough columns

    if (ScenariosTable{5,Years} <= 0.8267 && ScenariosTable{5,Years} > 0.826) 
        % moderate scenario: due to the prevention of food loss we can use more land.
        UpperBound = UpperBound * 1.24;

    elseif (ScenariosTable{5,Years} < 0.7467 && ScenariosTable{5,Years} > 0.746) 
        % advanced scenario: due to the prevention of food loss we can use more land.
        UpperBound = UpperBound * 1.41;
    end
end

FoodPercentegeByTheYearsLocal = CalcFoodPercentegeByTheYearsLocal(ScenariosTable, UpperBound, Years);
FoodPercentegeByTheYearsGlobal = CalcFoodPercentegeByTheYearsGlobal(ScenariosTable, UpperBound, Years);
FoodPercentageByTheYearsOriginal = ScenariosTable{1,:};


for i = 1:Years
    % each column is multiplied by the relevant percentages, in order to
    % limit the area for food in Israel to 4500 Km^2
    CurrentConsumption = array2table(zeros(food_numRows,food_numCols), 'RowNames', RowNames);
    CurrentConsumption{:,1} = Initialization(:,1)*(FoodPercentegeByTheYearsLocal(i));
    CurrentConsumption{:,2} = Initialization(:,2)*(FoodPercentegeByTheYearsLocal(i));
    CurrentConsumption{:,3} = Initialization(:,3)*(FoodPercentegeByTheYearsGlobal(i));
    CurrentConsumption{:,4} = Initialization(:,4)*(FoodPercentegeByTheYearsGlobal(i));
    CurrentConsumption.Properties.VariableNames = ColNames;

    for j = OnlyImportedFoodIndex
        % food that is grown only overseas isnt affacted by the area
        % limitation, and therefore only by the population growth: 
        % (change when updating the area coefficients in the orignal DATA)
        CurrentConsumption{j,:} = Initialization(j,:) * FoodPercentageByTheYearsOriginal(i);
    end

    FoodConsumptionCell{i} =  CurrentConsumption;
end

% for i = 1:Years
%    CurrentConsumption = array2table(zeros(food_numRows,food_numCols), 'RowNames', RowNames);
%    CurrentConsumption{:,:} = Initialization*(PrecentegeByTheYears(i));
%    CurrentConsumption.Properties.VariableNames = ColNames;
%    FoodConsumptionCell{i} =  CurrentConsumption;
% end



%% WATER

% Lidor's Update to be generic
WDB = Data.Water_DataBase;

%% WaterData HELP TABLE - For the changing Sectors not just by population (changing in years not by population)

water_Names = WDB.water_Names; % {'Water for Domestic & Industrial', 'Water for Agriculture', 'Water for Neighbors', 'Water for  Nature', 'Drilling Water', 'Reclaimed Wastewater', 'Brackish water, fresh and non-fresh reservoir water', 'Desalinated Water'};
waterData  = array2table(zeros(numel(water_Names), Years), 'RowNames', water_Names);

for i =1:Years  

   % 1. FOR THE UNCHANGING SECTORS
   waterData{'Water for Domestic & Industrial',i} = WDB.Avg_per_capita_domestic; % Fixed Consumption per capita
   waterData{'Water for Neighbors',i} = WDB.Avg_per_capita_Palestinians; % Consumption per capita
   waterData{'Reclaimed Wastewater',i} = NaN; % 66% from the Domestic water in each year
   waterData{'Brackish water, fresh and non-fresh reservoir water',i} = WDB.Fixed_Brackish; % Fixed value
   waterData{'Desalinated Water',i} = NaN; % complete the demand in each year
   
   %2. FOR THE CHANGING SECTORS

   % Agriculture per capita to all years
   waterData{'Water for Agriculture',i} = WDB.AgriculturePerCapitaFactor_water * log(i + (BaseYear - WDB.AgricultureBaseYear_water + 1)) + WDB.AgriculturePerCapitaOffset_water;
   
   % water for nature (conditions to be between some years ...) from the
   % "צרכנים" sheet in the water model excel in the projects files of dor
   idx = find(i < WDB.Nature_water_yearThresholds, 1); 
   if isempty(idx)
       selectedValue = WDB.Nature_water_yearThresholds_values(end);
   else
       selectedValue = WDB.Nature_water_yearThresholds_values(idx);
   end
   waterData{'Water for  Nature', i} = selectedValue;

   % Old solution
   % switch true 
   %     case i<7
   %        waterData(row_num,i) = {25};
   %     case i>=7 & i<12
   %        waterData(row_num,i) = {35};
   %     case i>=12 & i<22
   %        waterData(row_num,i) = {50};
   %     case i>=22 & i<32
   %        waterData(row_num,i) = {75};
   % end
   
   % Driliing Water

   % first year (2019)
   waterData{'Drilling Water',1} = WDB.WaterConsumptionTableNew{'Drilling Water', '2019'}; 
   
   % Drilling Water to all the other years
   if i>1   % means that is not in the Base year
       waterData{'Drilling Water',i} = waterData{'Drilling Water',i-1}*WDB.Yearly_ChangeDrillingWater;
       
       if i==2022-BaseYear+1 % Adjustment to the water model data for 2022, until all the data in the software is updated
            waterData{'Drilling Water',i} = WDB.WaterConsumptionTableNew{'Drilling Water', '2022'};
       end
   end
end

%% Water Consumption
WaterConsumptionCell = WDB.WaterConsumptionCell;
sectorNames = WDB.WaterConsumptionTableNew.Properties.RowNames;
CurrentConsumption = array2table(zeros(1, numel(sectorNames)), 'VariableNames', sectorNames);
% Initialization = WaterConsumptionCell{1}{:,1:5};

% %%2019 Data - from Dor's Model
% CurrentConsumption{1,'Water for Domestic & Industrial'} = 1022;
% CurrentConsumption{1,'Water for Agriculture'} = 1193;
% CurrentConsumption{1,'Water for Neighbors'} = 146;
% CurrentConsumption{1,'Water for  Nature'} = 24;
% CurrentConsumption{1,'Drilling Water'} = 828;
% CurrentConsumption{1,'Reclaimed Wastewater'} = 630;
% CurrentConsumption{1,'Brackish water, fresh and non-fresh reservoir water'} = 250;
% CurrentConsumption{1,'Desalinated Water'} = 609;

CurrentConsumption{1, :} = WDB.WaterConsumptionTableNew{:, '2019'}';
WaterConsumptionCell{1} =  CurrentConsumption;

%The essential change that ensures the correctness of the water model in a single scenario
%  Put the base values - Data for 2022 - another point we insert to increase accuracy
if (ScenariosTable{1,1}) == ScenariosTable{1,width(ScenariosTable)} && (orderIndex == 2) 
    for i =2:Years
        % % Consumers - Prediction for 2022 year
        % CurrentConsumption = array2table(zeros(1,numel(water_Names)), 'VariableNames', water_Names);
        % CurrentConsumption{1,1} = 1070;
        % CurrentConsumption{1,2} = 1300;
        % CurrentConsumption{1,3} = 190;
        % CurrentConsumption{1,4} = 25;
        % % Suppliers - Prediction for 2022 year
        % CurrentConsumption{1,5} = 1080;
        % CurrentConsumption{1,6} = 636;
        % CurrentConsumption{1,7} = 250;
        % CurrentConsumption{1,8} = 524;  

        CurrentConsumption{1, :} = WDB.WaterConsumptionTableNew{:,'2022'}';
        WaterConsumptionCell{i} =  CurrentConsumption;
    end

else
    for i =2:Years 
        sectorNames = WDB.WaterConsumptionTableNew.Properties.RowNames;
        CurrentConsumption = array2table(zeros(1, numel(sectorNames)), 'VariableNames', sectorNames);
        % Consumers
        CurrentConsumption{1,'Water for Domestic & Industrial'} = pop{'Israel population',i}*waterData{'Water for Domestic & Industrial',i}; 
        CurrentConsumption{1,'Water for Agriculture'} = pop{'Israel population',i}*waterData{'Water for Agriculture',i}; 
        CurrentConsumption{1,'Water for Neighbors'} = pop{'Palestinian Authority population',i}*waterData{'Water for Neighbors',i}; 
        CurrentConsumption{1,'Water for  Nature'} = waterData{'Water for  Nature', i}; 
        % Suppliers
        CurrentConsumption{1,'Drilling Water'} = waterData{'Drilling Water',i}; %% natural 
        CurrentConsumption{1,'Reclaimed Wastewater'} = WDB.ReclaimedRatio*CurrentConsumption{1,'Water for Domestic & Industrial'}; 
        CurrentConsumption{1,'Brackish water, fresh and non-fresh reservoir water'} = waterData{'Brackish water, fresh and non-fresh reservoir water',i}; 
        CurrentConsumption{1,'Desalinated Water'} = CurrentConsumption{1,'Water for Domestic & Industrial'}*WDB.FreshWaterForDomestic  + CurrentConsumption{1,'Water for Agriculture'}*WDB.FreshWaterForAgriculture  + CurrentConsumption{1,'Water for Neighbors'} - CurrentConsumption{1,'Drilling Water'}; 
        
        if i == (2022-BaseYear+1) % Adjustment to the water model data for 2022, until all the data in the software is updated - to give extra data to the predictions
            % % Consumers
            % CurrentConsumption{1,1} = 1070;
            % CurrentConsumption{1,2} = 1300;
            % CurrentConsumption{1,3} = 190;
            % CurrentConsumption{1,4} = 25;
            % % Suppliers
            % CurrentConsumption{1,5} = 1080;
            % CurrentConsumption{1,6} = 636;
            % CurrentConsumption{1,7} = 250;
            % CurrentConsumption{1,8} = 524;  

            CurrentConsumption{1, :} = WDB.WaterConsumptionTableNew{:, '2022'}';
        end
          WaterConsumptionCell{i} =  CurrentConsumption;
    end
end

Data.Water_DataBase = WDB;




%% Construction Tables
ConstructionTable = Data.Const_DataBase.ConstructionTable;
ConstructionTable_numRows = height(ConstructionTable) - 1;
ConstructionInitialization = ConstructionTable{1:ConstructionTable_numRows,1};

% Lidor's addition
ConstructionFootprintTable = Data.Const_DataBase.ConstructionFootprintTable;
ConstructionFootprint_numRows = height(ConstructionFootprintTable) - 1;
ConstructionFootprintInitialization = ConstructionFootprintTable{1:ConstructionFootprint_numRows,1};

CDB = Data.Const_DataBase;
 for i=2:Years

    %ConstructionTable{1:ConstructionTable_numRows, i} = (ScenariosTable{1,i}*ConstructionInitialization) - (sum(ConstructionTable{1:ConstructionTable_numRows, 1:i-1}, 2));
    %ConstructionTable{1:9, i} = (ScenariosTable{1,i}*ConstructionInitialization) - (sum(ConstructionTable{1:ConstructionTable_numRows, 1:i-1}, 2));
    %ConstructionTable{10:11, i} = (ScenariosTable{1,i}*PopulationStartYear_global*(CDB.Built_up_area_per_capita+(CDB.Annual_area_per_capita_growth_rate*(i-1)))) - (sum(ConstructionTable{1:ConstructionTable_numRows, 1:i-1}, 2)); % For the Domestic Categury
    ConstructionTable{ConstructionTable_numRows+1, i} = sum(ConstructionTable{1:ConstructionTable_numRows, i});

    % Lidor's addition
    ConstructionFootprintTable{1:ConstructionFootprint_numRows, i} = (ScenariosTable{1,i}*ConstructionFootprintInitialization) - sum(ConstructionFootprintTable{1:ConstructionFootprint_numRows, 1:i-1}, 2);
    %ConstructionFootprintTable{1:9, i} = (ScenariosTable{1,i}*ConstructionFootprintInitialization) - sum(ConstructionFootprintTable{1:ConstructionFootprint_numRows, 1:i-1}, 2);
    %ConstructionFootprintTable{10:11, i} = (ScenariosTable{1,i}*ConstructionFootprintInitialization) - sum(ConstructionFootprintTable{1:ConstructionFootprint_numRows, 1:i-1}, 2);
    ConstructionFootprintTable{ConstructionFootprint_numRows+1, i} = sum(ConstructionFootprintTable{1:ConstructionFootprint_numRows, i});

 end
 % Take for the base year 2019 the 2020 delta
 ConstructionTable{1:ConstructionTable_numRows, 1} = ConstructionTable{1:ConstructionTable_numRows, 2};
 ConstructionFootprintTable{1:ConstructionFootprint_numRows, 1} = ConstructionFootprintTable{1:ConstructionFootprint_numRows, 2};

%% Materials - generated waste and recycling
RowNames = {'Organic Products','Plastic', 'Paper', 'Cardboard', 'Diapers', 'Garden Waste', 'Textile', 'Metal', 'Glass', 'Pruned Trees','Wood', 'Oils', 'Others'};
ColNames = {'Local Authorities - Waste', 'Local Authorities - Recycling', 'Industry - Waste', 'Industry - Recycling','Food Industry - Waste' , 'Food Industry - Recycling','Agriculture - Waste', 'Agriculture - Recycling'};

WateAndRecyclingCell = Data.Materials_DataBase.WateAndRecyclingCell;
for i =2:Years
    CurrentRecyclingAndWate =  array2table(zeros(13,8), 'RowNames', RowNames);
    CurrentRecyclingAndWate.Properties.VariableNames = ColNames;
    CurrentRecyclingAndWate{:,:} = WateAndRecyclingCell{1}{:,:}*ScenariosTable{1,i};
    WateAndRecyclingCell{i} = CurrentRecyclingAndWate;
end

%% Organic Waste (From food)

OrganicWasteAmount =  Data.Food_DataBase.OrganicWasteAmountsCell;
RowNames = {'Local Authorities', 'Food Industry', 'Agriculture'};
ColNames = OrganicWasteAmount{1}.Properties.VariableNames;
for i = 2:Years
    CurrentOrganicWaste = array2table(zeros(3,2), 'RowNames',RowNames, 'VariableNames',ColNames);
    CurrentOrganicWaste{:,:} = OrganicWasteAmount{1}{:,:}*ScenariosTable{1,i};
    OrganicWasteAmount{i} = CurrentOrganicWaste;
end    


%% Amounts of Fuels (for industry) - Tons ------ Removed from the City model (Lidor) - values 0
RowNames = {'Crude Oil Products - Not for Energy', 'Crude Oil For Export', 'Crude Oil Import', 'Crude Oil Products - For Energy', 'LPG - Home', 'LPG - Commertiel' };
ColNames = {'Naptha', 'Diesel','Mazut','Kerosene','Gasoline','Liquified Petroleum Gas', 'Other'};
AmountsOfFuelsCells = Data.Materials_DataBase.AmountsOfFuelsCells;
% Crude Oil Products - For Energy
% multiple by 2- so it match to the data of raziel (this is what tal did and matched to raziel data)
AmountsOfFuelsCells{1,1}{4,:} = AmountsOfFuelsCells{1,1}{4,:}*2; % Completion to an estimated size of 1.5 MTOE Because currently the data is 0.75
for i = 1:Years
    CurrentFuelConsumption = array2table(zeros(6,7),'RowNames', RowNames);
    CurrentFuelConsumption.Properties.VariableNames = ColNames;
    CurrentFuelConsumption{:,:}  =  AmountsOfFuelsCells{1}{:,:};
    CurrentFuelConsumption{1:4,:} = AmountsOfFuelsCells{1}{1:4,:}*ScenariosTable{9,i}; % The multiplication in ScenariosTable{9,i} is because we understand that the amount of fuels in the industry will decrease according to this vector
    CurrentFuelConsumption{5:6,:} = AmountsOfFuelsCells{1}{5:6,:}*ScenariosTable{1,i}; % The multiplication in ScenariosTable{1,i} is because we understand that the amount of LPG will increase according to the increase in the population
    AmountsOfFuelsCells{i} = CurrentFuelConsumption;
end   

%% ADJUSTING FOR 2035:
%  REMOVING UNECESSARY COLUMNS FROM THE TABLES:

if (orderIndex >= 7 && width(ScenariosTable) <= Years) 
   ElectricityConsumptionTable = ElectricityConsumptionTable(:, 1:Years);
   TransportationConsumptionTable = TransportationConsumptionTable(:, 1:Years);
   VehicleAmountsCell = VehicleAmountsCell(:, 1:Years);
   FoodConsumptionCell = FoodConsumptionCell(:, 1:Years);
   WaterConsumptionCell = WaterConsumptionCell(:, 1:Years);
   ConstructionTable = ConstructionTable(:, 1:Years);
   ConstructionFootprintTable = ConstructionFootprintTable(:, 1:Years);
   WateAndRecyclingCell = WateAndRecyclingCell(:, 1:Years);
   AmountsOfFuelsCells = AmountsOfFuelsCells(:, 1:Years);
   OrganicWasteAmount =OrganicWasteAmount(:, 1:Years);
end

Data.Const_DataBase.ConstructionTable = ConstructionTable;
Data.Const_DataBase.ConstructionFootprintTable = ConstructionFootprintTable;

%%
function PercentVector = CalcChangeVector(MileStoneVector, Years, S, varargin)
    p = inputParser;
    addOptional(p,'Type','Exponential');
    addOptional(p,'Growth',true);
    parse(p,varargin{:});
    if(strcmp(p.Results.Type, 'Exponential'))
        PercentVector = Exponential(MileStoneVector, Years, S, p.Results.Growth);
    elseif(strcmp(p.Results.Type, 'Linear'))
         PercentVector = Linear(MileStoneVector, Years, S, p.Results.Growth);
    elseif(strcmp(p.Results.Type, 'Step'))
        PercentVector = Step(MileStoneVector, Years, S, p.Results.Growth);
    else
        PercentVector = zeros(1,Years);
    end
end

% exponential
function [PercentVector] = Exponential(MileStoneVector, Years, S, Growth)
    PercentVector = ones(1,Years);
    if Growth == 1
        PercentVector(Years) = 1+S;
        MileStoneVector(Years) = S;
    else
        PercentVector(Years) = 1-S;
        MileStoneVector(Years) = -1*S;
    end    
    StartYear = 1;
    for i = 1:length(MileStoneVector)
        if(MileStoneVector(i) ~= 0)
            EndYear = i;
            GrowthVector = GrowthVectorCalc(StartYear, EndYear, MileStoneVector(i), MileStoneVector(StartYear));
            for j = 1:length(GrowthVector)
                PercentVector(StartYear+j-1) = GrowthVector(j);
            end
            StartYear = i;
        end
    end
end

function GrowthVector = GrowthVectorCalc(StartYear, EndYear, EndYearVal, StartYearVal)
Period = EndYear-StartYear+1;
GrowthVector = ones(1, Period);
GrowthVector(1) = 1 + StartYearVal;
GrowthVector(Period) = 1 + EndYearVal;
FutureValue = GrowthVector(Period);
Rate = nthroot(FutureValue/GrowthVector(1),Period-1);
for i = 1:Period
    GrowthVector(i) = GrowthVector(1)*((Rate)^(i-1));
end
end

%Step
function [PercentVector] = Step(MileStoneVector, Years, S)
    PercentVector = ones(1,Years);
    if Growth == 1
        PercentVector(Years) = 1+S;
        MileStoneVector(Years) = S;
    else
        PercentVector(Years) = 1-S;
        MileStoneVector(Years) = -1*S;
    end    
    StartYear = 1;
    for i = 1:length(MileStoneVector)
        if(MileStoneVector(i) ~= 0)
            EndYear = i;
            GrowthVector = StepCalc(StartYear, EndYear, MileStoneVector(i));
            for j = 1:length(GrowthVector)
                PercentVector(StartYear+j-1) = GrowthVector(j);
            end
            StartYear = i;
        end
    end
end

function GrowthVector = StepCalc(StartYear, EndYear, EndYearVal)
    Period = EndYear-StartYear+1;
    GrowthVector = ones(1, Period)+EndYearVal;
end

%linear
function [PercentVector] = Linear(MileStoneVector, Years, S)
    PercentVector = ones(1,Years);
    if Growth == 1
        PercentVector(Years) = 1+S;
        MileStoneVector(Years) = S;
    else
        PercentVector(Years) = 1-S;
        MileStoneVector(Years) = -1*S;
    end    
    MileStoneVector(Years) = S;
    StartYear = 1;
    for i = 1:length(MileStoneVector)
        if(MileStoneVector(i) ~= 0)
            EndYear = i;
            GrowthVector = LinearCalc(StartYear, EndYear, MileStoneVector(i),MileStoneVector(StartYear));
            for j = 1:length(GrowthVector)
                PercentVector(StartYear+j-1) = GrowthVector(j);
            end
            StartYear = i;
        end
    end
end

function GrowthVector = LinearCalc(StartYear, EndYear, EndYearVal,StartYearVal)
    Period = EndYear-StartYear+1;
    GrowthVector = ones(1, Period);
    GrowthVector(1) = 1 + StartYearVal;
    GrowthVector(Period) = 1+EndYearVal;
    if(EndYearVal > StartYearVal)
        Rate = (EndYearVal-StartYearVal)/(Period-1);
    else
        Rate = -1*(StartYearVal-EndYearVal)/Period;
    end
    for i = 1:Period
        GrowthVector(i) = GrowthVector(1)+Rate*(i-1);
    end
end

%% Other Functions
function [PercentVector] = MileStonesGrowth(MileStoneVector, Years, S)
PercentVector = ones(1,Years);
PercentVector(Years) = 1+S;
MileStoneVector(Years) = S;
StartYear = 1;
for i = 1:length(MileStoneVector)
    if(MileStoneVector(i) ~= 0)
        EndYear = i;
        GrowthVector = GrowthVectorCalc(StartYear, EndYear, MileStoneVector(i), MileStoneVector(StartYear));
        for j = 1:length(GrowthVector)
            PercentVector(StartYear+j-1) = GrowthVector(j);
        end    
        StartYear = i;
    end
end
end

 end



 %% OTHER FUNCTIONS:

 function LinearPercentageVector = CalculatePercentageLinear(StartValue, EndValue, Years)
    step = (EndValue - StartValue) / (Years - 1);
    LinearPercentageVector = zeros(1, Years);
    for i = 1:Years
        LinearPercentageVector(i) = StartValue + (i - 1) * step;
    end
end

function FoodPercentegeByTheYearsLocal = CalcFoodPercentegeByTheYearsLocal(ScenariosTable, UpperBound, Years)
% doesnt allow the growth vector to bigger than the defined percentae.
    PercentegeByTheYears = ScenariosTable{1,:};
    FoodPercentegeByTheYearsLocal = PercentegeByTheYears;
    for i = 1:Years
        if PercentegeByTheYears(i) > UpperBound
           FoodPercentegeByTheYearsLocal(i) = UpperBound;
        end
    end
end

function FoodPercentegeByTheYearsGlobal = CalcFoodPercentegeByTheYearsGlobal(ScenariosTable, UpperBound, Years)
% if there's no more available area in Israel - the growth is moved to overseas.
    PercentegeByTheYears = ScenariosTable{1,:};
    FoodPercentegeByTheYearsGlobal = PercentegeByTheYears;
    for i = 1:Years
        if PercentegeByTheYears(i) > UpperBound
           DeltaArea = PercentegeByTheYears(i) - UpperBound; % adding the gap so it would be imported
           FoodPercentegeByTheYearsGlobal(i) = FoodPercentegeByTheYearsGlobal(i) + DeltaArea;
        end
    end
end

