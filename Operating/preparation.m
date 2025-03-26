
%% General Inputs
global TargetYear_global;
TargetYear_global = 2050;
global BaseYear;
BaseYear = 2019;
ScenarioNumber = 19; % For 2035 - water saving
Years = TargetYear_global-BaseYear+1; %השנים שבין שנת הבסיס לשנת המטרה

%% Lidor: population data, for the "populationCal" script
global PopulationStartYear_global;
PopulationStartYear_global = readtable(Data, 'Sheet', 'Population', 'Range', 'L17:L17', 'ReadVariableNames', false);
PopulationStartYear_global = table2array(PopulationStartYear_global); 
PopulationStartYear_global = PopulationStartYear_global(1); 
PopulationStartYear_global = double(PopulationStartYear_global); 
PopulationStartYear_global = PopulationStartYear_global / 1000000; 
global palestinians_base_pop_global;
palestinians_base_pop_global = double(0);

global GrowthRate_global;
GrowthRate_global = readtable(Data, 'Sheet', 'Population', 'Range', 'I35:I35', 'ReadVariableNames', false);
GrowthRate_global = table2array(GrowthRate_global); 
GrowthRate_global = GrowthRate_global{1}; 
GrowthRate_global = str2double(GrowthRate_global); 
GrowthRate_global = 1 + GrowthRate_global; 


%% Food lost
% The assumption was that 33% of the food manufactured is lost
global current_food_lost_global;
current_food_lost_global = 1/3;  

%% Waste incinaration values 
WasteToElectricity = 0.807; % How much waste needed to burn to get 1 kWh of electricity
IncinarationEmissionCoefficient = 1.01; % Emission coefficient of waste incineration

%% Transition to buses and trains 
TransitionToBus = 0.5;
TransitionToTrain = 1- TransitionToBus;

%% PV Data
% The maximum theoretical efficiency of a solar cell using a single p-n junction to collect power from the cell where the only loss mechanism is radiative recombination in the solar cell.
LowerBoundForArea = 6; %% according to shockley-queisser limit
PVType = 'Dual';

%% Number of rides per day we determine
global RidesPerDay_global;
RidesPerDay_global = 4;

% Define the ratio between car to bus use
global BusCarRatio_global
BusCarRatio_global = readtable(Data,'Sheet','TransportationConsumption','Range','B24:B24','ReadVariableNames',false);
BusCarRatio_global = BusCarRatio_global{1,1}; 

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

% Lidor: In the "populationCal" script - not sure if we need it here too
population  = array2table(zeros(4,Years));
population_RowNames = {'Num','Years', 'Israel population', 'Palestinian Authority population'};
pop.Properties.RowNames = population_RowNames;
% Filling the Data to every year (By option A in the excel sheet)
for i =1:Years
    population(1,i) = {i};
    population(2,i) = {i+BaseYear-1};
    population(3,i) = {PopulationStartYear_global*GrowthRate_global^(i-1)};
    population(4,i) = {palestinians_base_pop_global*0^(i-1)}; % No palestinian in beer sheva..
end

beep;