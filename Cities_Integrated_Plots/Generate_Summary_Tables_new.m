%% =====================================================================
% Generate_Summary_Tables_Generic.m
% Generates 3 summary tables (Long, Wide, Diffs) with "_2035" suffix
% Supported Years: 2019 (Baseline), 2035 (Mid-term), 2050 (Target)
%% =====================================================================

% --- Basic Setup ---
cityNames = fieldnames(AllCities);
cities    = struct2cell(AllCities);
nCities   = numel(cities);
scenarios = {'BAU','Moderate','Advanced'};

% --- Configuration ---
yearsToExport = [2019, 2030, 2040]; 
startYear     = 2019; % Baseline year (Matrix Column 1)
colsToExtract = yearsToExport - startYear + 1;

%% --- Define Metrics based on TotalResults row mapping ---
rows.Emission_Local  = [1 2 3];
rows.Emission_Global = [4 5 6];
rows.Emission_Total  = [7 8 9];
rows.Area_Local      = [10 11 12];
rows.Area_Global     = [13 14 15];
rows.Area_Total      = [16 17 18];
rows.Water_Local     = [19 20 21];
rows.Water_Global    = [22 23 24];
rows.Water_Total     = [25 26 27];
metrics = fieldnames(rows);

% Ensure the output directory exists
if ~exist('Results_Plots', 'dir'), mkdir('Results_Plots'); end

%% =====================================================================
% 1) Create SummaryTable (Long Format)
%% =====================================================================
summaryRows = {};
for c = 1:nCities
    TR = cities{c}.TotalResults;
    for s = 1:numel(scenarios)
        scen = scenarios{s};
        for m = 1:numel(metrics)
            rset = rows.(metrics{m});
            r    = rset(s);
            
            % Extract the values for the selected years
            rawVals = TR(r, colsToExtract);
            
            % Handle table vs numeric/cell extraction to prevent assignment errors
            if istable(rawVals)
                yearVals = table2cell(rawVals);
            elseif isnumeric(rawVals)
                yearVals = num2cell(rawVals);
            else
                yearVals = rawVals; 
            end
            
            % Build row: Concatenate metadata with the year values
            summaryRows(end+1, :) = [ {cityNames{c}, scen, metrics{m}}, yearVals ];
        end
    end
end

% Define dynamic header names
yearColNames = arrayfun(@(y) ['Year_', num2str(y)], yearsToExport, 'UniformOutput', false);
varNames = [ {'City','Scenario','Metric'}, yearColNames ];

SummaryTable = cell2table(summaryRows, 'VariableNames', varNames);
writetable(SummaryTable, 'Results_Plots/SummaryTable_Long_2030.xlsx');
disp('✔ SummaryTable_Long_2030.xlsx saved successfully.');

%% =====================================================================
% 2) Create SummaryWide (Wide Format)
%% =====================================================================
wideRows = {};      
wideVals = [];      
for s = 1:numel(scenarios)
    for m = 1:numel(metrics)
        metric = metrics{m};
        rowVals = [];
        for c = 1:nCities
            TR = cities{c}.TotalResults;
            r  = rows.(metric)(s);
            
            % Extract values and ensure they are converted to a numeric array
            rawCityVals = TR(r, colsToExtract);
            if istable(rawCityVals)
                cityVals = table2array(rawCityVals);
            elseif iscell(rawCityVals)
                cityVals = cell2mat(rawCityVals);
            else
                cityVals = rawCityVals;
            end
            
            rowVals = [rowVals, cityVals];
        end
        wideRows(end+1,:) = {scenarios{s}, metric};
        wideVals(end+1,:) = rowVals;
    end
end

% Create column names using the pattern: CityName_Year
safeCityNames = regexprep(cityNames,'[^a-zA-Z0-9]','_');
wideColNames = {};
for c = 1:nCities
    for y = yearsToExport
        wideColNames{end+1} = [safeCityNames{c}, '_', num2str(y)];
    end
end

SummaryWide = cell2table(wideRows, 'VariableNames', {'Scenario','Metric'});
SummaryWide = [SummaryWide array2table(wideVals, 'VariableNames', wideColNames)];
writetable(SummaryWide, 'Results_Plots/SummaryTable_Wide_2030.xlsx');
disp('✔ SummaryTable_Wide_2030.xlsx saved successfully.');

%% =====================================================================
% 3) Create SummaryDiffs (City Differences)
%% =====================================================================
diffVals  = [];
diffNames = {};
for i = 1:nCities-1
    for j = i+1:nCities
        for y = yearsToExport
            valTag = num2str(y);
            colA = [safeCityNames{i}, '_', valTag];
            colB = [safeCityNames{j}, '_', valTag];
            
            diffName = [safeCityNames{i}, '_minus_', safeCityNames{j}, '_', valTag];
            diffNames{end+1} = diffName;
            
            % Compute the difference between the two city columns
            diffVals(:,end+1) = SummaryWide.(colA) - SummaryWide.(colB);
        end
    end
end

SummaryDiffs = [SummaryWide(:,1:2), array2table(diffVals, 'VariableNames', diffNames)];
writetable(SummaryDiffs, 'Results_Plots/SummaryTable_Diffs_2030.xlsx');

disp('✔ SummaryTable_Diffs_2030.xlsx saved successfully.');
disp(['✔ All tables generated for years: ', strjoin(string(yearsToExport), ', ')]);