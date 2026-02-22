%% =====================================================================
%  Plot_MultiCity_Scenario_Comparison_Visible.m
%  Generates comparative charts for each scenario.
%  Each chart shows how a +10% change affects all detected cities.
%% =====================================================================

% 1. Automatically detect all cities
allCityNames = fieldnames(AllCities);
nCities = numel(allCityNames);

% 2. Get scenario names from the first available city
firstCity = allCityNames{1};
if isfield(AllCities.(firstCity), 'Sensitivity_RDB')
    scenNames = AllCities.(firstCity).Sensitivity_RDB.RelevantScenarioNames;
    nScens = numel(scenNames);
else
    error('Sensitivity_RDB not found. Ensure Option 2 (Sensitivity) was executed.');
end

% Set output directory
outputDir = 'Results_Plots\Scenario_Comparisons';
if ~exist(outputDir, 'dir'), mkdir(outputDir); end

% deviationDir = 2 represents the +10% deviation row
deviationDir = 2; 

%% 3. Loop through each Scenario and create a comparison plot
for s = 1:nScens
    currentScen = scenNames{s};
    impactValues = zeros(nCities, 1);
    
    % Collect impact data
    for i = 1:nCities
        cityName = allCityNames{i};
        SR = AllCities.(cityName).Sensitivity_RDB;
        
        baseVal = SR.EmissionByScenario{1, s};
        plusVal = SR.EmissionByScenario{deviationDir, s};
        
        impactValues(i) = ((plusVal - baseVal) / baseVal) * 100;
    end
    
    % --- Create Figure (Now Visible) ---
    fig = figure('Name', ['Comparison - ' currentScen], ...
                 'Color', 'w', 'Position', [200 200 800 500], ...
                 'Visible', 'on'); % CHANGED TO ON
    ax = axes(fig);
    
    % Sort cities by impact for better readability
    [sortedImpact, sortIdx] = sort(impactValues, 'descend');
    sortedCityNames = allCityNames(sortIdx);
    
    b = bar(ax, categorical(sortedCityNames, sortedCityNames), sortedImpact, 'FaceColor', [0.15 0.35 0.55]);
    grid on;
    
    % Styling
    ylabel('Impact on Total Emissions (%)', 'FontWeight', 'bold');
    title(['Comparison: Sensitivity to ' currentScen], 'FontSize', 14);
    subtitle('Impact of +10% Parameter Change on Total City Footprint');
    
    % Add value labels
    xtips = b.XEndPoints;
    ytips = b.YEndPoints;
    labels = string(round(sortedImpact, 2)) + '%';
    text(xtips, ytips, labels, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    
    % Refresh drawing so you can see it
    drawnow; 
    
    % Save each scenario as a separate file
    safeName = strrep(currentScen, ' ', '_');
    saveas(fig, fullfile(outputDir, ['Comparison_' safeName '.png']));
    
    % Keep the figure open for a brief moment or close it manually if preferred
    % pause(1); % Optional: adds a 1-second delay so you can see each one
end

fprintf('✔ Generated %d comparison charts in: %s\n', nScens, outputDir);