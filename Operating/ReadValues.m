%% Create all the Sectors tables for all the years from the base to the target year

%% Read Files  - needs to convert to function
addpath("Scenarios");
addpath("CalcFunctions");
%addpath("UI");
addpath("Data");

%% Create the DataBase
DataBase = struct();
DataBase.Water_DataBase = struct();
DataBase.Electricity_DataBase = struct();
DataBase.Trans_DataBase = struct();
DataBase.Food_DataBase = struct();
DataBase.Const_DataBase = struct();
DataBase.Materials_DataBase = struct();
DataBase.Area_DataBase = struct();
DataBase.Money_DataBase = struct();
WDB = DataBase.Water_DataBase;
EDB = DataBase.Electricity_DataBase;
TDB = DataBase.Trans_DataBase;
FDB = DataBase.Food_DataBase;
CDB = DataBase.Const_DataBase;
MDB = DataBase.Materials_DataBase;
ADB = DataBase.Area_DataBase;
MONDB = DataBase.Money_DataBase;
Data = "Data.xlsx";

% Generel Input for the model DataBase
GeneralInputsDataBase = struct();

% For the Results Analisys
ResultsDataBase = struct();
ResultsDataBase.BAU_RDB = struct();
ResultsDataBase.Moderate_RDB = struct();
ResultsDataBase.Advanced_RDB = struct();

% For the sensetivity Analisys
SensitivityResults = struct();

%% Insert data to the DataBase from the "prepatation" script
DataBase.ScenarioRowNames = ScenarioRowNames;
DataBase.EvSenarioLines = EvSenarioLines;
DataBase.Conversion_Liter_To_Kg = Conversion_Liter_To_Kg;
DataBase.Days_In_Year = 365; 

%% ------------------------------------- ELECTRICITY ------------------------------------------------

% Define the names
EDB.Electricity_Consumption_RowNames = {'Home', 'Public & Commercial', 'Industrial', 'Other', 'Transportation', 'Water Supply and Seweage Treatment', 'Total'};
Electricity_Consumption_Row_Num = int32(numel(EDB.Electricity_Consumption_RowNames));
% Elctricity - Energy type
ElctricityFromNatualGasCoeff_RowNames = {'Converted', 'Combined Cycle'};
% Electricity sources for the fullScenario script
EDB.Electricity_Sources = {'Coal', 'Natural Gas', 'Renewable', 'Soler', 'Mazut'};
% Electricity - Consumption For Water
ElectricityConsumptionForWater_RowNames = {'Natural Water', 'Urban Consumption','Diselinated Water','Treated Waste Water', 'Sewege'};
ElectricityConsumptionForWater_Row_Num = int32(numel(ElectricityConsumptionForWater_RowNames));

%%% For later calculations
EDB.ElectricityBySources_row_names = {'KWh From Coal', 'KWh From Natural Gas', 'KWh From Renewable Energies', 'KWh From Soler', 'KWh From Mazut', 'KWh From Waste Incinaration', 'Total'};
EDB.Renewable_Electricity_row_names = {'Coal','Natural Gas','PV', 'Wind', 'Biomass', 'Thermo Solar', 'Total'};
EDB.ElectricityEmissionTypes = {'Co2', 'CH4', 'Nitrous Oxide (N2O)', 'NOX', 'PM', 'SO2', 'Other Air Pollutants', 'Sewage', 'Co2e'};

% Electricity Consumption - UPDATED 
% create a table in the DataBase that contain the Electricity consumption for every year to the target year
EDB.ElectricityConsumptionTable = array2table(zeros(Electricity_Consumption_Row_Num, Years),'RowNames',EDB.Electricity_Consumption_RowNames);
ColumnNames = cell(1,Years);
% Add the name for each year column
s1 = "KWH for "; 
for i=1:Years
    s2 = num2str(i+BaseYear-1);
    ColumnNames{i} = strcat(s1, s2); 
end
EDB.ElectricityConsumptionTable.Properties.VariableNames = cellstr(ColumnNames); % Convert the column names to string
% Read the 2019 Data from the Data File
EDB.ElectricityConsumptionTable{1:(Electricity_Consumption_Row_Num-1), 1} = table2array(readtable(Data,'Sheet','ElectricityConsumption','Range','B2:B7','ReadVariableNames',false));

% Import more variables
EDB.IndustryElectricityConsumptionChange = readmatrix('Data.xlsx', 'Sheet','ElectricityConsumption','Range','E4:E4'); % Save the single Datumn in the DataBase as single value
EDB.ElectricityLossRatio = readmatrix('Data.xlsx', 'Sheet','ElectricityConsumption','Range','E2:E2'); % Save the single Datumn in the DataBase as single value

% Electricity Fuels coeff
EDB.Crude_Oil_To_Electricity = readmatrix('Data.xlsx', 'Sheet','Materials','Range','L37:L37');  %11.63; % Crude oil to electricity
% Emission coefficient per ton fuel burning
EDB.fuel_MTOE_coeff = 2.5; % CO₂ Emission Factor per Ton of Burning Fuel (Ton/Ton)
EDB.fuel_LPG_coeff = 2.9; % CO₂ Emission Factor per Ton of Burning LPG Fuel (Ton/Ton)

% Electricity Consumption Emissions In Transportation (taken from the ElectricityConsumption sheet)
% Electricity: Electricity Consumption for Electric Vehicle (kWh/KM)
EDB.ElectricityConsumptionEmissionsInTransportation = table2array(readtable(Data,'Sheet','ElectricityConsumption','Range','H4:H7','ReadVariableNames',false)); 
% Electricity: Emissions Coefficeints from Battery Manufacturing (gCo2/km)
EDB.EmissionsCoefficientsFromBatteryManufacturing = table2array(readtable(Data,'Sheet','ElectricityConsumption','Range','H2:H2','ReadVariableNames',false)); 
% initial percentage (Electricity Fuels Consumption distribution in base year)
EDB.InitialPercentage = table2array(readtable(Data,'Sheet','ElectricityConsumption','Range','B12:F12','ReadVariableNames',false));

% Calc Electricity Consumption
% Emissions g/KWh of differnt types of fuels for electricity
EDB.EmissionsFromElectricityConsumption = table2array(readtable(Data,'Sheet','ElectricityConsumption','Range','B15:I21','ReadVariableNames',true));
% Emissions from Natural Gas g/KWh from two power-plant
EDB.ElctricityFromNatualGasCoeff = array2table(zeros(2,1));
EDB.ElctricityFromNatualGasCoeff.Properties.RowNames = ElctricityFromNatualGasCoeff_RowNames;

EDB.ElctricityFromNatualGasCoeff{1,1}  = readmatrix('Data.xlsx', 'Sheet','ElectricityConsumption','Range','I11:I11'); 
EDB.ElctricityFromNatualGasCoeff{2,1}  = readmatrix('Data.xlsx', 'Sheet','ElectricityConsumption','Range','I12:I12'); 

% Calc Electricity manufacturing
DataBase.EmissionsCoefficientsForPv = readtable(Data,'Sheet','PVEmissions','Range','I8:J40','ReadVariableNames',true);
% Coefficients from mining and fuel manufacturing 
EDB.EmissionsCoefficientsUpstreamElectricity = table2array(readtable(Data,'Sheet','ElectricityManufactureEmissions','Range','B15:G21','ReadVariableNames',false))';
% How many tons of fuel is needed for 1 kwh of electricity
EDB.ElectrictyManufacturingCoefficients = table2array(readtable(Data,'Sheet','ElectricityManufactureEmissions','Range','B3:E3','ReadVariableNames',false));
% The Ratio between crude oil to Manufactured Fuel
EDB.CrudeOilToFuelRatio = readmatrix('Data.xlsx', 'Sheet','ElectricityManufactureEmissions','Range','K2:K2'); 

% Renewable energy data
% Data about Percentage of enery resurces in the latest year we have data on-  in order to accurate the model data (that based on the 2019 year)
EDB.RenewableEnergies_CurrentYear = readmatrix('Data.xlsx', 'Sheet','ElectricityConsumption','Range','L3:L3');
EDB.NaturalGas_CurrentYear = readmatrix('Data.xlsx', 'Sheet','ElectricityConsumption','Range','L4:L4');
EDB.CurrentYearReal = readmatrix('Data.xlsx', 'Sheet','ElectricityConsumption','Range','L2:L2');
% PV - data assumptions
EDB.PVLifeCycle = readmatrix('Data.xlsx', 'Sheet','Area','Range','F5:F5');
EDB.NewPV_PercentageBaseYear = readmatrix('Data.xlsx', 'Sheet','Area','Range','F7:F7');
EDB.GroundPVPercentage = readmatrix('Data.xlsx', 'Sheet','Area','Range','F2:F2');
EDB.DualPVPercentage = readmatrix('Data.xlsx', 'Sheet','Area','Range','F3:F3');

% Waste Inciniration
%% Waste incinaration values 
EDB.WasteToElectricity = readmatrix('Data.xlsx', 'Sheet','ElectricityManufactureEmissions','Range','H6:H6'); % How much waste needed to burn to get 1 kWh of electricity
%EDB.IncinarationEmissionCoefficient = readmatrix('Data.xlsx', 'Sheet','ElectricityManufactureEmissions','Range','H8:H8'); % Emission coefficient of waste incineration


%% ------------------------------------- TRANSPORTATION ------------------------------------------------
%%%%%% TEMPS
% Transportation - Consumption
Transportation_Consumption_RowNames = {'Bus', 'Car', 'Minibus', 'Motorcycle', 'Truck', 'LCV', 'PassengerTrain','Freight Train', 'Total'};
Transportation_Consumption_Row_Num = int32(numel(Transportation_Consumption_RowNames));

% Transportation - Vehicle Amounts By type
TDB.Vehicle_Amounts_RowNames = {'Quantity', 'Gasoline', 'Diesel', 'Drive Per Day', 'Drive Per Year', 'Cars Per Year'};
TDB.Vehicle_Amounts_ColNames = {'Bus','Car','Minibus','Motorcycle', 'Truck', 'LCV'};
TDB.Train_Names = {'Passenger Train', 'Friehgt Train'};
TDB.Train_EmissionTypes = {'NOX' , 'CO','NMVOC', 'NH3', 'TSP', 'PM10', 'PM2.5', 'N2O', 'CH4', 'SO2', 'CO2', 'CO2E'};
TDB.TransEmissionTypes = {'c6h6', 'ch2o', 'ch4', 'co', 'n2o', 'nh3', 'nmvoc', 'no2', 'nox', 'PM2.5', 'PM10', 'so2', 'co2', 'Fuel Consumption', 'Total Air Pollutants', 'Co2e'};
TDB.TransEnergy_type = {'Mazut', 'Diesel', 'Kerosene', 'Gasoline','Liquefied Petroleum Gas', 'Crude Oil', 'Natural Gas', 'Battery Manufacturing'};
TDB.TransEmission_Manu_type = {'CH4', 'CO2','Hydroflour Carbon','Air Pollutants','Mining Waste','Waste Water','CO2E'};
Vehicle_Amounts_Row_Num = int32(numel(TDB.Vehicle_Amounts_RowNames));
Vehicle_Amounts_Col_Num = int32(numel(TDB.Vehicle_Amounts_ColNames));

% Fuels
AmountsOfFuels_RowNames = {'Crude Oil Products - Not for Energy', 'Crude Oil For Export', 'Crude Oil Import','Crude Oil Products - For Energy', 'LPG - Home', 'LPG - Commertiel'  };
AmountsOfFuels_ColNames = {'Naptha', 'Mazut','Diesel','Kerosene','Gasoline','Liquified Petroleum Gas', 'Other'};
AmountsOfFuels_Row_Num = int64(numel(AmountsOfFuels_RowNames));
AmountsOfFuels_Col_Num = int64(numel(AmountsOfFuels_ColNames));

% Fuel - Consumption Coefficients
FuelConsumptionCoefficients_RowNames = {'Hot Emissions', 'Cold Emissions', 'Evaporation Emissions', 'Evaporation Emissions - After Driving', 'Evaporation Emissions - Every Day', 'Grinding Emissions'};
FuelConsumptionCoefficients.Properties.VariableNames = {'Bus', 'Car', 'Minibus', 'Motorcycle', 'Truck', 'LCV', 'Train'};
FuelConsumptionCoefficients_Row_Num = int64(numel(FuelConsumptionCoefficients_RowNames));
FuelConsumptionCoefficients_Col_Num = int64(numel(FuelConsumptionCoefficients.Properties.VariableNames ));

%%%%%%%%%%%%% Transportation Cosnumption
% create a table in the DataBase that contain the Transportation KM for every year to the target year
TDB.TransportationConsumptionTable = array2table(zeros(Transportation_Consumption_Row_Num, Years),'RowNames', Transportation_Consumption_RowNames);
% Add the name for each year column
ColumnNames = cell(1,Years);
s1 = "Annual Travel (KM) for ";
for i=1:Years
    s2 = num2str(i+BaseYear-1);
    ColumnNames{i} = strcat(s1, s2);
end
TDB.TransportationConsumptionTable.Properties.VariableNames = cellstr(ColumnNames);
TDB.TransportationConsumptionTable{1:(Transportation_Consumption_Row_Num-1), 1} = table2array(readtable(Data,'Sheet','TransportationConsumption','Range','B3:B10','ReadVariableNames',false));
TDB.TransportationConsumptionTable{Transportation_Consumption_Row_Num, 1} = sum(TDB.TransportationConsumptionTable{1:(Transportation_Consumption_Row_Num-1),1}); % Create a sum row for the table

%%%%%%%%%%%% Vehicle Amounts - Needs to Updates with Trains!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
% This is a one-demantional array that contain columns for each year.
% Ideally each cell of it will contain a table with the year data of the number of vehicle. For now its just the first cell that contain the table (for 2019)
TDB.VehicleAmountsCell = cell(1,Years);
TDB.VehicleAmountsCell{1} = array2table(zeros(Vehicle_Amounts_Row_Num,Vehicle_Amounts_Col_Num), 'RowNames', TDB.Vehicle_Amounts_RowNames);
% Read the 2019 Data from the Data File
TDB.VehicleAmountsCell{1}{:,:} = table2array(readtable(Data,'Sheet','TransportationConsumption','Range','E3:J8','ReadVariableNames',false));
TDB.VehicleAmountsCell{1}.Properties.VariableNames = TDB.Vehicle_Amounts_ColNames;


%%%%%%%%%%%% Calc transportation consumption

% All the Emissions Coefficients for different kindes of emission
TDB.TransportationHotEmissionsCoefficients = table2array(readtable(Data,'Sheet','TransportationConsumption','Range','B20:H33','ReadVariableNames',false));
TDB.TransportationColdEmissionsCoefficients = table2array(readtable(Data,'Sheet','TransportationConsumption','Range','K20:Q33','ReadVariableNames',false));
TDB.TransportationEvaporationEmissionsWhileDriving = table2array(readtable(Data,'Sheet','TransportationConsumption','Range','T20:Z33','ReadVariableNames',false));
TDB.TransportationEvaporationEmissionsAfterDriving = table2array(readtable(Data,'Sheet','TransportationConsumption','Range','AC20:AI33','ReadVariableNames',false));
TDB.TransportationEvaporationEmissionsEveryDay = table2array(readtable(Data,'Sheet','TransportationConsumption','Range','AL20:AR33','ReadVariableNames',false));
TDB.TransportationGridingEmissions = table2array(readtable(Data,'Sheet','TransportationConsumption','Range','AU20:BA33','ReadVariableNames',false));

% The table settings (15*7) (we added one more col and one more row to what exist in the excel)
[TDB.TransEmissionNumRows, TDB.TransEmissionNumCols] = size(TDB.TransportationHotEmissionsCoefficients);
TDB.TransEmissionNumRows = TDB.TransEmissionNumRows + 1;  % First row is a header 
TDB.TransEmissionNumCols = TDB.TransEmissionNumCols + 1;  % Last col- The sum of the row
TDB.MainEmissionTypesRows = 12; % The main Types of emissions in the excel

% Train Emissions Coefficients (g/KM)
TDB.PassengerTrainEmissionCoefficients = table2array(readtable(Data,'Sheet','TransportationConsumption','Range','B77:B88','ReadVariableNames',false));
TDB.PassengerTrainEmissionCoefficients(11, :) = []; % Deletes the 11th line (Total Pollutants)
TDB.FreightTrainEmissionCoefficients = table2array(readtable(Data,'Sheet','TransportationConsumption','Range','C77:C88','ReadVariableNames',false));
TDB.FreightTrainEmissionCoefficients(11,:) = []; % Deletes the 11th line (Total Pollutants)

%%%%%%%%%%%%%%%%%%%%%% Calc transportation manufacturing
% Fuel Consumption coefficients (g/Km) for every kind of emission in transportation
TDB.FuelConsumptionCoefficients = array2table(zeros(FuelConsumptionCoefficients_Row_Num, FuelConsumptionCoefficients_Col_Num), 'RowNames', FuelConsumptionCoefficients_RowNames);
TDB.FuelConsumptionCoefficients.Properties.VariableNames = {'Bus', 'Car', 'Minibus', 'Motorcycle', 'Truck', 'LCV', 'Train'};
TDB.FuelConsumptionCoefficients{1,1:6} = table2array(readtable(Data,'Sheet','TransportationConsumption','Range','B33:G33','ReadVariableNames',false));
TDB.FuelConsumptionCoefficients{2,1:6} = table2array(readtable(Data,'Sheet','TransportationConsumption','Range','K33:P33','ReadVariableNames',false));
TDB.FuelConsumptionCoefficients{3,1:6} = table2array(readtable(Data,'Sheet','TransportationConsumption','Range','T33:Y33','ReadVariableNames',false));
TDB.FuelConsumptionCoefficients{4,1:6} = table2array(readtable(Data,'Sheet','TransportationConsumption','Range','AC33:AH33','ReadVariableNames',false));
TDB.FuelConsumptionCoefficients{5,1:6} = table2array(readtable(Data,'Sheet','TransportationConsumption','Range','AL33:AQ33','ReadVariableNames',false));
TDB.FuelConsumptionCoefficients{6,1:6} = table2array(readtable(Data,'Sheet','TransportationConsumption','Range','AU33:AZ33','ReadVariableNames',false));
% Train Fuel Consumption Coefficients (Diesel/KM) 
TDB.TrainFuelConsumptionCoefficints = table2array(readtable(Data,'Sheet','TransportationConsumption','Range','F77:F78','ReadVariableNames',false))';

% Soler/amount ratio - CBS Coeeficients 2011
TDB.InflationCoefficient = readmatrix('Data.xlsx', 'Sheet','TransportationConsumption','Range','G93:G93');
% Fuel Amounts For Transportation - Natural Gas to Fuel Refining for transportation (Ton)
TDB.NaturalGasForFuelRefining = readmatrix('Data.xlsx', 'Sheet','TransportationConsumption','Range','I63:I63');
% Coefficients from mining and fuel manufacturing for Mazut only
TDB.EmissionsCoefficientsUpstream = table2array(readtable(Data,'Sheet','TransportationConsumption','Range','N3:T9','ReadVariableNames',false))'; %% array(6,7)

% Rides per day
TDB.RidesPerDay = readmatrix('Data.xlsx','Sheet','TransportationConsumption','Range','A13:A13'); % 4
% Car Bus Ratio - Define the ratio between car to bus use
TDB.BusCarRatio = readmatrix('Data.xlsx','Sheet','TransportationConsumption','Range','F12:F12');
% Car Train Ratio - Define the ratio between car to Train use
TDB.TrainCarRatio = readmatrix('Data.xlsx','Sheet','TransportationConsumption','Range','E12:E12');

% Distribution of - Transition to buses and trains 
TDB.TransitionToBus = readmatrix('Data.xlsx','Sheet','TransportationConsumption','Range','H12:H12');
TDB.TransitionToTrain = readmatrix('Data.xlsx','Sheet','TransportationConsumption','Range','I12:I12');

%% ---------------------------------------- WATER ------------------------------------------------

% Load water base consumption table
WDB.water_Names = {'Water for Domestic & Industrial', 'Water for Agriculture', 'Water for Neighbors', 'Water for  Nature', 'Drilling Water', 'Reclaimed Wastewater', 'Brackish water, fresh and non-fresh reservoir water', 'Desalinated Water'};
WDB.WaterConsumptionTableNew = readtable('Data.xlsx','Sheet', 'WaterNew','ReadVariableNames', false, 'ReadRowNames', true,'Range', 'A2:D9');  
WDB.WaterConsumptionTableNew.Properties.VariableNames = {'2017','2019','2022'};
WDB.WaterConsumptionTableNew.Properties.RowNames = WDB.water_Names;

WDB.Water_Electricity_Types = {'Drilling Water', 'Desalinated Water', 'Moving Reclaimed Wastewater', 'Reclaimed Wastewater','Moving Brackish water, fresh and non-fresh reservoir water', 'Total'};

WDB.WaterConsumptionCell = cell(1,Years); 
WDB.WaterConsumptionCell{1} = array2table(zeros(1,numel(WDB.water_Names)), 'VariableNames', WDB.water_Names);

%% Old Water
% Water_Consumption_RowNames = {'Agriculture', 'Marginal Water Percentage', 'Home Consumption(Urban)', 'Industry', 'Water for Nature', 'Water for Neighbors'};
% Water_Consumption_ColNames = {'Water From Nature', 'Diselinated Water','Brackish Water','Treated WasteWater','Flood Water'};
% Water_Consumption_Row_Num = int32(numel(Water_Consumption_RowNames));
% Water_Consumption_Col_Num = int32(numel(Water_Consumption_ColNames));
% % choosing brakish, treated water water and flood of 2019. and put it in the 3-5 columns of the table in the first cell
% DataBase.WaterConsumptionCell{1}{:,3:5} = table2array(readtable(Data,'Sheet','Water','Range','F12:H17','ReadVariableNames',false));
% % choosing drinking water for all purpuses. (Save it in another variable)
% DataBase.DrinkingWater = table2array(readtable(Data,'Sheet','Water','Range','E12:E17','ReadVariableNames',false));
% % precentage of desalinated water from all SHAFIRIM (all drinking water) 
% DiselinatedWaterPercntage = readtable(Data,'Sheet','Water','Range','N44:N44','ReadVariableNames',false);
% DataBase.DiselinatedWaterPercntage = DiselinatedWaterPercntage{1,1}; 
% DiselinatedWaterPercntage = DiselinatedWaterPercntage{1,1};
% % the total water from nature is all the drinkingWater X precentage of not desalinated
% DataBase.WaterConsumptionCell{1}{:,1} = DataBase.DrinkingWater*(1-DiselinatedWaterPercntage);
% % the total Diselinated water is all the drinkingWater X precentage of desalinated
% DataBase.WaterConsumptionCell{1}{:,2} = DataBase.DrinkingWater*DiselinatedWaterPercntage;
% % Basicaly this is the Drinking Water
% DataBase.WaterConsumptionCell{1}{5,1} = DataBase.WaterConsumptionCell{1}{5,1}+DataBase.WaterConsumptionCell{1}{5,2};
% % Water for nature doesn't get desalinated
% DataBase.WaterConsumptionCell{1}{5,2} = 0;
% % Give column names to the table we just built above
% DataBase.WaterConsumptionCell{1}.Properties.VariableNames = Water_Consumption_ColNames;

%% Water-New load (Dor's model) - Lidor's Update
% Load all the constant values
% Agriculture_water
WDB.AgriculturePerCapitaFactor_water = readmatrix('Data.xlsx', 'Sheet','WaterNew','Range','D20:D20');
%WDB.AgriculturePerCapitaFactor_water_Not_Base_Year = readmatrix('Data.xlsx', 'Sheet','WaterNew','Range','D21:D21');
WDB.AgriculturePerCapitaOffset_water = readmatrix('Data.xlsx', 'Sheet','WaterNew','Range','D22:D22');
WDB.AgricultureBaseYear_water = readmatrix('Data.xlsx', 'Sheet','WaterNew','Range','D19:D19');

WDB.PopulationGrowth           = readmatrix('Data.xlsx', 'Sheet','WaterNew','Range','B19:B19');
WDB.ChangeFreshWater           = readmatrix('Data.xlsx', 'Sheet','WaterNew','Range','B20:B20');
WDB.FreshWaterForAgriculture   = readmatrix('Data.xlsx', 'Sheet','WaterNew','Range','B21:B21');
WDB.FreshWaterForDomestic      = readmatrix('Data.xlsx', 'Sheet','WaterNew','Range','C31:C31');
WDB.LossRatio                  = 1 + readmatrix('Data.xlsx', 'Sheet','WaterNew','Range','B22:B22');
WDB.ChangeDrillingWater        = readmatrix('Data.xlsx', 'Sheet','WaterNew','Range','B23:B23');
% Calculate the yeasrly Change in drilling water (25% less until 2050)
WDB.Yearly_ChangeDrillingWater = WDB.ChangeDrillingWater^(1/Years);
WDB.ReclaimedRatio             = readmatrix('Data.xlsx', 'Sheet','WaterNew','Range','B24:B24'); 
WDB.BrackishAmount             = readmatrix('Data.xlsx', 'Sheet','WaterNew','Range','B25:B25');
WDB.DesalinatedFormula         = readcell('Data.xlsx', 'Sheet','WaterNew','Range','B26:B26'); 
WDB.Avg_per_capita_domestic    = readmatrix('Data.xlsx', 'Sheet','WaterNew','Range','B31:B31'); 
WDB.Avg_per_capita_Palestinians= readmatrix('Data.xlsx', 'Sheet','WaterNew','Range','B32:B32'); 
WDB.Fixed_Brackish = WDB.WaterConsumptionTableNew{'Brackish water, fresh and non-fresh reservoir water', '2019'};

% Nature_water
M = readmatrix('Data.xlsx', 'Sheet', 'WaterNew', 'Range', 'G7:H10');  
WDB.Nature_water_yearThresholds = M(:,2);
WDB.Nature_water_yearThresholds_values = M(:,1);
% WDB.Nature_water_yearThresholds = [7, 12, 22, 32];
% WDB.Nature_water_yearThresholds_values = [25, 35, 50, 75];

% Read the values of Waste Treatment Emmission Coefficients
WDB.SewegeTreatmentEmissionsCoefficitns = readtable(Data,'Sheet','WaterNew','Range','B37:C37','ReadVariableNames',false);
WDB.SewegeTreatmentEmissionsCoefficitns.Properties.VariableNames = {'Air Pollutants (KG\Ton)', 'GHG (KG\Ton)'};

% Electricity Consumption For Water
% Read the electricity consumption as a result of water beeing desalinated,pump, moving, Seweage Treatment...
WDB.ElectricityConsumptionForWaterCell = cell(1,1);
WDB.ElectricityConsumptionForWaterCell{1} = array2table(zeros(ElectricityConsumptionForWater_Row_Num,1), 'RowNames', ElectricityConsumptionForWater_RowNames);
%WDB.Electricity_DataBase.ElectricityConsumptionForWaterCell{1}{:,1} = table2array(readtable(Data,'Sheet','Water','Range','I33:I37','ReadVariableNames',false));

% Calc Electricity for water
% Electricity For Water Coefficints (kwh/m^3)
WDB.ElectricityConsumptionCoefficients = readmatrix(Data, 'Sheet', 'WaterNew', 'Range', 'B12:B17');

% % Distribution in uses of Urban SHAPIRIM 
% WDB.UrbanConsumptionPercentages = table2array(readtable(Data,'Sheet','Water','Range','M20:R20','ReadVariableNames',false));
% % Distribution of Brackish Water to Gardening and Trade and Crafts
% WDB.RatioForBrackishWater = table2array(readtable(Data,'Sheet','Water','Range','P23:Q23','ReadVariableNames',false));

WDB.Electricity_Drillind_Water_Coeff = WDB.ElectricityConsumptionCoefficients(2,1) + WDB.ElectricityConsumptionCoefficients(6,1); % Electricity water coeff


%% ---------------------------------------- FOOD ------------------------------------------------

% Temp variables
Food_Consumption_RowNames = table2cell(readtable(Data,'Sheet','Food','Range','A5:A68','ReadVariableNames',false))';
Food_Consumption_ColNames = {'Humans and Other - Local','Animals - Local','Humans and Others - Import','Animals - Import'};
Food_Consumption_Row_Num = int32(numel(Food_Consumption_RowNames));
Food_Consumption_Col_Num = int32(numel(Food_Consumption_ColNames));

%%%%%%% For function uses
% Meat rows in the excel table
FDB.meatRows = meatRows;
% Food Loss
FDB.current_food_lost = readmatrix('Data.xlsx','Sheet','Food','Range','S2:S2'); % The assumption was that 33% of the food manufactured is lost 
% {'Local Water For Humans','Local Water For Animals', 'Global Water For Humans', 'Global Water For Animals'}
FDB.WaterFromFoodCategories = WaterFromFoodCategories;

%%%%%%%%%%%% Food Cosnumption
% This is a one-demantional array that contain columns for each year.
% Ideally each cell of it will contain a table with the year data of the number of food. For now its just the first cell that contain the table (for 2019)
FDB.FoodConsumptionCell = cell(1,Years);
FDB.FoodConsumptionCell{1} = array2table(zeros(Food_Consumption_Row_Num,Food_Consumption_Col_Num), 'RowNames', Food_Consumption_RowNames); % Create a table in the first cell for the 2019 data.
FDB.FoodConsumptionCell{1}{:,:} = table2array(readtable(Data,'Sheet','Food','Range','B5:E68','ReadVariableNames',false));
FDB.FoodConsumptionCell{1}.Properties.VariableNames = Food_Consumption_ColNames;
% Insert the row names (types of food) to the DataBase (we could also just
% compare it to "RowNames" that we already defined...)
FDB.FoodRowName = table2cell(readtable(Data,'Sheet','Food','Range','A5:A68','ReadVariableNames',false))';
% the maximal value possible in order to keep the area for food in Israel under 4500000 m^2.
FDB.TotalGrowthForLocalFood = readmatrix('Data.xlsx', 'Sheet','Food','Range','Y2:Y2');  % Save it in the DataBase

%%%%% Water for food percentages (distribution of Nature Water, Diselinated Water, Brackish Water, Reclaimed Water, Flood Water)
FDB.WaterForFoodPercentages = table2array(readtable(Data,'Sheet','Food','Range','T6:T10','ReadVariableNames',false))';

%%%%% Area For food consumption (Area from Food growth) both golbal and local
FDB.AreaCoefficientsLocal = readtable(Data,'Sheet','Food','Range','W4:W67','ReadVariableNames',false);
FDB.AreaCoefficientsLocal = table2array(FDB.AreaCoefficientsLocal);
FDB.AreaCoefficientsGlobal = readtable(Data,'Sheet','Food','Range','X4:X67','ReadVariableNames',false);
FDB.AreaCoefficientsGlobal =table2array(FDB.AreaCoefficientsGlobal);

%%%%%% Calc CO2E For food consumption (Emission Coefficients for KG/KG)
FDB.FoodEmissionCoefficients = table2array(readtable(Data,'Sheet','Food','Range','L3:M66','ReadVariableNames',false));

%$$% Calc Water for Food Consumption 
%Coefficients Water Consumption for Growing the Product m^3/ton
FDB.WaterConsumptionCoefficientsLocal = table2array(readtable(Data,'Sheet','Food','Range','H4:H68','ReadVariableNames',false));
FDB.WaterConsumptionCoefficientsGlobal = table2array(readtable(Data,'Sheet','Food','Range','I4:I68','ReadVariableNames',false));    

%%%%% Organic Waste Amounts - for food
% CH4 Organic Waste Emission Coefficient (kg/kg)
FDB.OrganicWasteCoefficients = table2array(readtable(Data,'Sheet','Food','Range','H80:H80','ReadVariableNames',false));

% Organic Waste Quantity (Ton)
FDB.OrganicWasteAmountsCell = cell(1,Years);
FDB.OrganicWasteAmountsCell{1} = readtable(Data,'Sheet','Food','Range','H73:I76','ReadVariableNames',true);
OrganicWasteAmounts_RowNames = {'Local Authorities', 'Food Industry', 'Agriculture'};
FDB.OrganicWasteAmountsCell{1}.Properties.RowNames = OrganicWasteAmounts_RowNames;

%%%%%% area for food coefficient (m^2/kg)
FDB.AreaForFoodCoefficients = readtable(Data,'Sheet','Food','Range','W3:X67','ReadVariableNames',true);


%% ---------------------------------------- CONSTRUCTION ------------------------------------------------

%%%% temp variables
Construction_RowNames = {'Agriculture', 'Other Public Buildings', 'Helathcare', 'Education', 'Industry and Storage', 'Transportation and Communications', 'Trade', 'Offices', 'Hosting', 'Residential - High-Density Construction', 'Residential - Low-Density Construction', 'Total'};
Construction_Row_Num = int64(numel(Construction_RowNames));

%%%% Construction Settings
%CDB.ConstructionTypes = {'Agriculture', 'Other Public Buildings', 'Helathcare', 'Education', 'Industry and Storage', 'Transportation and Communications', 'Trade', 'Offices', 'Hosting', 'Residential - High-Density Construction', 'Residential - Low-Density Construction', 'Total for Construction', Improted Cement', 'Local Cement' };
CDB.ConstructionTypes = Construction_RowNames;
CDB.MaterialsForConstruction = {'Steel', 'Concrete', 'Asphalt', 'Autoclaved Aerated Concrete', 'Ceramic flooring', 'Gypsum plaster', 'Exterior cladding'};
%CDB.ConstructionEmissionTypes = {'Mining Waste', 'CO2', 'NOX', 'PM10', 'SO2', 'CO2E From Mortar Production'};
CDB.ConstructionEmissionTypes = {'Mining Waste', 'NOX', 'PM10', 'SO2'};

%%%% Consumption table and floor_footprint table 
% (Lidor's add)
CDB.ConstructionTable = array2table(zeros(Construction_Row_Num,Years), 'RowNames', Construction_RowNames);
CDB.ConstructionFootprintTable = array2table(zeros(Construction_Row_Num,Years), 'RowNames', Construction_RowNames);
s1 = "Area for Construction ";
s2 = "Floor Area for Constructure ";
ColumnNames = cell(1,Years);
for i=1:Years
    s3 = num2str(i+BaseYear-1);
    ColumnNames{i} = strcat(s1, s3);
    ColumnNames2{i} = strcat(s2, s3);
end
% Convert column names to string
CDB.ConstructionTable.Properties.VariableNames = cellstr(ColumnNames); 
CDB.ConstructionFootprintTable.Properties.VariableNames = cellstr(ColumnNames2); 
% Put the values to the Base Year (first cell in the years-array)
% The total area
CDB.ConstructionTable{1:(Construction_Row_Num-1), 1} = table2array(readtable(Data,'Sheet','Construction','Range','B3:B13','ReadVariableNames',false));
CDB.ConstructionTable{Construction_Row_Num, 1} = sum(CDB.ConstructionTable{1:(Construction_Row_Num-1), 1});
% The floor area
CDB.ConstructionFootprintTable{1:(Construction_Row_Num-1), 1} = table2array(readtable(Data,'Sheet','Construction','Range','C3:C13','ReadVariableNames',false));
CDB.ConstructionFootprintTable{Construction_Row_Num, 1} = sum(CDB.ConstructionFootprintTable{1:(Construction_Row_Num-1), 1});

%%%% Variables
% Lidor's addition
%CDB.Mining_Waste = readmatrix('Data.xlsx', 'Sheet','Construction','Range','A26:A26');	
CDB.TotalBuiltArea = readmatrix('Data.xlsx', 'Sheet','Construction','Range','H2:H2');   % square kilometer
%Mortar Production Emissions Coefficients - CO2E (KG/KG)
%CDB.MortarProductionCO2ECoefficient = readmatrix('Data.xlsx', 'Sheet','Construction','Range','L36:L36');

%%%%%% Calc Construction Area Emission Coefficient, Material Waste Coefficients, Material consumption
% Waste Coefficients (KG/KG) - Materials that are leftover during the peocess of extracting minerals.
CDB.CostructionEmissionCoefficients = table2array(readtable(Data,'Sheet','Construction','Range','A29:D29','ReadVariableNames',false));

% The required amount needed per Square Meter of contruction (ton/km^2)
%CDB.ConstructionMaterialCoefficients = table2array(readtable(Data,'Sheet','Construction','Range','B19:H19','ReadVariableNames',false));
% Lidor
CDB.ConstructionMaterialCoefficients_HighDensity = table2array(readtable(Data,'Sheet','Construction','Range','B19:H19','ReadVariableNames',false));
CDB.ConstructionMaterialCoefficients_LowDensity = table2array(readtable(Data,'Sheet','Construction','Range','B20:H20','ReadVariableNames',false));
% The ratio between imported and local production of materials in israel
CDB.ConstructionMaterialImprotedRate = table2array(readtable(Data,'Sheet','Construction','Range','B24:H24','ReadVariableNames',false));
CDB.ConstructionMaterialLocalProductionRate = table2array(readtable(Data,'Sheet','Construction','Range','B25:H25','ReadVariableNames',false));
% The emission coefficient per material type (lidor)
CDB.ConstructionECO2Coefficients_ByMaterial = table2array(readtable(Data,'Sheet','Construction','Range','B22:H22','ReadVariableNames',false));

%%%%% Material consumption table (How much Cement for construction)
% Probably will change, due to consideration of apartments construction!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
%CDB.MaterialConsumption = table2array(readtable(Data,'Sheet','Construction','Range','B41:G42','ReadVariableNames',false));





%% ---------------------------------------- MATERIALS ------------------------------------------------

% temp variables
WateAndRecycling_RowNames = {'Organic Products','Plastic', 'Paper', 'Cardboard', 'Diapers', 'Garden Waste', 'Textile', 'Metal', 'Glass', 'Pruned Trees','Wood', 'Oils', 'Others'};
WateAndRecycling_ColNames = {'Local Authorities - Waste', 'Local Authorities - Recycling', 'Industry - Waste', 'Industry - Recycling','Food Industry - Waste','Food Industry - Recycling' ,'Agriculture - Waste', 'Agriculture - Recycling'};
WateAndRecycling_Row_Num = int64(numel(WateAndRecycling_RowNames));
WateAndRecycling_Col_Num = int64(numel(WateAndRecycling_ColNames));

%%% Names Fuel for energy in the industry & others
MDB.FuelConsumption_RowNames = {'Crude Oil Products - For Energy', 'LPG - Home', 'LPG - Commertiel'  };
MDB.FuelConsumption_ColNames = {'Naptha', 'Mazut','Diesel','Kerosene','GWDB.Electricity_Drillind_Wateasoline','Liquified Petroleum Gas', 'Other'};

%%%% Materials - generated waste and recycling - on hold, Need to Update!!!!!!!!!!!!!!!!!!!!!!!!!!!
WateAndRecyclingCell = cell(1,Years);
WateAndRecyclingCell{1} =  array2table(zeros(WateAndRecycling_Row_Num,WateAndRecycling_Col_Num), 'RowNames', WateAndRecycling_RowNames);
WateAndRecyclingCell{1}{:,:} = table2array(readtable(Data,'Sheet','Materials','Range','I4:P16','ReadVariableNames',false));
WateAndRecyclingCell{1}.Properties.VariableNames = WateAndRecycling_ColNames;
MDB.WateAndRecyclingCell = WateAndRecyclingCell;

%%%%% Amounts of Fuels For Industry in tons of oil equivelent
% Need to Update the Data in the excel...!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
MDB.AmountsOfFuelsCells = cell(1,Years); %% including mazut, kerosene and LPG for transportation
MDB.AmountsOfFuelsCells{1} = array2table(zeros(AmountsOfFuels_Row_Num,AmountsOfFuels_Col_Num),'RowNames', AmountsOfFuels_RowNames);
MDB.AmountsOfFuelsCells{1}{1,:} = table2array(readtable(Data,'Sheet','Materials','Range','P45:V45','ReadVariableNames',false));
MDB.AmountsOfFuelsCells{1}{2,:} = table2array(readtable(Data,'Sheet','Materials','Range','P49:V49','ReadVariableNames',false));
MDB.AmountsOfFuelsCells{1}{3,:} = table2array(readtable(Data,'Sheet','Materials','Range','P57:V57','ReadVariableNames',false));
MDB.AmountsOfFuelsCells{1}{4,:} = table2array(readtable(Data,'Sheet','Materials','Range','P41:V41','ReadVariableNames',false));
MDB.AmountsOfFuelsCells{1}{5,6} = table2array(readtable(Data,'Sheet','Materials','Range','R30:R30','ReadVariableNames',false));
MDB.AmountsOfFuelsCells{1}{6,6} = table2array(readtable(Data,'Sheet','Materials','Range','R31:R31','ReadVariableNames',false));
MDB.AmountsOfFuelsCells{1}.Properties.VariableNames = AmountsOfFuels_ColNames;

%%%%%% Calc Consumption emissions 
% CH4 Emission Coefficients from Waste (Kg/Kg)
MDB.ConsumptionEmissionCoefficients = table2array(readtable(Data,'Sheet','Materials','Range','X3:X15','ReadVariableNames',false));
% CH4 Emissions Coefficients from Crude Oil Refining (Kg/Ton)
MDB.CrudeOilRefiningEmissionsCoefficients = readtable(Data,'Sheet','Materials','Range','B41:H46','ReadVariableNames',false);

%%%%%% Calc Waste and recycling  
% Distributionof different materials for Export Waste For Recycling 
MDB.ExportWasteForRecyclingPercentage = table2array(readtable(Data,'Sheet','Materials','Range','I20:I32','ReadVariableNames',false));
    



%% ---------------------------------------- AREA ------------------------------------------------

%%%% Resources - Area
ADB.AreaForSolarEnergyCoefficients = readtable(Data,'Sheet','Area','Range','A1:E33','ReadVariableNames',true, 'ReadRowNames',true);
ADB.RenewablePercents = RenewablePercents;
ADB.RenewablePercents = array2table(ADB.RenewablePercents);
ADB.RenewablePercents.Properties.VariableNames = {'PV','Wind', 'Biomass', 'Thermo Solar'};

% Insert the maximum theoretical efficiency of a solar cell
ADB.LowerBoundForArea = LowerBoundForArea; 
ADB.KWToKwh = readtable(Data,'Sheet','Area','Range','N39:O44','ReadRowNames',true);
ADB.PVType = PVType;

%area distribution
ADB.AreaDistribution = readtable(Data,'Sheet','Area','Range','H1:K6','ReadVariableNames',true, 'ReadRowNames',true);


%% ---------------------------------------- MONEY ------------------------------------------------

MONDB.AreaCostForElectricity = readtable(Data,'Sheet','Money','Range','N37:Q71','ReadVariableNames',true, 'ReadRowNames',true);

% Setting costs (ILS\KW)
MONDB.SettingCosts = readtable(Data,'Sheet','Money','Range','A2:I36','ReadVariableNames',true, 'ReadRowNames',true);
% Operating Costs (ILS\KW)
MONDB.OperatingCosts = readtable(Data,'Sheet','Money','Range','A41:I75','ReadVariableNames',true, 'ReadRowNames',true);
% ILS/Ton Fuel Manufacturing and Fuel Transportation
MONDB.ILSPerTon = readtable(Data,'Sheet','Money','Range','L19:O23','ReadVariableNames',false, 'ReadRowNames',true);



%% ---------------------------------------- RESULTS AND CLEANING ------------------------------------------------

DataBase.Water_DataBase = WDB;
DataBase.Electricity_DataBase = EDB;
DataBase.Trans_DataBase = TDB;
DataBase.Food_DataBase = FDB;
DataBase.Const_DataBase = CDB;
DataBase.Materials_DataBase = MDB;
DataBase.Area_DataBase = ADB;
DataBase.Money_DataBase = MONDB;

%% read the trends in consumption for the target year (empty)- Needs to change!!!!!!!!!!!!!!!!!!
DataBase.ChnageStruct = struct;
DataBase.ChnageStruct.Electricity = readtable("The Three Scenarios.xlsx",'Sheet','ChangesInConsumptionType','Range','A2:B5','ReadRowNames',true);
DataBase.ChnageStruct.Water = readtable("The Three Scenarios.xlsx",'Sheet','ChangesInConsumptionType','Range','A8:B12','ReadRowNames',true);
DataBase.ChnageStruct.Transportation = readtable("The Three Scenarios.xlsx",'Sheet','ChangesInConsumptionType','Range','A15:B21','ReadRowNames',true);
DataBase.ChnageStruct.Food = readtable("The Three Scenarios.xlsx",'Sheet','ChangesInConsumptionType','Range','D2:E65','ReadRowNames',true);

%%%% Delete all the temps
clear Transportation_Consumption_RowNames Transportation_Consumption_Row_Num Vehicle_Amounts_Row_Num Vehicle_Amounts_Col_Num AmountsOfFuels_RowNames AmountsOfFuels_ColNames AmountsOfFuels_Row_Num AmountsOfFuels_Col_Num FuelConsumptionCoefficients_RowNames FuelConsumptionCoefficients_Row_Num FuelConsumptionCoefficients_Col_Num
clear Food_Consumption_RowNames Food_Consumption_ColNames Food_Consumption_Row_Num Food_Consumption_Col_Num
clear Electricity_Consumption_RowNames Electricity_Consumption_Row_Num ElctricityFromNatualGasCoeff_RowNames ElectricityConsumptionForWater_RowNames ElectricityConsumptionForWater_Row_Num
clear Construction_Row_Num Construction_RowNames
clear WateAndRecycling_RowNames WateAndRecycling_ColNames WateAndRecycling_Row_Num WateAndRecycling_Col_Num WateAndRecyclingCell
clear TDB FDB EDB WDB CDB MDB ADB MONDB
clear M FuelConsumptionCoefficients Days_In_Year
clear s1 s2 OrganicWasteAmounts_RowNames PVType BusCarRatio LowerBoundForArea
clear i ColumnNames WaterFromFoodCategories
clear meatRows RenewablePercents ScenarioRowNames EvSenarioLines
clear Conversion_Liter_To_Kg 
clear ColumnNames2 s3 