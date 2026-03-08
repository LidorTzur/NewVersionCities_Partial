
Data = excelFile;
scenarios = scenariosFile;

%% ------------------------------------------------------  Inputs ------------------------------------------------------

%% General Inputs
Days_In_Year = 365;
global TargetYear_global;
TargetYear_global = 2050;
global BaseYear;
BaseYear = 2019;
Years = TargetYear_global-BaseYear+1; % Years between Base year to target
Conversion_Liter_To_Kg = 0.85;
% Order to print
manualOrder = { ...
    'Tlv', 'RishonLeZion', 'BeerSheva', ...    % Major hubs
    'Raanana', 'Modiin', ...                   % High Socio-economic / Suburbs
    'Hadera', 'Afula', 'KiryatGat', ...        % Rapid development / Periphery
    'BeitShemesh', 'MazkeretBatya' ...         % Religious / Rural-Community
};

%% Lidor: population data, for the "populationCal" script
global PopulationStartYear_global;
PopulationStartYear_global = readtable(Data, 'Sheet', 'Population', 'Range', 'L17:L17', 'ReadVariableNames', false);
PopulationStartYear_global = table2array(PopulationStartYear_global); 
PopulationStartYear_global = double(PopulationStartYear_global(1)) / 1000000; 
global palestinians_base_pop_global;
palestinians_base_pop_global = double(0);

%% Food Inputs
% meat rows in the excel
meatRows = [53, 54, 55, 56, 57, 59, 60, 61];
WaterFromFoodCategories = {'Local Water For Humans (m^3)','Local Water For Animals (m^3)', 'Global Water For Humans (m^3)', 'Global Water For Animals (m^3)'};

%% PV Data
% The maximum theoretical efficiency of a solar cell using a single p-n junction to collect power from the cell where the only loss mechanism is radiative recombination in the solar cell.
LowerBoundForArea = 6; %% according to shockley-queisser limit
PVType = 'Dual';
RenewablePercents = [1 0 0 0]; % Only pv

%% EV scenario rows number of electric vehicles
EvSenarioLines = [14 15 16 17];

%% Scenario Table
ScenarioRowNames = {'Population Growth', 'Increased Electricity Per Capita', 'Increase in Desalinared Water', ...
    'Reducing Beef Consumption', 'Preventing Food Loss', 'Change In Energy Consumption From Renewable Energies', ...
    'Electricity Production by Natural Gas', 'Electricity Saving', 'Fuel for Energy', 'Recycled Waste', 'Burning Waste', ...
    'Reduction Of Mileage', 'Transition To Public Transportation', 'Transition to Electric Car', 'Transition to Electric Van', ...
    'Transition to Electric Truck', 'Transition to Electric Bus', 'vehicles with improved emission factors', 'Water Saving', 'Vegetarians', 'Change in Building High-Density Type Distribution', ...
    'Change in FloorPrint High-Density','Change in FloorPrint Low-Density', 'Change in Construction Green Materials' ,...
    'Num of floors - Agriculture','Num of floors - Other Public Buildings','Num of floors - Healthcare', ...
    'Num of floors - Education','Num of floors - Industry and Storage','Num of floors - Transportation and Communications', ...
    'Num of floors - Trade','Num of floors - Offices','Num of floors - Hosting'};

%% Upload the Scenarios table
global ScenariosAndValues
ScenariosAndValues = readtable(scenarios,'Sheet','Scenarios','Range','A1:J34','ReadRowNames',true,'ReadVariableNames',true);


%% ------------------------------------------------------ Run this two scripts 
ReadValues;
TechnologicalImprovements;  


beep;
clear i 