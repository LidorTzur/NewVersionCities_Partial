%% =====================================================================
%  Plot_CityEfficiencyRanking_EN.m
%  Generic script to visualize Emission Elasticity across all cities.
%  Identifies how sensitive a city's footprint is to population growth.
%% =====================================================================

% 1. Automatically detect all cities in the AllCities structure
allCityNames = fieldnames(AllCities);
nCities = numel(allCityNames);

% 2. Identify Population index from the first available city
firstCity = allCityNames{1};
if isfield(AllCities.(firstCity), 'Sensitivity_RDB')
    scenNames = AllCities.(firstCity).Sensitivity_RDB.RelevantScenarioNames;
    popIdx = find(contains(scenNames, 'population', 'IgnoreCase', true));
else
    error('Sensitivity_RDB not found. Please run Sensitivity Analysis (Case 2) first.');
end

% Initialize efficiency index array
% deviationDir = 2 represents the +10% deviation row in SR.EmissionByScenario
deviationDir = 2; 
efficiencyIndex = zeros(nCities, 1);

%% 3. Data Processing
for i = 1:nCities
    cityName = allCityNames{i};
    C = AllCities.(cityName);
    SR = C.Sensitivity_RDB;
    
    % Access summarized emission table: Row 1 (Base) | Row 2 (+10% Pop)
    baseVal = SR.EmissionByScenario{1, popIdx};
    plusVal = SR.EmissionByScenario{2, popIdx};
    
    % Calculate % Change in total emissions
    percChange = ((plusVal - baseVal) ./ baseVal) * 100;
    
    % Calculate Elasticity Index (Efficiency)
    % We divide by 10 because the input deviation was 10%
    efficiencyIndex(i) = percChange / 10; 
end

%% 4. Visualization: Efficiency Ranking
fig = figure('Name', 'City Efficiency Ranking', 'Color', 'w', 'Position', [100 100 900 600]);
ax = axes(fig);

% Sort from most efficient (lowest index) to least efficient
[sortedIndex, sortIdx] = sort(efficiencyIndex, 'ascend');
sortedCities = allCityNames(sortIdx);

b = bar(ax, categorical(sortedCities, sortedCities), sortedIndex, 'FaceColor', [0.2 0.4 0.6]);
grid on;

% Professional Labels
ylabel('Emission Elasticity (\Delta% Total Emissions / 1% \DeltaPopulation)', 'FontWeight', 'bold');
title('City Efficiency Ranking: Population Impact Index', 'FontSize', 14);
subtitle('Lower Index = Higher Efficiency (Decoupling Growth from Emissions)');

% Add value labels on top of bars
xtips = b.XEndPoints;
ytips = b.YEndPoints;
labels = string(round(sortedIndex, 2));
text(xtips, ytips, labels, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

% Add explanatory text box
annotation('textbox', [0.15, 0.75, 0.35, 0.1], 'String', ...
    {'Index Interpretation:', ...
     '• 1.00: Emissions grow exactly with population', ...
     '• < 1.00: Efficiency/Decoupling achieved', ...
     '• > 1.00: Increasing intensity per capita'}, ...
    'FitBoxToText', 'on', 'BackgroundColor', 'w', 'FaceAlpha', 0.8);

%% 5. Saving Results
outputDir = 'Results_Plots\Comparison';
if ~exist(outputDir, 'dir'), mkdir(outputDir); end
saveas(fig, fullfile(outputDir, 'City_Efficiency_Ranking_EN.png'));