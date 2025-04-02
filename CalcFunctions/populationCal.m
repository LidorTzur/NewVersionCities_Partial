function [population] = populationCal(PrecentegeByTheYears)
% populationCal: This function calculates the population of Israel and the Palestinian Authority over the years.
% It uses the percentage changes for each year provided in the input 'PrecentegeByTheYears'.
% The function creates a table with 4 rows:
%   1. Year index (1 to the target year),
%   2. Actual year (BaseYear + year index),
%   3. Israel's population, calculated by multiplying the starting population by the percentage change for each year,
%   4. Palestinian Authority's population, which is set to 0 for all years (as per the assumption in the code).
% The function populates the table for all years from the BaseYear to the TargetYear.

population_RowNames = {'Num','Years', 'Israel population', 'Palestinian Authority population'};
global TargetYear_global;
global BaseYear;
Years = TargetYear_global-BaseYear+1; 
global PopulationStartYear_global;
global palestinians_base_pop_global; % No palestinian in beer sheva.

%% Inputs 
population_Row_Num = numel(population_RowNames);
population_Column_In_Vector = 1;

%% population data
% Calculate the pupolations over the years
population  = array2table(zeros(population_Row_Num,(Years)));
population.Properties.RowNames = population_RowNames;

% Filling the Data to every year (By option A in the excel Scenario sheet)
for i =1:Years
    population(1,i) = {i};
    population(2,i) = {i+BaseYear-1};
    population(3,i) = {PopulationStartYear_global * PrecentegeByTheYears{population_Column_In_Vector,i}};
    population(4,i) = {palestinians_base_pop_global * PrecentegeByTheYears{population_Column_In_Vector,i}}; 
end
%fprintf('Population table in the pupolationCal is:\n');
%disp(population);
