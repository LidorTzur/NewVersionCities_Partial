%% =====================================================================
% Plot_Population_Comparison_Modular.m
% Goal: Produce a modular population comparison chart across multiple years
% Uses existing helper functions from 'helpers' folder.
%% =====================================================================
addpath('helpers');

% --- Modular Configuration ---
% Add or remove years here as needed
targetYears = [2019, 2035, 2050]; 
scen = 'BAU'; 

% --- Get City Order and Info ---
try
    cats_cities = getCityCats(AllCities);
    cityNames = cellstr(cats_cities);
catch
    cityNames = fieldnames(AllCities);
end
nCities = numel(cityNames);

% Get year labels from the first city
firstCity = cityNames{1};
yearLabels = AllCities.(firstCity).BAU_RDB.TotalEmissionSum1.Properties.VariableNames;

%% --- Extract Population Data ---
nYears = numel(targetYears);
popData = zeros(nCities, nYears); 

for i = 1:nCities
    cityName = cityNames{i};
    if isfield(AllCities, cityName)
        C = AllCities.(cityName);
        
        for k = 1:nYears
            yr = targetYears(k);
            % Find the column index for the specific year
            colIdx = find(contains(yearLabels, num2str(yr)), 1);
            
            if ~isempty(colIdx)
                % Use your existing helper function
                popData(i, k) = getPopMillionsByCol(C, colIdx, scen, yearLabels);
            end
        end
    end
end

%% --- Create Plot ---
fig = figure('Name', 'Modular Population Comparison', 'Color', 'w', ...
             'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.7]);

% Create Grouped Bar Chart
b = bar(popData, 'grouped', 'BarWidth', 0.8);

% Set aesthetic colors (dynamic based on number of years)
colors = lines(nYears); 
for k = 1:nYears
    b(k).FaceColor = colors(k, :);
    b(k).DisplayName = num2str(targetYears(k));
    
    % Add Value Labels above bars
    xPos = b(k).XEndPoints;
    yVal = b(k).YData;
    for j = 1:numel(xPos)
        if yVal(j) > 0
            text(xPos(j), yVal(j), sprintf('%.2f', yVal(j)), ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
                'FontSize', 10, 'FontWeight', 'bold');
        end
    end
end

%% --- Axis and Styling ---
set(gca, 'XTick', 1:nCities, 'XTickLabel', cityNames, ...
    'XTickLabelRotation', 45, 'FontSize', 13, 'FontWeight', 'bold');

ylabel('Population (Millions)', 'FontSize', 15, 'FontWeight', 'bold');
title(sprintf('Population Growth Comparison: %s', strjoin(string(targetYears), ' vs ')), ...
      'FontSize', 18, 'FontWeight', 'bold');

grid on;
legend('Location', 'northeastoutside', 'FontSize', 12);

%% --- Save ---
outputDir = 'Results_Plots\Population';
if ~exist(outputDir,'dir'), mkdir(outputDir); end

fileName = sprintf('Population_Comparison_%s.png', strjoin(string(targetYears), '_'));
saveas(fig, fullfile(outputDir, fileName));

disp(['✔ Population comparison chart for ', num2str(targetYears), ' saved successfully.']);