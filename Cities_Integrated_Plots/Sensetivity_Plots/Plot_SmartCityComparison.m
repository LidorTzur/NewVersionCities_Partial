%% =====================================================================
%  Plot_MultiCity_Sensitivity_EN.m
%  Comparing Sensitivity Analysis results across all cities.
%  Uses data from SR.EmissionByScenario (Row 1: As-Is, Row 2: +10%)
%% =====================================================================

% 1. Automatically detect cities
allCityNames = fieldnames(AllCities);
nCities = numel(allCityNames);

% 2. Get scenario names from the first city
firstCity = allCityNames{1};
if isfield(AllCities.(firstCity), 'Sensitivity_RDB')
    scenNames = AllCities.(firstCity).Sensitivity_RDB.RelevantScenarioNames;
    nScens = numel(scenNames);
else
    error('Sensitivity_RDB not found. Please run Sensitivity Analysis first.');
end

% Matrix to store the % change for each city and each scenario
% 
comparisonMatrix = zeros(nCities, nScens);

%% 3. Extract Sensitivity Data
for i = 1:nCities
    cityName = allCityNames{i};
    C = AllCities.(cityName);
    
    % Access the Sensitivity results structure
    SR = C.Sensitivity_RDB;
    
    % Extract summarized emission table
    % Row 1: As-Is (Base for sensitivity)
    % Row 2: +10% Deviation
    baseValues = SR.EmissionByScenario{1, :};
    plusValues = SR.EmissionByScenario{2, :};
    
    % Calculate % impact relative to the sensitivity base
    comparisonMatrix(i, :) = ((plusValues - baseValues) ./ baseValues) * 100;
end

%% 4. Plotting
fig = figure('Name', 'Multi-City Sensitivity Comparison', 'Color', 'w', 'Position', [100 100 1200 700]);
ax = axes(fig);

b = bar(ax, comparisonMatrix', 'grouped');
grid on;

% Professional Styling
set(ax, 'XTick', 1:nScens, 'XTickLabel', scenNames, 'TickLabelInterpreter', 'none');
xtickangle(45);
ylabel('Impact on Total Emissions (%)', 'FontSize', 12, 'FontWeight', 'bold');
title('Sensitivity Comparison: Impact of +10% Change in Parameters', 'FontSize', 14);
legend(allCityNames, 'Location', 'northeastoutside');

% Add value labels for clarity
if nCities < 5
    for i = 1:nCities
        xtips = b(i).XEndPoints;
        ytips = b(i).YEndPoints;
        labels = string(round(comparisonMatrix(i,:), 1)) + '%';
        text(xtips, ytips, labels, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'FontSize', 8);
    end
end

%% 5. Save Output
outputDir = 'Results_Plots\Comparison';
if ~exist(outputDir, 'dir'), mkdir(outputDir); end
saveas(fig, fullfile(outputDir, 'MultiCity_Sensitivity_Comparison.png'));