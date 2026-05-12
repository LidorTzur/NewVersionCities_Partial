 %function [ElectricityConsumptionTable, TransportationConsumptionTable, VehicleAmountsCell, FoodConsumptionCell, WaterConsumptionCell, ConstructionTable, ConstructionFootprintTable, WateAndRecyclingCell, AmountsOfFuelsCells, OrganicWasteAmount, Data] = ConsumptionChanges(Data, ScenariosTable,Years,pop,orderIndex, varargin)
 function [ElectricityConsumptionTable, TransportationConsumptionTable, VehicleAmountsCell, FoodConsumptionCell, WaterConsumptionCell, WateAndRecyclingCell, AmountsOfFuelsCells, OrganicWasteAmount, Data] = ConsumptionChanges(Data, ScenariosTable,Years,pop,orderIndex, varargin)

%% -------------------------------------------------Variables-------------------------------------------

PerCapitaTransGrowth = 1.075; % Annual growth factor for per-capita VKT based on national historical trends (National Model)

global BaseYear
scenArr = table2array(ScenariosTable); % Convert once to avoid table indexing
popArr = table2array(pop); % Convert population table to array

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

%% -------------------------------------------------Finished Variables-------------------------------------------





%% ---------------------------------- Electricity Consumption
% The model estimates electricity demand for Residential, Commercial, and Industrial sectors.
% While most sectors grow linearly with population, Industry is calculated using a separate 
% industrial growth rate independent of the general population trend.
ElectricityConsumptionTable = Data.Electricity_DataBase.ElectricityConsumptionTable;
% Apply the Grid Loss Ratio to the base year consumption to account for transmission inefficiency
electBase = ElectricityConsumptionTable{:,1} * Data.Electricity_DataBase.ElectricityLossRatio;

% Calculate annual consumption based on the scenario growth vector
electArr = electBase * scenArr(1,:); 

% Update the Industrial sector (Row 3) based on a specific industrial growth projection
IndustryChange = CalculatePercentageLinear(1, Data.Electricity_DataBase.IndustryElectricityConsumptionChange, Years);
if scenArr(1,1) ~= scenArr(1,Years)
    electArr(3,:) = electBase(3) * IndustryChange;
end
ElectricityConsumptionTable{:,:} = electArr;


%% ---------------------------------- Transportation Consumption
% Calculates the total Vehicle Kilometers Traveled (VKT) within the city.
% The model assumes a direct correlation between population growth and the 
% total mileage covered by vehicles to meet urban mobility needs.

TransportationConsumptionTable = Data.Trans_DataBase.TransportationConsumptionTable;
transBase = TransportationConsumptionTable{:,1};
transArr = transBase(1:8) * scenArr(1,:) * PerCapitaTransGrowth; 
TransportationConsumptionTable(1:8, :) = array2table(transArr);
TransportationConsumptionTable{9,:} = sum(transArr, 1); % Total city mileage


%% ---------------------------------- Vehicle Amoount
% Estimates the required number of vehicles (Buses, Cars, Trucks, etc.) to support the city's projected transportation demand.
VehicleAmountsCell = cell(1, Years);
vehBase = table2array(Data.Trans_DataBase.VehicleAmountsCell{1});
vehRowNames = {'Quantity', 'Gasoline', 'Diesel', 'Drive Per Day', 'Drive Per Year', 'Cars Per Year'};
vehColNames = {'Bus','Car','Minibus','Motorcycle', 'Truck', 'LCV'};

for i = 1:Years
    % Update the fleet size and annual usage statistics for each simulation year
    VehicleAmountsCell{i} = array2table(vehBase * scenArr(1,i),'RowNames', vehRowNames, 'VariableNames', vehColNames);
end

%% ---------------------------------- Food Consumption
% assuming perfect corrrelation between population growth and food consumption.
% SHIRI'S UPDATE: adding upper-bound to the growth of local consumption due to area limitation.
% The model tracks food consumption for humans and livestock, distinguishing between 
% locally produced and imported food.
% A cap (UpperBound) is applied to local production due to Israel's limited agricultural land.
Initialization = Data.Food_DataBase.FoodConsumptionCell{1}{:,:};
foodRowNames = Data.Food_DataBase.FoodRowName;
foodColNames = {'Humans and Other - Local','Animals - Local','Humans and Others - Import','Animals - Import'};
OnlyImportedFoodIndex = [2, 8, 45, 46, 47, 55, 57, 58, 62];

UpperBound = Data.Food_DataBase.TotalGrowthForLocalFood;
% Adjust the land-use cap if food-loss prevention scenarios are active
if width(ScenariosTable) == Years
    finalScen5 = scenArr(5, Years);
    if finalScen5 <= 0.8267 && finalScen5 > 0.826, UpperBound = UpperBound * 1.24;
    elseif finalScen5 < 0.7467 && finalScen5 > 0.746, UpperBound = UpperBound * 1.41; end
end

% Distribute consumption between local and global markets based on land availability
FoodPercLocal = CalcFoodPercentegeByTheYearsLocal(ScenariosTable, UpperBound, Years);
FoodPercGlobal = CalcFoodPercentegeByTheYearsGlobal(ScenariosTable, UpperBound, Years);
FoodPercOrig = scenArr(1,:);

for i = 1:Years
    currFood = Initialization .* [FoodPercLocal(i), FoodPercLocal(i), FoodPercGlobal(i), FoodPercGlobal(i)];
    % Items labeled as "Import Only" are not restricted by local land caps
    currFood(OnlyImportedFoodIndex, :) = Initialization(OnlyImportedFoodIndex, :) * FoodPercOrig(i);
    FoodConsumptionCell{i} = array2table(currFood, 'RowNames', foodRowNames, 'VariableNames', foodColNames);
end


%% ---------------------------------- WATER
% Calculates the total urban water balance, including domestic, agricultural, and industrial demand.
% The model integrates multiple supply sources: Natural Drilling, Reclaimed Wastewater, and Desalination.
WDB = Data.Water_DataBase;
WaterConsumptionCell = cell(1, Years);
sectorNames = WDB.WaterConsumptionTableNew.Properties.RowNames;

% Project drilling growth and ecological water requirements (water for nature) over time
waterDataMat = zeros(8, Years);
waterDataMat(5, :) = WDB.WaterConsumptionTableNew{5, 2} * (WDB.Yearly_ChangeDrillingWater .^ (0:Years-1)); % Drilling Water
waterDataMat(7, :) = WDB.WaterConsumptionTableNew{7, 2}; % Brackish water, fresh and non-fresh reservoir water
waterDataMat(4, :) = WDB.WaterConsumptionTableNew{4, 2}; % For Nature

israelPop = popArr(find(strcmpi(pop.Properties.RowNames, 'Israel population')), :);
palestinePop = popArr(find(strcmpi(pop.Properties.RowNames, 'Palestinian Authority population')), :);

for i = 1:Years
    currW = zeros(1, numel(sectorNames));
    % Consumption per sector (Liters per capita multiplied by population)
    currW(1) = israelPop(i) * WDB.Avg_per_capita_domestic; % Domestic & Industrial
    currW(2) = israelPop(i) * (WDB.AgriculturePerCapitaFactor_water * log(i + (BaseYear - WDB.AgricultureBaseYear_water + 1)) + WDB.AgriculturePerCapitaOffset_water);
    currW(3) = palestinePop(i) * WDB.Avg_per_capita_Palestinians; % Neighbors/Palestinians
    currW(4) = waterDataMat(4, i); % For Nature
    currW(5) = waterDataMat(5, i); % Natural Drilling supply
    currW(6) = WDB.ReclaimedRatio * currW(1) * WDB.FreshWaterForDomestic; % Reclaimed WasteWater
    currW(7) = waterDataMat(7, i); % Brackish Water- Fixed to all years
    % Desalinated water is calculated as a "buffer" to meet demand after natural sources are exhausted
    currW(8) = (currW(1)*WDB.FreshWaterForDomestic + currW(2)*WDB.FreshWaterForAgriculture + currW(3)) - currW(5) - currW(7);
    

    WaterConsumptionCell{i} = array2table(currW, 'VariableNames', sectorNames);
end
WDB.WaterConsumptionCell = WaterConsumptionCell;
Data.Water_DataBase = WDB;


%% ---------------------------------- Materials - generated waste and recycling
% Estimates the quantity of municipal solid waste generated by material type (Plastic, Paper, Organic).
% Waste generation is assumed to grow in direct proportion to the city's population.
WasteRowNames = {'Organic Products','Plastic', 'Paper', 'Cardboard', 'Diapers', 'Garden Waste', 'Textile', 'Metal', 'Glass', 'Pruned Trees','Wood', 'Oils', 'Others'};
ColNames = {'Generated Waste', 'Recycling'};

WateAndRecyclingCell = Data.Materials_DataBase.WateAndRecyclingCell;
wasteBase = table2array(WateAndRecyclingCell{1});

for i = 2:Years
    % Update annual waste generation and recycling tables
    WateAndRecyclingCell{i} = array2table(wasteBase * scenArr(1,i), 'RowNames', WasteRowNames, 'VariableNames', ColNames);
end

% Final Data Sync to the main structure
Data.Water_DataBase = WDB;



%% 2. Organic Waste (From food)- % Growth by population

% 2. Organic Waste (From food) - Vectorized Growth by Population
% Extract base data and scenario row once to avoid repeated table access
OrganicWasteAmount = Data.Food_DataBase.OrganicWasteAmountsCell;
baseOrgMatrix = table2array(OrganicWasteAmount{1}); % [1x2] matrix of base values
scenRow1 = table2array(ScenariosTable(1, :)); % Population growth vector

% Pre-fetch metadata to reuse for table creation
RowNames = {'Food - Local Authorities'};
ColNames = OrganicWasteAmount{1}.Properties.VariableNames;

% Perform calculations using matrix multiplication
% This creates a [2 x Years] matrix where each column is the waste for that year
allYearsData = baseOrgMatrix' * scenRow1; 

for i = 2:Years
    % Create the table directly from the pre-calculated slice
    % This is much faster than zeros -> indexing -> assigning
    OrganicWasteAmount{i} = array2table(allYearsData(:, i)', ...
        'RowNames', RowNames, 'VariableNames', ColNames);
end

% Save back to Data structure
Data.Food_DataBase.OrganicWasteAmountsCell = OrganicWasteAmount;

%% 3. -------------------------- NOT RELEVENT IN THE CITY MODEL- CALL ON ZERO 0 ----------------------
% Amounts of Fuels (for industry) - Tons ------ Removed from the City model (Lidor) - values 0
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


%% ---------------------------------- ADJUSTING FOR 2035:
%  REMOVING UNECESSARY COLUMNS FROM THE TABLES:
if (orderIndex >= 7 && width(ScenariosTable) <= Years) 
   ElectricityConsumptionTable = ElectricityConsumptionTable(:, 1:Years);
   TransportationConsumptionTable = TransportationConsumptionTable(:, 1:Years);
   VehicleAmountsCell = VehicleAmountsCell(:, 1:Years);
   FoodConsumptionCell = FoodConsumptionCell(:, 1:Years);
   WaterConsumptionCell = WaterConsumptionCell(:, 1:Years);
   WateAndRecyclingCell = WateAndRecyclingCell(:, 1:Years);
   AmountsOfFuelsCells = AmountsOfFuelsCells(:, 1:Years);
   OrganicWasteAmount =OrganicWasteAmount(:, 1:Years);
end


%% ---------------------------------- Relevent functions --------------------------------------
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


% function [BuiltAreaRes, FloorFootprintRes, CDB] = CalculateAnnualResidentialAreas(CDB, pop, Years, BaseYear)
% % CALCULATEANNUALRESIDENTIALAREAS calculates the cumulative built area and floor footprint
% % for residential sectors using optimized matrix operations.
% 
%     BuiltAreaRes = zeros(2, Years); 
%     FloorFootprintRes = zeros(2, Years); 
% 
%     % 1. Vectorized Area Per Capita Calculation
%     % Instead of a loop with if/else, we calculate the growth years and cap them.
%     areaPerCapita = zeros(1, Years);
%     baseArea = CDB.Built_up_area_per_capita;
%     growthRate = CDB.Annual_area_per_capita_growth_rate;
% 
%     % Years until the urban plan cap is reached
%     yearsOfGrowth = CDB.UrbanPlan_Year - BaseYear;
%     growthVector = (0:Years-1) * growthRate;
% 
%     % Cap the growth at the plan year
%     if yearsOfGrowth < Years && yearsOfGrowth >= 0
%         growthVector(yearsOfGrowth + 1 : end) = yearsOfGrowth * growthRate;
%     end 
% 
%     areaPerCapita = baseArea + growthVector;
%     CDB.AreaPerCapitaVector = areaPerCapita;
% 
%     % 2. Population Vector (Direct numeric access)
%     % Converting population table to array once
%     PopulationVector = table2array(pop(3, 1:Years));
% 
%     % 3. Pre-extract coefficients to avoid table access inside the loop
%     % We extract the values from the Cell Arrays into 2xYears matrices
%     distMatrix = zeros(2, Years);
%     footprintRatioMatrix = zeros(2, Years);
% 
%     % Building Distribution & Footprint Ratios
%     for i = 1:Years
%         % Extract Distribution
%         if i <= length(CDB.Building_Type_Distribution_Cell)
%             dTable = CDB.Building_Type_Distribution_Cell{i};
%         else
%             dTable = CDB.Building_Type_Distribution_Cell{1};
%         end
%         % Use numeric indexing if possible, or table2array
%         distMatrix(:, i) = table2array(dTable(1, 1:2));
% 
%         % Extract Footprint Ratios
%         if i <= length(CDB.Precent_Floor_Footprint_Cell)
%             fTable = CDB.Precent_Floor_Footprint_Cell{i};
%         else
%             fTable = CDB.Precent_Floor_Footprint_Cell{1};
%         end
%         footprintRatioMatrix(:, i) = table2array(fTable(1, 1:2));
%     end
% 
%     % 4. Final Matrix Calculation (Full Vectorization)
%     % Total cumulative area = Population * AreaPerCapita * 1,000,000
%     TotalAreaMatrix = PopulationVector .* areaPerCapita .* 1000000;
% 
%     % High-Density (Row 1) and Low-Density (Row 2)
%     BuiltAreaRes = TotalAreaMatrix .* distMatrix;
% 
%     % Footprint = Built Area * Ratio
%     FloorFootprintRes = BuiltAreaRes .* footprintRatioMatrix;
% end



function [BuiltAreaRes_Delta, FloorFootprintRes_Delta, CDB] = CalculateAnnualResidentialAreas(CDB, pop, Years, BaseYear)
% CALCULATEANNUALRESIDENTIALAREAS calculates the annual NEW built area and floor footprint
% for residential sectors using a delta-based allocation to ensure mass balance.

    % Output matrices for annual delta (new construction only)
    BuiltAreaRes_Delta = zeros(2, Years); 
    FloorFootprintRes_Delta = zeros(2, Years); 
    
    % 1. Calculate Area per Capita Vector (Restoring the missing logic)
    areaPerCapita = zeros(1, Years);
    baseArea = CDB.Built_up_area_per_capita;
    growthRate = CDB.Annual_area_per_capita_growth_rate;
    yearsOfGrowth = CDB.UrbanPlan_Year - BaseYear;
    growthVector = (0:Years-1) * growthRate;
    
    if yearsOfGrowth < Years && yearsOfGrowth >= 0
        growthVector(yearsOfGrowth + 1 : end) = yearsOfGrowth * growthRate;
    end 
    areaPerCapita = baseArea + growthVector;
    CDB.AreaPerCapitaVector = areaPerCapita; % Sync back to CDB
    
    % 2. Population and Stock Constants
    PopulationVector = table2array(pop(3, 1:Years));
    
    % 3. Extract Scenario Distribution and Footprint Ratios
    distMatrix = zeros(2, Years);
    footprintRatioMatrix = zeros(2, Years);
    
    for i = 1:Years
        % Extract Distribution
        if i <= length(CDB.Building_Type_Distribution_Cell)
            dTable = CDB.Building_Type_Distribution_Cell{i};
        else
            dTable = CDB.Building_Type_Distribution_Cell{1};
        end
        distMatrix(:, i) = table2array(dTable(1, 1:2));
        
        % Extract Footprint Ratios
        if i <= length(CDB.Precent_Floor_Footprint_Cell)
            fTable = CDB.Precent_Floor_Footprint_Cell{i};
        else
            fTable = CDB.Precent_Floor_Footprint_Cell{1};
        end
        footprintRatioMatrix(:, i) = table2array(fTable(1, 1:2));
    end
    
    % 4. Calculate Annual Construction Delta and Allocate
    for i = 1:Years
        % Total residential stock required for the current year
        TotalStock_i = PopulationVector(i) * areaPerCapita(i) * 1000000;
        
        if i == 1
            % Base Year: Use the delta of the second year to represent 2019 growth
            % as per your methodology.
            TotalStock_next = PopulationVector(i+1) * areaPerCapita(i+1) * 1000000;
            Annual_Total_New_Area = max(0, TotalStock_next - TotalStock_i);
        else
            TotalStock_prev = PopulationVector(i-1) * areaPerCapita(i-1) * 1000000;
            Annual_Total_New_Area = max(0, TotalStock_i - TotalStock_prev);
        end
        
        % Allocate the Annual Delta based on the scenario of that year
        BuiltAreaRes_Delta(1, i) = Annual_Total_New_Area * distMatrix(1, i);     % High-Density
        BuiltAreaRes_Delta(2, i) = Annual_Total_New_Area * (1 - distMatrix(1, i)); % Low-Density
        
        % Calculate Footprint for the delta
        FloorFootprintRes_Delta(1, i) = BuiltAreaRes_Delta(1, i) * footprintRatioMatrix(1, i);
        FloorFootprintRes_Delta(2, i) = BuiltAreaRes_Delta(2, i) * footprintRatioMatrix(2, i);
    end
end