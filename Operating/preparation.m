
%% General Inputs
Days_In_Year = 365;
global TargetYear_global;
TargetYear_global = 2050;
global BaseYear;
BaseYear = 2019;
ScenarioNumber = 19; % For 2035 - water saving
Years = TargetYear_global-BaseYear+1; % Years between Base year to target
Conversion_Liter_To_Kg = 0.85;

%% Lidor: population data, for the "populationCal" script
global PopulationStartYear_global;
PopulationStartYear_global = readtable(Data, 'Sheet', 'Population', 'Range', 'L17:L17', 'ReadVariableNames', false);
PopulationStartYear_global = table2array(PopulationStartYear_global); 
PopulationStartYear_global = PopulationStartYear_global(1); 
PopulationStartYear_global = double(PopulationStartYear_global); 
PopulationStartYear_global = PopulationStartYear_global / 1000000; 
global palestinians_base_pop_global;
palestinians_base_pop_global = double(0);

% global GrowthRate_global;
% GrowthRate_global = readtable(Data, 'Sheet', 'Population', 'Range', 'I35:I35', 'ReadVariableNames', false);
% GrowthRate_global = table2array(GrowthRate_global); 
% GrowthRate_global = GrowthRate_global{1}; 
% GrowthRate_global = str2double(GrowthRate_global); 
% GrowthRate_global = 1 + GrowthRate_global; 

%% Food
% meat rows in the excel
meatRows = [53, 54, 55, 56, 57, 59, 60, 61];
WaterFromFoodCategories = {'Local Water For Humans','Local Water For Animals', 'Global Water For Humans', 'Global Water For Animals'};

% PV Data
% The maximum theoretical efficiency of a solar cell using a single p-n junction to collect power from the cell where the only loss mechanism is radiative recombination in the solar cell.
LowerBoundForArea = 6; %% according to shockley-queisser limit
PVType = 'Dual';
RenewablePercents = [1 0 0 0];

% EV scenario rows number of electric vehicles
EvSenarioLines = [14 15 16 17];

% The emission table from transportation settings
%TransEmissionNumRows = 15;
%TransEmissionNumCols = 7; 

%% Scenario Table

ScenarioRowNames = {'Population Growth', 'Increased Electricity Per Capita', 'Increase in Desalinared Water', ...
    'Reducing Beef Consumption', 'Preventing Food Loss', 'Change In Energy Consumption From Renewable Energies', ...
    'Electricity Production by Natural Gas', 'Electricity Saving', 'Fuel for Energy', 'Recycled Waste', 'Burning Waste', ...
    'Reduction Of Mileage', 'Transition To Public Transportation', 'Transition to Electric Car', 'Transition to Electric Van', ...
    'Transition to Electric Truck', 'Transition to Electric Bus', '18', 'Water Saving', 'Vegetarians'};

% for SensitivityAnalysis (in runningSteps) - Needs to be Changed!!!!!!!!!!!!!!
%PopulationGrowth = {0, 0.45, 0.9};
%ElectricityPerCapita = {0, 0.2, 0.41};
%DesalinatedWater = {0,1.32,2.64};

% Analysis
% AllButOneAnalysis_Variable_Num = 9;
% AllButOneAnalysis_Variable_Names ={'Emissions', 'Emissions - Global', 'Emissions - Local', 'Water', 'Water - Global', 'Water - Local', 'Area', 'Area - Global', 'Area - Local'};
% OnlyOneAnalysis_Variable_Num = 9;
% OnlyOneAnalysis_Variable_Names = {'Emissions', 'Emissions - Global', 'Emissions - Local', 'Water', 'Water - Global', 'Water - Local', 'Area', 'Area - Global', 'Area - Local'};
% Analysis_Row_Names = {'Population Growth', 'Increase In Electricity Per Capita', 'Increase in Desalinated Water', 'Reducing Beef Consumption', 'Preventing Food Loss', 'Change In Energy Consumption From Renewable Energies', 'Electricity Production by Natural Gas','Electricity Saving', 'Waste Minimization','Recycle Waste', '11', 'Reducing Mileage', 'Transition To Public Transportation', 'Transition to Electric Car', 'Transition to Electric Van', 'Transition to Electric Truck', 'Transition to Electric Bus','18', 'Water Saving', 'Vegetarians'};

% Upload the Scenarios table
ScenariosAndValues = readtable("The Three Scenarios.xlsx",'Sheet','Scenarios','Range','A1:J21','ReadRowNames',true,'ReadVariableNames',true);

% Run this two scripts
ReadValues;
TechnologicalImprovements;  

%% Analysis 
% AllButOneAnalysis = array2table(zeros(height(ScenariosAndValues),AllButOneAnalysis_Variable_Num));
% AllButOneAnalysis.Properties.RowNames = Analysis_Row_Names;
% AllButOneAnalysis.Properties.VariableNames = AllButOneAnalysis_Variable_Names;
% OnlyOneAnalysis = array2table(zeros(height(ScenariosAndValues),OnlyOneAnalysis_Variable_Num));
% OnlyOneAnalysis.Properties.RowNames = Analysis_Row_Names;
% OnlyOneAnalysis.Properties.VariableNames = OnlyOneAnalysis_Variable_Names;

% %% Lidor: In the "populationCal" script - not sure if we need it here too
% population_RowNames = {'Num','Years', 'Israel population', 'Palestinian Authority population'};
% population  = array2table(zeros(numel(population_RowNames),Years));
% population.Properties.RowNames = population_RowNames;
% 
% % Filling the Data to every year (By option A in the excel sheet)
% for i =1:Years
%     population(1,i) = {i};
%     population(2,i) = {i+BaseYear-1};
%     population(3,i) = {PopulationStartYear_global*GrowthRate_global^(i-1)};
%     population(4,i) = {palestinians_base_pop_global*0^(i-1)}; % No palestinian in beer sheva..
% end
% 
% fprintf('Population table in the main is:\n');
% disp(population);


beep;
clear i 