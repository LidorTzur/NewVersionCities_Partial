function [EmissionsByYears,ConsumptionAmounts, Resources, WaterFromFoodCell, Data1] = FullScenario(Data,ScenariosTable,Years,pop,orderIndex, index, varargin)

%% ------------------------------------------ COMPARE -------------------
%% Handle optional comparison input
if nargin > 6
    WaterFromFood_BAU = varargin{1};
else
    WaterFromFood_BAU = [];
end

%% ----------------------------------------- Preperations

RidesPerDay = Data.Trans_DataBase.RidesPerDay;
Days_In_Year = Data.Days_In_Year;
global BaseYear
addpath("CalcFunctions");

% !!! אופטימיזציה: המרת ScenariosTable למערך מראש כדי למנוע גישה איטית לטבלה בכל איטרציה
scenArr = table2array(ScenariosTable);

%% Initialize the Results calculated data-base
% Initialize the row names
Emission_RowNames = {'Food (Ton ECo2)', 'Electricity - Direct (Ton ECo2)', 'Electricity - Indirect (Ton ECo2)', 'Transportation - Direct (Ton ECo2)', 'Train Emissions (Ton ECo2)','Transportation - Indirect (Ton ECo2)', 'Construction (Ton ECo2)', 'Consumption Emissions' ,'Fuel for Industry (Ton ECo2)', 'Sewege Treatment', 'Solid Waste (Ton ECo2)'}; %, 'Water from food'
consumption_RowNames = {'Water (10^6*m^3)', 'Fuels For Electriciy Manufacturing (Ton)', 'Fuels For Transportation Amounts (Ton)', 'Materials For Construction (Ton)', 'Fuels For Energy Industry (Ton)'};
Resources_RowNames = {'Area For Electricity (Km^2)', 'Cumulative Area For Electricity (Km^2)','Area For Food (Km^2)', 'Operating Costs', 'Setting Costs', 'Fuels Costs', 'Cost Of Area For PV', 'Area For Construction (Km^2)', 'Cumulative Area For Construction (Km^2)'};

% Initialize the final tables
EmissionsByYears = cell(numel(Emission_RowNames),Years);  % Initialize the emissions table for each year
ConsumptionAmounts = cell(numel(consumption_RowNames),Years); % Initialize the consumption table for each year
Resources = cell(numel(Resources_RowNames), Years);  % Initialize the resources table for each year

%% Inputs
% Fuel for energy in the industry & others
FuelConsumption_RowNames = Data.Materials_DataBase.FuelConsumption_RowNames;
FuelConsumption_ColNames = Data.Materials_DataBase.FuelConsumption_ColNames;
BusCarRatio_global = Data.Trans_DataBase.BusCarRatio;
TrainCarRatio = Data.Trans_DataBase.TrainCarRatio;

% Electricity_Emissions 
ElectricityBySources_row_names = Data.Electricity_DataBase.ElectricityBySources_row_names;
ElectricityBySources = array2table(zeros(numel(ElectricityBySources_row_names),Years));
ElectricityBySources.Properties.RowNames = ElectricityBySources_row_names;

% Renewable Sources Electricity table
Renewable_Electricity_row_names = Data.Electricity_DataBase.Renewable_Electricity_row_names;

% Electricity Fuels coeff
Crude_Oil_To_Electricity = Data.Electricity_DataBase.Crude_Oil_To_Electricity; % Crude oil to electricity - Needs to understand where it is came from
fuel_MTOE_coeff = Data.Electricity_DataBase.fuel_MTOE_coeff;
fuel_LPG_coeff = Data.Electricity_DataBase.fuel_LPG_coeff;

% food
meatRows = Data.Food_DataBase.meatRows;

%% Extracting Scenario Vectors 
ChangeInElectricityConsumptionPercentage = scenArr(2,:);
ReducingBeefConsumptionPercentage = scenArr(4,:);
PreventingFoodLoss = scenArr(5,:);
IncreaseInEnergyConsumptionFromRenewableEnergiesPercentage = scenArr(6,:);
IncreaseInEnergyConsumptionFromNaturalGasPercentage  = scenArr(7,:);
ElectricitySavingPercentage = scenArr(8,:);
FuelForEnergyPercentage = scenArr(9,:); % !!! הוספתי בחזרה לשימוש
RecycleWaste = scenArr(10,:);
BurningWaste = scenArr(11,:);
ReductionOfMileage = scenArr(12,:);
TransitionToPublicTransportationPercentage = scenArr(13,:);
TransitionToElectricCar = scenArr(14,:);
TransitionToElectricVan = scenArr(15,:);
TransitionToElectricTruck = scenArr(16,:);
TransitionToElectricBus = scenArr(17,:);
WaterSaving = scenArr(19,:);
ReducingMeatConsumptionPercentage = scenArr(20,:);
ChangeInGreenMaterials = scenArr(24,:);
ChangeInBuildingMixRatio = scenArr(21,:); 
ChangeInFloorPrintHighDensity = scenArr(22,:); 
ChangeInFloorPrintLowDensity = scenArr(23,:); 
ChangeInFloorsNumber = scenArr(25:33,:);
% All the Construction is apllied at the ConsumptionChanges Sheet (Lidor's application)

%% ----------------------------------------- Calculate Base Consumptions (No scenario)
% Calculate the base consumption data based on population growth
%[ElectricityConsumptionTable, TransportationConsumptionTable, VehicleAmountsCell, FoodConsumptionCell, WaterConsumptionCell, ConstructionTable, ConstructionFootprintTable ,WasteAndRecyclingCell,AmountsOfFuelsCells, OrganicWasteCell, Data1] = ConsumptionChanges(Data,ScenariosTable, Years, pop, orderIndex);
[ElectricityConsumptionTable, TransportationConsumptionTable, VehicleAmountsCell, FoodConsumptionCell, WaterConsumptionCell,WasteAndRecyclingCell,AmountsOfFuelsCells, OrganicWasteCell, Data1] = ConsumptionChanges(Data,ScenariosTable, Years, pop, orderIndex);

%% ----------------------------------------- Create the years column names (based on the years)
YearsStringsForColNames = cell(1,Years);
for i=1:Years
    s1 = num2str(i+BaseYear-1); % changed
    YearsStringsForColNames{i} = s1;
end

%% ----------------------------------------- Fuels Consumption and Emissions
% Loop over each year and calculate the fuel consumption and emissions For industry Fuels (Materials)
temp_row_num = find(strcmpi(consumption_RowNames, 'Fuels For Energy Industry (Ton)'));
temp_row_num_2 = find(strcmpi(Emission_RowNames, 'Fuel for Industry (Ton ECo2)'));

for i=1:Years 
   currentFuelTable = AmountsOfFuelsCells{1,i}(4:6,:);
   ConsumptionAmounts{temp_row_num,i} = currentFuelTable;
   emData = table2array(currentFuelTable);
   emData(1,:) = emData(1,:) * fuel_MTOE_coeff; % 2.5 industry
   emData(2:3,:) = emData(2:3,:) * FuelForEnergyPercentage(i) * fuel_LPG_coeff; % 2.9 home & commercial
   EmissionsByYears{temp_row_num_2,i} = array2table(emData, 'RowNames', FuelConsumption_RowNames, 'VariableNames', FuelConsumption_ColNames);
end

%% ----------------------------------------- Food Emissions and Consumption (food and water) 
% Reducing beef consumption -- scenario 4
% When reducing beef consumption, we considered a replacement by other food products.
% the calories will be divided equally among the legumes (bean, chickpea, lentil, broad bean and green pea).
% including scenario of vegetarian population:

meatRows = Data.Food_DataBase.meatRows;
Beef_row = 52;
plantRows = 10:14; % That true i checked (Lidor)
WaterFromFoodCell = cell(1,Years); % Initialize water from food table
CaloricCompletion = ones(1,Years) + (1-(ReducingBeefConsumptionPercentage))/5 + (1-(ReducingMeatConsumptionPercentage))/5;

% Food loss -- - scenario 5
for i = 1:Years
    CurrentFoodConsumption = FoodConsumptionCell{i};
    foodArr = table2array(CurrentFoodConsumption);

    if (index == 4 || (index == 5 && orderIndex == 2)) || (orderIndex ~= 2)
        % !!! חישוב וקטורי מהיר
        foodArr(Beef_row, [1,3]) = foodArr(Beef_row, [1,3]) * ReducingBeefConsumptionPercentage(i);
        foodArr(meatRows, [1,3]) = foodArr(meatRows, [1,3]) * ReducingMeatConsumptionPercentage(i);
        foodArr(plantRows, [1,3]) = foodArr(plantRows, [1,3]) * CaloricCompletion(i);
        foodArr = foodArr * PreventingFoodLoss(i);
    end

    % החזרה לטבלה רק בסיום החישובים
    CurrentFoodConsumption{:,:} = foodArr;

    % Calculate water consumption based on the updated food consumption data (m^3)
    WaterFromFoodCell{i} = CalcWaterForFoodConsumption(Data, CurrentFoodConsumption); 

    % ------------------------------------- COMPARE ---------------------
    % >>> BAU COMPARISON: Adjust WaterConsumptionCell based on gap from BAU <<<
    % Because we have 'prevent food loss' in the scenario table for Moderate and Advanced, so we take the diff form the BAU
       % Here we reduces the water saved from food (which is agriculture
       % water in the water model, so that we will show emission savings
       % from this scenario in water too. we take tha gap off from the
       % desilinated water- because it answers to a lack of water for it.

   if nargin > 6 && ~isempty(varargin{1})
        gap = (sum(varargin{1}{i}{1,1:2}) - sum(WaterFromFoodCell{i}{1,1:2})) / 10^6;
        WaterConsumptionCell{i}{1,8} = WaterConsumptionCell{i}{1,8} - gap;
   end

    % Compute emissions from food consumption based on the updated values
    EmissionsByYears{1,i} = CalcCo2eFromFoodConsumption(Data, CurrentFoodConsumption, OrganicWasteCell{i}); % Store the emissions in the corresponding year   
    FoodConsumptionCell{i} = CurrentFoodConsumption; % Update the food consumption table after applying the modifications
end


%% ----------------------------------------- Water
% ---------------------------- Lidor: MATCHED TO DOR'S MODEL: 

% Water Emissions (from sewege)


for i = 1:Years

    % water saving - scenario 19
    waterArr = table2array(WaterConsumptionCell{i});
    waterArr(:, 1:4) = waterArr(:, 1:4) * WaterSaving(i);
    
    % ReCalculate Reclaimed WasteWater
    waterArr(:, 6) = Data.Water_DataBase.ReclaimedRatio * waterArr(:, 1); 
    % ReCalculate Desilinated Water
    waterArr(:, 8) = (waterArr(:, 1)* Data.Water_DataBase.FreshWaterForDomestic + waterArr(:, 2)* Data.Water_DataBase.FreshWaterForAgriculture + waterArr(:, 3) + waterArr(:, 4)) - waterArr(:, 5);
    waterArr(:, 8) = max(waterArr(:, 8), 0);

    WaterConsumptionCell{i}{:,:} = waterArr;

    EmissionsByYears{10,i} = CalcSewegeEmissions(Data, WaterConsumptionCell{i});

    sumWater = sum(waterArr, 1);

    ConsumptionAmounts{1,i} = array2table(waterArr, 'VariableNames', WaterConsumptionCell{i}.Properties.VariableNames);

end



%% ----------------------------------------- Transportation - Downstream

% change in mileage - scenario 12
transArr = table2array(TransportationConsumptionTable);
transArr = transArr .* ReductionOfMileage;

% KM from car to bus and train (percentages) - scenario 13
PercentageToBuses  = Data.Trans_DataBase.TransitionToBus;
PercentageToTrains = Data.Trans_DataBase.TransitionToTrain;

for i = 2:Years
    KmDroppedFromCars = transArr(2,i) * (1 - TransitionToPublicTransportationPercentage(i));
    transArr(2,i) = transArr(2,i) * TransitionToPublicTransportationPercentage(i);
    
    transArr(1,i) = transArr(1,i) + (KmDroppedFromCars * PercentageToBuses * BusCarRatio_global);
    transArr(7,i) = transArr(7,i) + (KmDroppedFromCars * PercentageToTrains * TrainCarRatio);
end

% Transition to EV - consider the electricity and emission from it (Lidor)
ElectricityCoeffs = table2array(Data.Electricity_DataBase.ElectricityConsumptionEmissionsInTransportation);
KWH_EV_Matrix = zeros(4, Years); % לאיסוף צריכת החשמל
KMTraveledByElectricCar = zeros(1,Years);

for i = 1:Years
    [KMTraveledByElectricCar(i), transArr(2,i)] = CalcTransitionToEV(transArr(2,i), TransitionToElectricCar(i));
    [kmVan,   transArr(6,i)] = CalcTransitionToEV(transArr(6,i), TransitionToElectricVan(i));
    [kmTruck, transArr(5,i)] = CalcTransitionToEV(transArr(5,i), TransitionToElectricTruck(i));
    [kmBus,   transArr(1,i)] = CalcTransitionToEV(transArr(1,i), TransitionToElectricBus(i));
    
    currentKMs = [KMTraveledByElectricCar(i); kmVan; kmTruck; kmBus];
    KWH_EV_Matrix(:,i) = currentKMs .* ElectricityCoeffs(:, i);
end

% פירוק לוקטורים לצורך המשך הקוד (אם צריך אותם בנפרד)
KWHForElectricCar   = KWH_EV_Matrix(1,:);
KWHForElectricVan   = KWH_EV_Matrix(2,:);
KWHForElectricTruck = KWH_EV_Matrix(3,:);
KWHForElectricBus   = KWH_EV_Matrix(4,:);

% !!! החזרת הערכים המחושבים לטבלה המקורית פעם אחת בסוף
TransportationConsumptionTable{:,:} = transArr;

% 4. עדכון כמויות רכבים ופליטות
VehicleAmountsCell = CalulateChangeInVehicleAmountsTransitionToPublicTransport(TransportationConsumptionTable, VehicleAmountsCell, Data, Years, RidesPerDay, Days_In_Year);
VehicleAmountsCell = ChangesInVehicelAmountsAfterElectricVehicels(TransportationConsumptionTable, VehicleAmountsCell, Data, Years, RidesPerDay, Days_In_Year);

for i = 1:Years
    CurrentTransportatiionConsumtpion = transArr(:,i);
    CurrentVehicleAmount = table2array(VehicleAmountsCell{i});
    
    [EmissionsByYears{4,i}, EmissionsByYears{5,i}] = CalcTransportationConsumption(Data, CurrentTransportatiionConsumtpion, CurrentVehicleAmount);
    [EmissionsByYears{6,i}, ConsumptionAmounts{3,i}] = CalcTransportationManufacturing(Data, CurrentTransportatiionConsumtpion, CurrentVehicleAmount, KMTraveledByElectricCar(i), Data.Trans_DataBase.VehicleAmountsCell(1:i));
end


%% ----------------------------------------- Electricity - Consumption

electArr = table2array(ElectricityConsumptionTable);

industryOriginal = electArr(3,:); % Store original Industry values (Row 3) which aren't affected by per-capita changes

% 1. Per-Capita Consumption (Scen 2) and Electricity Saving (Scen 8)
% The .* operator handles the column-wise multiplication perfectly.
electArr = electArr .* ChangeInElectricityConsumptionPercentage .* ElectricitySavingPercentage;

% 2. Restore Industry values (only applying the Saving percentage)
electArr(3,:) = industryOriginal .* ElectricitySavingPercentage; 

% 3. Add EV Electricity consumption to Row 5
electArr(5,:) = KWHForElectricCar + KWHForElectricVan + KWHForElectricTruck + KWHForElectricBus;

% 4. Write back to Table once
ElectricityConsumptionTable{:,:} = electArr;

% --- Global Calculations (Keep outside heavy loops) ---
InitialPercentage = Data.Electricity_DataBase.InitialPercentage;

PercentageOfElectricitySourcesByYears = CalculatePercentageOfElectricitySourcesByYears(...
    IncreaseInEnergyConsumptionFromRenewableEnergiesPercentage,IncreaseInEnergyConsumptionFromNaturalGasPercentage, InitialPercentage);

% Electricity from Water calculation
ElectricityFromWaterCell = CalculateElectricityFromWaterAllYears(Data, WaterConsumptionCell, Years);

% Final sync for specific rows
for i = 1:Years
    ElectricityConsumptionTable{6,i} = ElectricityFromWaterCell{i}{6,1};
end


%% ----------------------------------------- construction waste
% Get Base Year Values (2019)
BaseDistTable = Data.Const_DataBase.Building_Type_Distribution_Cell{1}; 
BaseFootprintTable = Data.Const_DataBase.Precent_Floor_Footprint_Cell{1}; 
BaseFloorsTable = table2array(Data.Const_DataBase.ConstructionFloorsTable(:,1));

% Pre-calculate the scalars to avoid table indexing inside the loop
baseHD = BaseDistTable{1, 1};
baseHighFoot = BaseFootprintTable{1, 1};
baseLowFoot = BaseFootprintTable{1, 2};

% 1. Optimized Scenario Application (Building Mix, Footprint, and Floors)
% Instead of creating new tables in each iteration, we update the data structures efficiently.
for i = 1:Years
    % --- Update Building Type Distribution ---
    currHD = min(baseHD + ChangeInBuildingMixRatio(i), 1.0);
    newDist = BaseDistTable; % Copy structure once
    newDist{1, 1} = currHD;
    newDist{1, 2} = 1 - currHD;
    Data.Const_DataBase.Building_Type_Distribution_Cell{i} = newDist;

    % --- Update Floor Print Distribution ---
    newFoot = BaseFootprintTable;
    newFoot{1, 1} = min(baseHighFoot + ChangeInFloorPrintHighDensity(i), 1.0);
    newFoot{1, 2} = min(baseLowFoot + ChangeInFloorPrintLowDensity(i), 1.0);
    Data.Const_DataBase.Precent_Floor_Footprint_Cell{i} = newFoot;

    % --- Update Floors Number ---
    % Vectorized multiplication for all sectors in the current year
    Data.Const_DataBase.ConstructionFloorsTable{:,i} = BaseFloorsTable * ChangeInFloorsNumber(i);
end

% 2. Accumulative Residential Calculations
CDB = Data.Const_DataBase;
[BuiltAreaRes_Acc, FloorFootprintRes_Acc, CDB] = CalculateAnnualResidentialAreas(CDB, pop, Years, BaseYear); 
Data.Const_DataBase = CDB;

% 3. Optimized Delta Calculations (New Construction per Year)
ConstructionTable = Data.Const_DataBase.ConstructionTable;
ConstructionFootprintTable = Data.Const_DataBase.ConstructionFootprintTable;
ConstructionFloorsTable = Data.Const_DataBase.ConstructionFloorsTable;

consArr = table2array(ConstructionTable);
footArr = table2array(ConstructionFootprintTable);
floorArr = table2array(ConstructionFloorsTable);

consInit9 = consArr(1:9, 1);
numRowsCons = size(consArr, 1) - 1;
numRowsFoot = size(footArr, 1) - 1;

% --- Non-Residential Sectors (Rows 1-9) ---
for i = 2:Years

    % Total area required up to year i
    totalNonResArea = scenArr(1,i) * consInit9;
    consArr(1:9, i) = totalNonResArea - sum(consArr(1:9, 1:i-1), 2); % Delta = (Today's Total) - (Sum of everything built until yesterday)

    % FootPrint area required up to year i
    currentFloors = floorArr(1:9, i); % Footprint Delta
    currentFloors(currentFloors == 0) = 1; % Avoid division by zero
    totalNonResFoot = totalNonResArea ./ currentFloors;
    footArr(1:9, i) = totalNonResFoot - sum(footArr(1:9, 1:i-1), 2);

    % Since BuiltAreaRes_Acc and FloorFootprintRes_Acc now represent the DELTA directly:
    consArr(10:11, i) = BuiltAreaRes_Acc(:, i); 
    footArr(10:11, i) = FloorFootprintRes_Acc(:, i);

    % --- Update Totals ---
    consArr(numRowsCons+1, i) = sum(consArr(1:numRowsCons, i));
    footArr(numRowsFoot+1, i) = sum(footArr(1:numRowsFoot, i));

end

% 4. Final Processing & Table Sync

% Remove negative values and sync base year (2019) to 2020
consArr = max(consArr, 0);
footArr = max(footArr, 0);

consArr(:, 1) = consArr(:, 2);
footArr(:, 1) = footArr(:, 2);

% Assign the optimized arrays back to the original Tables at once
ConstructionTable{:, :} = consArr;
ConstructionFootprintTable{:, :} = footArr;

% Save final results
Data.ConstructionTable = ConstructionTable;
Data.ConstructionFootprintTable = ConstructionFootprintTable;

% 4. Scenario Green Materials

BaseEmissionMaterials = Data.Const_DataBase.ConstructionECO2Coefficients_ByMaterial{1}; %Convert Base Table/Struct to Array once before the loop
Saving_Green_Cement = Data.Const_DataBase.Saving_Green_Cement;

if istable(BaseEmissionMaterials)
    BaseEM_Arr = table2array(BaseEmissionMaterials); 
else
    BaseEM_Arr = BaseEmissionMaterials; % It's already an array
end

% Ensure Saving_Green_Cement is an array and transpose it
Saving_Green_Cement = Data.Const_DataBase.Saving_Green_Cement;
if istable(Saving_Green_Cement)
    SavingCement_Arr = table2array(Saving_Green_Cement)'; 
else
    SavingCement_Arr = Saving_Green_Cement'; % Transpose once
end

% Calculate Emissions from construction
for i = 1:Years
    % !!! Accessing array directly instead of table indexing
    currConst = ConstructionTable{:,i};
    currFootprint = ConstructionFootprintTable{:, i};
    
    % --- Update Materials Emission by Green Transition (Scenario 24) ---
    % We use the pre-converted BaseEM_Arr
    currentFactor = (ChangeInGreenMaterials(i) - 1);
    NewEmissionMaterial = BaseEM_Arr - (BaseEM_Arr .* SavingCement_Arr * currentFactor);
    
    % Emissions construction
    [ConsumptionAmounts{4,i}, EmissionsByYears{7,i}] = CalcConstruction(Data1, currConst, currFootprint, NewEmissionMaterial, ChangeInGreenMaterials(i));
end

% Clean up: Fix the base year values after the loop (only once)
if Years >= 2
    ConsumptionAmounts{4,1} = ConsumptionAmounts{4,2};
    EmissionsByYears{7,1} = EmissionsByYears{7,2};
end

%% ----------------------------------------- Materials Waste

% !!! OPTIMIZATION: Extract base percentage and pre-allocate arrays
BaseRecyclePerc = table2array(Data.Materials_DataBase.ExportWasteForRecyclingPercentage{1});
colNames = Data.Materials_DataBase.ExportWasteForRecyclingPercentage{1}.Properties.VariableNames;
colNames = WasteAndRecyclingCell{1}.Properties.RowNames;
WasteInciniration = zeros(1, Years);

total_Waste_Base = sum(WasteAndRecyclingCell{1}{:, 1}, 'omitnan');
total_Recycle_Base = sum(WasteAndRecyclingCell{1}{:, 2}, 'omitnan');

% Base Percentagr Recycle
if total_Waste_Base > 0
    Base_Overall_Rate = (total_Recycle_Base / total_Waste_Base); 
else
    Base_Overall_Rate = 0;
end

% חישוב משקלים יחסיים של החומרים משנה 1
current_material_recycle_base = WasteAndRecyclingCell{1}{:, 2};
sum_recycle_base = sum(current_material_recycle_base, 'omitnan');
if sum_recycle_base > 0
    material_weights = current_material_recycle_base / sum_recycle_base;
else
    material_weights = ones(size(current_material_recycle_base)) / length(current_material_recycle_base);
end

for i = 1:Years
    if i == 1
        CurrentRecycleShare = BaseRecyclePerc;
    else
        % 1. יעד המיחזור לשנה i
        target_overall_rate = Base_Overall_Rate * RecycleWaste(i);
        
        % 2. סך הפסולת בשנה הנוכחית
        total_Waste_Curr = sum(WasteAndRecyclingCell{i}{:, 1}, 'omitnan');
        total_required_recycle_weight = total_Waste_Curr * target_overall_rate;
        
        % 3. פיזור לפי משקלי הבסיס
        new_material_recycle = material_weights * total_required_recycle_weight;
        
        % 4. חישוב אחוז המיחזור (כעמודה)
        total_material_per_row = WasteAndRecyclingCell{i}{:, 1};
        CurrentRecycleShare = new_material_recycle ./ total_material_per_row;
        
        % ניקוי חריגות
        CurrentRecycleShare(total_material_per_row == 0) = 0;
        CurrentRecycleShare = min(1, CurrentRecycleShare);

        %CurrentRecycleShare = min(1, BaseRecyclePerc .* (RecycleWaste(i)));
    end
    
    % וידוא שזה וקטור עמודה (Column Vector)
    CurrentRecycleShare = CurrentRecycleShare(:); 
 
    
    % יצירת הטבלה
    Data1.Materials_DataBase.ExportWasteForRecyclingPercentage{i} = array2table(CurrentRecycleShare, ...
        'VariableNames', {'RecyclingPercentage'}, 'RowNames', colNames);
    
    % B. Process Waste Data
    CurrentWasteTable = WasteAndRecyclingCell{i};
    wasteArr = table2array(CurrentWasteTable);
    
    TotalWaste = wasteArr(:,1);
    
    if i == 1
        % Base year logic
        NewRecycled = wasteArr(:,2);
        NewBurial   = max(0, TotalWaste - NewRecycled);
    else
        % Scenario logic
        NewRecycled = TotalWaste .* CurrentRecycleShare;
        NewBurial   = max(0, TotalWaste - NewRecycled);
    end
    
    % C. Burning Waste Logic (Scenario 11)
    BurialBeforeBurning = NewBurial;
    NewBurialAfterBurning = BurialBeforeBurning - (BurialBeforeBurning .* (BurningWaste(i) - 1));
    WasteInciniration(i) = sum(BurialBeforeBurning - NewBurialAfterBurning);
    
    % D. Final Array Sync
    wasteArr(:,1) = NewBurialAfterBurning;
    wasteArr(:,2) = NewRecycled;
    
    % E. Update Tables & Emissions
    CurrentWasteTable{:,:} = wasteArr; % Update table only once
    WasteAndRecyclingCell{i} = CurrentWasteTable;
    Data1.Materials_DataBase.WasteAndRecyclingCell{i} = CurrentWasteTable;
    
    % F. Solid Waste Emissions (Scenario 3)
    EmissionsByYears{11,i} = CalcMaterialEmissions(Data, CurrentWasteTable);
end


%% ----------------------------------------- Electricity emissions

electConsArr = table2array(ElectricityConsumptionTable); % VECTOR, Main consumption matrix
DrillingWaterCoeff = Data.Water_DataBase.Electricity_Drillind_Water_Coeff;
Scen9_Vec = ScenariosTable{9,:}; % Prepare ScenariosTable row 9 as a vector

% Initialize variables for incremental logic
PreviousYearElectricity = electConsArr(:,1) * 0; 
addKWHfromFuels_Mat = zeros(3, Years); 

% Pre-calculate base fuel sums 
BaseFuelSum_4 = sum(AmountsOfFuelsCells{1,1}{4,:});

for i = 1:Years
    % 1. Calculate Electricity from Industry Fuels
    if (i >= 2 && orderIndex ~= 7 && orderIndex ~= 8)
        currFuel4 = sum(AmountsOfFuelsCells{1,i}{4,:}); % Conversion of the amount of fuels to electricity in the case of industrial fuels
        currFuel5 = sum(AmountsOfFuelsCells{1,i}{5,:}); % Conversion of the amount of fuel to electricity in the case of home LPG
        currFuel6 = sum(AmountsOfFuelsCells{1,i}{6,:}); % Conversion of the amount of fuel to electricity in the case of Commercial LPG
        
        % Calculate fuel-to-electricity deltas
        addKWHfromFuels_Mat(1,i) = (BaseFuelSum_4 - currFuel4) * Crude_Oil_To_Electricity;
        addKWHfromFuels_Mat(2,i) = (currFuel5 - currFuel5 * Scen9_Vec(i)) * Crude_Oil_To_Electricity;
        addKWHfromFuels_Mat(3,i) = (currFuel6 - currFuel6 * Scen9_Vec(i)) * Crude_Oil_To_Electricity;
        
        % ----------------------- BAU Comparison Logic -----------------------
        % >>> Adding to the electricity from the basic scenario 
        % the diff of the electricy in the new scenario that are used for energy
        % Because in the BAU scenario the crude oil for energy rises by 0% from the base year
        % Add electricity from fuels if BAU comparison is on
        if ~isempty(WaterFromFood_BAU)
            electConsArr(1,i) = electConsArr(1,i) + addKWHfromFuels_Mat(2,i);
            electConsArr(2,i) = electConsArr(2,i) + addKWHfromFuels_Mat(3,i);
            electConsArr(3,i) = electConsArr(3,i) + addKWHfromFuels_Mat(1,i);
        end
    end
    
    % 2. Integration with Water & Food
    % The amount of water for global food per cubic meter is twice the electricity coefficients for global water in KWH per cubic meter.
    currentTotalWaterElect = ElectricityFromWaterCell{i}{6,1};

    electConsArr(6,i) = currentTotalWaterElect;

    % Calculate electricity for drilling/transporting fresh water (from food cell)
    foodWaterArr = table2array(WaterFromFoodCell{1,i});
    electConsArr(7,i) = sum(foodWaterArr(1, 3:4)) * DrillingWaterCoeff;

    % 3. Core Calculations: Consumption & Manufacturing
    % !!! Pass the current YEAR vector from our fast Matrix
    CurrentYearVec = electConsArr(:,i);

    % Run model functions
    [EmissionsByYears{2,i}, ElectricityBySources{1:6,i}] = CalcElectricityConsumption(Data, CurrentYearVec, PercentageOfElectricitySourcesByYears{:,i}, WasteInciniration(i), i);
    % Shiri's Adjustments: allowing changes in PV emissions - sending the function the consumption of the prev year in order to find the delta,and the year (i) so we can calculate the current emissions
    [EmissionsByYears{3,i}, ConsumptionAmounts{2,i}] = CalcElectricityManufacturing(Data, CurrentYearVec, PreviousYearElectricity, PercentageOfElectricitySourcesByYears{:,:}, i);
    
    % 4. Summary Row Logic- Vectorized sum for the sources table
    srcMat = ElectricityBySources{1:6,i};
    ElectricityBySources{numel(ElectricityBySources_row_names), i} = sum(srcMat);
    
    % Update for next iteration
    PreviousYearElectricity = CurrentYearVec; 
end

% !!! Final Sync: Update the original Table one last time
ElectricityConsumptionTable{:,:} = electConsArr;
% Sync the addKWHfromFuels back if needed as a table
addKWHfromFuels = array2table(addKWHfromFuels_Mat);



%% ----------------------------------------- Area

% 1. Electricity Sector - Installed Capacity (KW)
% This section calculates the required installed capacity for each energy source 
% based on the total electricity consumption and the specific grid mix.
Renewable_Electricity_row_num = numel(Renewable_Electricity_row_names);
KWForElectricity_Mat = zeros(Renewable_Electricity_row_num, Years);
RenewablePercents_Vec = Data.Area_DataBase.RenewablePercents{1,:};
KWToKwh_Coeff = Data.Area_DataBase.KWToKwh;

for i = 1:Years
    % Retrieve electricity consumption generated by each source for current year
    currentElectSources = ElectricityBySources{1:3,i}; 
    
    % Convert KWh (Energy) to KW (Installed Capacity) using source-specific coefficients
    KWForElectricity_Mat(1:(Renewable_Electricity_row_num-1), i) = CalcKWFromKwh(currentElectSources, KWToKwh_Coeff, RenewablePercents_Vec);
    
    % Sum total installed capacity for all renewable sources
    KWForElectricity_Mat(Renewable_Electricity_row_num, i) = sum(KWForElectricity_Mat(1:Renewable_Electricity_row_num-1, i));
end

% 2. Solar PV Land Distribution
% Select land-use coefficients based on the PV installation type (Ground-mounted vs. Dual-use/Agri-PV)
if strcmp(Data.Area_DataBase.PVType, "Ground")
    RenewableDistribution = Data.Area_DataBase.AreaDistribution.GroundPV;
else
    RenewableDistribution = Data.Area_DataBase.AreaDistribution.DualPV;
end  

% 3. Incremental Capacity (Delta KW)
% Calculate the addition of new installed capacity needed each year compared to the previous year.
DeltaKW_Mat = zeros(7, Years);
DeltaKW_Mat(:,1) = KWForElectricity_Mat(1:7, 1); 
% DeltaKW_Mat(:, 2:end) = max(0, diff(KWForElectricity_Mat(1:7, :), 1, 2)); % Optional: calculate growth only

% 4. Land Use and Resource Integration Loop
% A unified loop to calculate total land footprint for energy, food, and urban development.
TotalArea_Electricity = 0;
InitBuiltArea = Data.Const_DataBase.TotalBuiltArea;
AreaLimit = Data.Const_DataBase.TotalAreaAllowed;

% Pre-mapping resource categories to their respective rows in the final database
idxAreaElect = find(strcmpi(Resources_RowNames, 'Area For Electricity (Km^2)'));
idxCumElect  = find(strcmpi(Resources_RowNames, 'Cumulative Area For Electricity (Km^2)'));
idxAreaFood  = find(strcmpi(Resources_RowNames, 'Area For Food (Km^2)'));
idxAreaConst = find(strcmpi(Resources_RowNames, 'Area For Construction (Km^2)'));
idxCumConst  = find(strcmpi(Resources_RowNames, 'Cumulative Area For Construction (Km^2)'));

ConstFootprintArr = ConstructionFootprintTable{:, :};
AreaSolarCoeffs = Data.Area_DataBase.AreaForSolarEnergyCoefficients;
AreaFoodCoeffs = Data.Food_DataBase.AreaForFoodCoefficients;
areaLimitReached = false;

for i = 1:Years
    % A. Solar Energy Land Use (Km^2)
    % Calculate the land area required for solar panels based on technology efficiency and distribution.
    CurrentAreaCoefficient = AreaSolarCoeffs{i,:};
    AreaForElect = CalcAreaForElectricity(Data, DeltaKW_Mat(:,i), CurrentAreaCoefficient, RenewableDistribution, Data.Area_DataBase.AreaDistribution{:,3});
    
    AreaForElect{:,:} = AreaForElect{:,:} / 1000; % Convert from Dunam/1000m^2 to Km^2
    TotalArea_Electricity = sum(AreaForElect{1,:}) + TotalArea_Electricity;
    
    Resources{idxAreaElect, i} = AreaForElect; 
    Resources{idxCumElect, i}  = TotalArea_Electricity;
    
    % B. Agriculture Land Use for Food Consumption
    % Estimate the land required to support the city's food consumption based on diet scenarios.
    CurrentAreaForFood = CalcAreaForFoodConsumption(FoodConsumptionCell{i}, AreaFoodCoeffs);
    CurrentAreaForFood{:,:} = CurrentAreaForFood{:,:} / 1000; % Convert to Km^2
    Resources{idxAreaFood, i} = CurrentAreaForFood; 
    
    % C. Urban Construction Footprint
    % Track the expansion of the built environment and cumulative urban land use.
    if i == 1
        Resources{idxAreaConst, 1} = ConstFootprintArr(end, 2); % Initial annual expansion
        Resources{idxCumConst, 1}  = ConstFootprintArr(end, 1); % Initial total footprint
    else
        % Scenario-based urban growth: Standard vs. Sensitivity modes
        if (orderIndex == 2 && ConstFootprintArr(end,1) ~= ConstFootprintArr(end, end)) || orderIndex ~= 2
            Resources{idxAreaConst, i} = ConstFootprintArr(end, i);
            Resources{idxCumConst, i}  = ConstFootprintArr(end, i) + Resources{idxCumConst, i-1};
        else
            Resources{idxAreaConst, i} = InitBuiltArea;
        end
    end
    
    % D. Ecological Constraint Check
    % Monitor if the combined land use (Urban + Energy) exceeds the city's available land area.
    if ~areaLimitReached
        ProjectedTotal = TotalArea_Electricity + Resources{idxCumConst, i};
        if ProjectedTotal > AreaLimit
            areaLimitReached = true; 
            msg = sprintf('Exceeded max allowed Area in year %d. (Current: %.2f / Max: %.2f km²)', ...
                           i+BaseYear-1, ProjectedTotal, AreaLimit);
            warndlg(msg, '⚠️ Ecological Capacity Reached');
        end
    end
end

% 5. Data Export - Formatting results back to tables
KWForElectricity = array2table(KWForElectricity_Mat, 'RowNames', Renewable_Electricity_row_names, 'VariableNames', YearsStringsForColNames);
DeltaKW = array2table(DeltaKW_Mat, 'RowNames', Renewable_Electricity_row_names(1:7), 'VariableNames', YearsStringsForColNames);

%% ----------------------------------------- Money

%OperationCost
% if(Data.PVType == "Ground")
%     Data.OperatingCosts.DualPV = [];
%     Data.SettingCosts.DualPV = [];
% else
%     Data.OperatingCosts.GroundPV = [];
%     Data.SettingCosts.GroundPV = [];
% end    
for i = 1:Years
    %Resources{4,i} = CalcOperationCosts(KWForElectricity{:,i}, Data.OperatingCosts{i,:});
    Resources{4,i} = 0;
end

%%Setting Costs
for i = 1:Years
     %Resources{5,i} = CalcSettingCosts(KWForElectricity{:,i}, Data.SettingCosts{i,:});
     %Resources{5,i} = CalcSettingCosts(DeltaKW{:,i}, Data.SettingCosts{i,:});
     Resources{5,i} = 0;
end

% cost of Fuels For Electriciy Manufacturing ONLY, not include transportation
for i = 1:Years
    %Resources{6,i} = CalcFuelCosts(ConsumptionAmounts{2,i}{1,:},ConsumptionAmounts{3,i}{1,:}, Data.ILSPerTon{:,1}, Data.ILSPerTon{:,3});
    Resources{6,i} = 0;
end

% cost of area - UPDATED
% GroundDist = Data.Area_DataBase.AreaDistribution.GroundPV;
% DualDist = Data.Area_DataBase.AreaDistribution.DualPV;
for i = 1:Years
     %Resources{7,i} = CalcCostOfArea(Resources{1,i}{1,3:4}, Data.AreaCostForElectricity{i,:}, GroundDist, DualDist);
     Resources{7,i} = 0;
end


% Lidor add it - just so we can see the output
Data1.Water_DataBase.WaterConsumptionCell = WaterConsumptionCell;


%% ----------------------------------------- Data Export & Final Table Construction
% This final stage organizes all calculated results (Emissions, Consumptions, and Resources) 
% into structured MATLAB Tables for easy analysis, plotting, and Excel export.

% 1. Emissions Results Table
% Converts the raw emission data (Tons of Co2e) into a labeled table by pollutant and sector.
EmissionsByYears = cell2table(EmissionsByYears, 'RowNames', Emission_RowNames);
EmissionsByYears.Properties.VariableNames = YearsStringsForColNames;

% 2. Resource Consumption Table
% Summarizes the physical quantities used (Water, Fuel, Materials) across the simulated years.
ConsumptionAmounts = cell2table(ConsumptionAmounts, 'RowNames', consumption_RowNames);
ConsumptionAmounts.Properties.VariableNames = YearsStringsForColNames;

% 3. Land Use & Infrastructure Resources Table
% Maps land requirements (Energy, Food, Construction) and cumulative urban expansion.
% !!! Logic Check: If Resources is already a numeric array, use array2table instead of cell2table.
if iscell(Resources)
    Resources = cell2table(Resources);
else
    Resources = array2table(Resources);
end

Resources.Properties.RowNames = Resources_RowNames;
Resources.Properties.VariableNames = YearsStringsForColNames;

% 4. Data Structure Sync
% Updates the master data structure with any changes made during the simulation steps.
Data = Data1;


%% ----------------------------------------- Other Functions

function ElectricityFromWater = CalculateElectricityFromWaterAllYears(Data, WaterConsumptionCell, Years)
ElectricityFromWater = cell(1,Years);
for i=1:Years
    ElectricityFromWater{i} = CalcElectricityForWater(Data, WaterConsumptionCell{i}, Data.Water_DataBase.ElectricityConsumptionCoefficients{:,i});
end
end


function printWithCommas(varName, year, value, unit)
    % פונקציה שמדפיסה ערכים עם פסיקים ויחידה אם צריך

    if nargin < 4
        unit = '';
    end

    % הפורמט עם פסיקים
    formattedValue = regexprep(sprintf('%.0f', value), '\d(?=(\d{3})+$)', '$&,');

    % הדפסה
    fprintf('%s for year: %d is: %s %s\n', varName, year, formattedValue, unit);
end



% function PercentageByYears = CalculatePercentageOfElectricitySourcesByYears(RenewableEnergiesPercentage, NaturalGasPercentage, Percentage)
% % Keep original logic for table creation
% ElectricityRowName = Data.Electricity_DataBase.Electricity_Sources;
% ElectricityRowNum = numel(ElectricityRowName);
% PercentageByYears = array2table(zeros(ElectricityRowNum,Years)); 
% 
% ColumnNames = cell(1,Years);
% 
% for i=1:Years
%     s1 = num2str(i+BaseYear-1); 
%     ColumnNames{i} = s1;
% end
% 
% PercentageByYears.Properties.VariableNames = ColumnNames;
% PercentageByYears.Properties.RowNames = ElectricityRowName;
% PercentageByYears{:,1} = Percentage'; %% initialization
% 
% for i = 2:Years
%     % Calculating the "Power" of the Queen (Renewables) and the Support (Gas)
%     CurrentRenewableChange = RenewableEnergiesPercentage(i)-RenewableEnergiesPercentage(i-1);
%     CurrentGasChange = NaturalGasPercentage(i)-NaturalGasPercentage(i-1);
% 
%     % The total capacity to displace old fuels
%     TotalDisplacementPower = CurrentRenewableChange + CurrentGasChange;
% 
%     % The Hit List (Priority of removal): 
%     % 1. Mazut (5), 2. Soler (4), 3. Coal (1)
%     PollutingIndices = [1,5,4];
% 
%     for idx = PollutingIndices
%         if TotalDisplacementPower > 0 && Percentage(idx) > 0
%             if Percentage(idx) > TotalDisplacementPower
%                 Percentage(idx) = Percentage(idx) - TotalDisplacementPower;
%                 TotalDisplacementPower = 0;
%             else
%                 TotalDisplacementPower = TotalDisplacementPower - Percentage(idx);
%                 Percentage(idx) = 0;
%             end
%         end
%     end
% 
%     % --- THE DOMINANCE RULE ---
%     % Renewable Energy (3) is the Queen: it takes its share NO MATTER WHAT.
%     Percentage(3) = Percentage(3) + CurrentRenewableChange;
% 
%     % Natural Gas (2) is the Buffer: 
%     % If there's still Displacement Power left after killing Oil and Coal, 
%     % it means the Renewables are now "trampling" the Gas.
%     if TotalDisplacementPower > 0 && CurrentGasChange <= 0
%         Percentage(2) = max(0, Percentage(2) - TotalDisplacementPower);
%     else
%         Percentage(2) = Percentage(2) + CurrentGasChange;
%     end
% 
%     % Final normalization to ensure the mix always sums to 1 (100%)
%     Percentage = Percentage / sum(Percentage);
% 
%     % Store in table
%     PercentageByYears{:,i} = Percentage';
% end
% end



function PercentageByYears = CalculatePercentageOfElectricitySourcesByYears(RenewableEnergiesPercentage, NaturalGasPercentage, Percentage)
    % RenewableEnergiesPercentage ו-NaturalGasPercentage הם עכשיו וקטורים אבסולוטיים (למשל 0.05 עד 0.8)
    
    ElectricityRowName = Data.Electricity_DataBase.Electricity_Sources;
    ElectricityRowNum = numel(ElectricityRowName);
    PercentageByYears = array2table(zeros(ElectricityRowNum, Years)); 
    
    % שנת הבסיס האמיתית מה-Data (לפני תחילת התרחיש)
    InitialRenewable = Data.Electricity_DataBase.InitialPercentage(3);
    InitialGas = Data.Electricity_DataBase.InitialPercentage(2);

    % לולאה על השנים
    for i = 1:Years
        % חישוב השינוי ביחס לשנה הקודמת
        if i == 1
            % בשנה הראשונה - השינוי הוא מול שנת הבסיס של המודל
            CurrentRenewableChange = RenewableEnergiesPercentage(i) - InitialRenewable;
            CurrentGasChange = NaturalGasPercentage(i) - InitialGas;
        else
            % בשאר השנים - השינוי הוא מול השנה הקודמת בווקטור
            CurrentRenewableChange = RenewableEnergiesPercentage(i) - RenewableEnergiesPercentage(i-1);
            CurrentGasChange = NaturalGasPercentage(i) - NaturalGasPercentage(i-1);
        end
        
        % סך הכל דלקים מזהמים שצריך להחליף השנה
        TotalDisplacementPower = CurrentRenewableChange + CurrentGasChange;
        
        % סדר עדיפויות להוצאה מהתמהיל: מזוט (5), סולר (4), פחם (1)
        PollutingIndices = [1,5,4];
        
        for idx = PollutingIndices
            if TotalDisplacementPower > 0 && Percentage(idx) > 0
                if Percentage(idx) > TotalDisplacementPower
                    Percentage(idx) = Percentage(idx) - TotalDisplacementPower;
                    TotalDisplacementPower = 0;
                else
                    TotalDisplacementPower = TotalDisplacementPower - Percentage(idx);
                    Percentage(idx) = 0;
                end
            end
        end
        
        % עדכון האחוזים האבסולוטיים
        Percentage(3) = Percentage(3) + CurrentRenewableChange; % מלכה (מתחדשות)
        
        % גז טבעי כבלאנסר
        if TotalDisplacementPower > 0 && CurrentGasChange <= 0
            Percentage(2) = max(0, Percentage(2) - TotalDisplacementPower);
        else
            Percentage(2) = Percentage(2) + CurrentGasChange;
        end
        
        % נרמול ל-100%
        Percentage = Percentage / sum(Percentage);
        PercentageByYears{:,i} = Percentage';
    end
end



function NewVehicleAmountCell = CalulateChangeInVehicleAmountsTransitionToPublicTransport(TrasnportationConsumptionTable, VehicleAmountCell, Data, Years, RidesPerDay, Days_In_Year)
% Description:
% This function calculates the NET CHANGE (Delta) in vehicle fleet size for a specific year
% due to transitions between private cars and public transportation.

% 1. Setup & Pre-allocation
TransRowNames = Data.Trans_DataBase.Vehicle_Amounts_RowNames;
TransColNames = Data.Trans_DataBase.Vehicle_Amounts_ColNames;
TransRow_Num  = numel(TransRowNames);
TransColNum   = numel(TransColNames);

NewVehicleAmountCell = cell(1, Years);

% !!! OPTIMIZATION: Convert table to array once
transArr = table2array(TrasnportationConsumptionTable);

% 2. Calculate Base Mileage Coefficients
% Determining the average annual KM covered by a single vehicle unit.
KMPerCar = transArr(2,1) / VehicleAmountCell{1}{1,2};
KMPerBus = transArr(1,1) / VehicleAmountCell{1}{1,1};

% 3. Fleet Delta Calculation Loop
for i = 1:Years
    % Initialize current year matrix with zeros
    currYearArr = zeros(TransRow_Num, TransColNum);
    
    if i == 1
        % Base Year: Copy original data
        currYearArr = table2array(VehicleAmountCell{1});
    else
        % !!! OPTIMIZATION: Working with numeric arrays for speed
        prevYearArr = table2array(NewVehicleAmountCell{i-1});
        
        % --- Calculate Delta for Fleet Quantity (Row 1) ---
        % Net Change = (Current Required Fleet) - (Previous Year Fleet)
        % Bus (Column 1), Car (Column 2)
        currYearArr(1,1) = ceil(transArr(1,i) / KMPerBus) - prevYearArr(1,1);
        currYearArr(1,2) = floor(transArr(2,i) / KMPerCar) - prevYearArr(1,2);
        
        % --- Update Derived Statistics (Rows 4, 5, 6) ---
        % Vectorized update for both Bus and Car columns
        targetCols = [1, 2];
        currYearArr(4, targetCols) = currYearArr(1, targetCols) * RidesPerDay;
        currYearArr(5, targetCols) = currYearArr(4, targetCols) * Days_In_Year;
        currYearArr(6, targetCols) = currYearArr(1, targetCols) * Days_In_Year;
    end
    
    % !!! OPTIMIZATION: Convert back to table ONLY ONCE per year
    NewVehicleAmountCell{i} = array2table(currYearArr, 'RowNames', TransRowNames, 'VariableNames', TransColNames);
end

end


function NewVehicleAmountCell = ChangesInVehicelAmountsAfterElectricVehicels(TransportationConsumptionTable, VehicleAmountCell, Data, Years, RidesPerDay, Days_In_Year)
% Description:
% This function updates the vehicle fleet size and daily/annual ride statistics 
% based on the transition to electric vehicles (EV) and changes in total mileage.

% 1. Initialization
TransRowNames = Data.Trans_DataBase.Vehicle_Amounts_RowNames;
TransColNames = Data.Trans_DataBase.Vehicle_Amounts_ColNames;
TransRow_Num  = numel(TransRowNames);
TransColNum   = numel(TransColNames);

NewVehicleAmountCell = cell(1, Years);

% !!! OPTIMIZATION: Convert the input table to an array once
transTableArr = table2array(TransportationConsumptionTable);

% 2. Calculate Base Year Mileage per Vehicle
% These constants define the average annual distance traveled by a single unit of each vehicle type.
KMPerCar   = transTableArr(2,1) / VehicleAmountCell{1}{1,2};
KMPerBus   = transTableArr(1,1) / VehicleAmountCell{1}{1,1};
KMPerTruck = transTableArr(5,1) / VehicleAmountCell{1}{1,5};
KMPerVan   = transTableArr(6,1) / VehicleAmountCell{1}{1,6};

% 3. Fleet Evolution Loop
% Track the changes in vehicle quantities and update usage statistics (rides/day, rides/year).
for i = 1:Years
    if i == 1
        % Set base year data
        NewVehicleAmountCell{1} = VehicleAmountCell{1};
        continue;
    end
    
    % !!! OPTIMIZATION: Work with a numeric matrix instead of a Table inside the loop
    % Start with the previous year's values
    prevYearArr = table2array(NewVehicleAmountCell{i-1});
    currYearArr = prevYearArr; 
    
    % --- Update Vehicle Quantities (Row 1) ---
    % Calculate the new fleet size based on the change in total mileage and average KM per vehicle.
    % Index 1: Bus, 2: Car, 5: Truck, 6: Van
    currYearArr(1,1) = prevYearArr(1,1) - floor((transTableArr(1,i-1) - transTableArr(1,i)) / KMPerBus);
    currYearArr(1,2) = prevYearArr(1,2) - floor((transTableArr(2,i-1) - transTableArr(2,i)) / KMPerCar);
    currYearArr(1,5) = prevYearArr(1,5) - floor((transTableArr(5,i-1) - transTableArr(5,i)) / KMPerTruck);
    currYearArr(1,6) = prevYearArr(1,6) - floor((transTableArr(6,i-1) - transTableArr(6,i)) / KMPerVan);
    
    % --- Update Usage Statistics (Rows 4, 5, 6) ---
    % Row 4: Rides Per Day | Row 5: Rides Per Year | Row 6: Vehicle-Days Per Year
    targetCols = [1, 2, 5, 6];
    currYearArr(4, targetCols) = currYearArr(1, targetCols) * RidesPerDay;
    currYearArr(5, targetCols) = currYearArr(4, targetCols) * Days_In_Year;
    currYearArr(6, targetCols) = currYearArr(1, targetCols) * Days_In_Year;
    
    % !!! OPTIMIZATION: Convert back to table ONLY ONCE per year
    NewVehicleAmountCell{i} = array2table(currYearArr, 'RowNames', TransRowNames, 'VariableNames', TransColNames);
end

end


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

%clear fuel_LPG_coeff  fuel_MTOE_coeff Crude_Oil_To_Electricity ElectricityBySources_row_names


end


