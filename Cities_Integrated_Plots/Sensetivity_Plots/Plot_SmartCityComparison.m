%% =====================================================================
%  Plot_MultiCity_Sensitivity_EN.m
%  Comparing Sensitivity Analysis results across all cities.
%  Uses data from SR.EmissionByScenario (Row 1: As-Is, Row 2: +10%)
%% =====================================================================

% 1. Automatically detect cities
allCityNames = fieldnames(AllCities);
allCityNames = {'Tlv', 'RishonLeZion', 'BeerSheva', 'Raanana', 'Modiin','Hadera', 'Afula', 'KiryatGat','BeitShemesh', 'MazkeretBatya'};
nCities = numel(allCityNames);
outputDir = 'Results_Plots\Sensitivity Analysis\Smart_Comparison';

% Create directory if it does not exist
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% 2. Get scenario names from the first city
firstCity = allCityNames{1};
if isfield(AllCities.(firstCity), 'Sensitivity_RDB')
    % scenNames = AllCities.(firstCity).Sensitivity_RDB.RelevantScenarioNames;
    % nScens = numel(scenNames);
    scenNames = AllCities.(firstCity).Sensitivity_RDB.EmissionByScenario.Properties.VariableNames;
    % delete specific column
    scenNames([6, 13, 14]) = [];
    nScens = numel(scenNames);
    disp(nScens);
else
    error('Sensitivity_RDB not found. Please run Sensitivity Analysis first.');
end

% Matrix to store the % change for each city and each scenario
% comparisonMatrix = zeros(nCities, nScens); TO CHANGE !!!!!!!!!!!!!!!!!!!!
comparisonMatrix = zeros(nCities, nScens);

%% 3. Extract Sensitivity Data
for i = 1:nCities
    cityName = allCityNames{i};
    C = AllCities.(cityName);
    SR = C.Sensitivity_RDB;
    T = SR.EmissionByScenario;


    % לולאה שעוברת רק על השמות שאישרנו ב-scenNames
    for s = 1:nScens
        targetName = scenNames{s};
        
        % בדיקה אם השם קיים בטבלה של העיר הנוכחית
        if ismember(targetName, T.Properties.VariableNames)
            baseVal = T{1, targetName};
            plusVal = T{2, targetName};
            
            % חישוב והכנסה למטריצה במקום המדויק
            comparisonMatrix(i, s) = ((plusVal - baseVal) / baseVal) * 100;
        else
            % אם העמודה חסרה בעיר הזו - נשים 0
            comparisonMatrix(i, s) = 0;
        end
    end
end

%     % Extract summarized emission table
%     % Row 1: As-Is (Base for sensitivity)
%     % Row 2: +10% Deviation
%     baseValues = SR.EmissionByScenario{1, :};
%     plusValues = SR.EmissionByScenario{2, :};
% 
% 
%     % Calculate % impact relative to the sensitivity base
%     comparisonMatrix(i, :) = ((plusValues - baseValues) ./ baseValues) * 100;
% end

%% 3.1. Filtering Scenarios (Add filtering)
% Define sensitivity threshold - anything below this is considered "negligible"
threshold = 0.2; 
isSignificant = any(abs(comparisonMatrix) > threshold, 1);
filteredMatrix = comparisonMatrix(:, isSignificant);
filteredScenNames = scenNames(isSignificant);
nFilteredScens = numel(filteredScenNames);
fprintf('Filtered out %d scenarios with near-zero impact.\n', nScens - nFilteredScens);

%% 4. Plotting
fig = figure('Name', 'Multi-City Sensitivity Comparison', 'Color', 'w', 'Position', [100 100 1300 750]);
ax = axes(fig);
b = bar(ax, filteredMatrix', 'grouped');
grid on;

% --- Define manual color palette (Professional and contrasting) ---
customColors = [
    0.15, 0.15, 0.50;  % Navy Blue (Tlv)
    0.85, 0.33, 0.10;  % Burnt Orange (RishonLeZion)
    0.10, 0.60, 0.20;  % Forest Green (BeerSheva)
    0.45, 0.20, 0.60;  % Deep Purple (Raanana)
    0.00, 0.75, 0.75;  % Turquoise (Modiin)
    0.65, 0.10, 0.10;  % Wine Red (Hadera)
    0.95, 0.75, 0.00;  % Mustard Yellow (Afula)
    0.40, 0.40, 0.40;  % Dark Gray (KiryatGat)
    0.20, 0.80, 0.50;  % Mint Green (BeitShemesh)
    0.60, 0.40, 0.20   % Chocolate Brown (MazkeretBatya)
];

% Professional Styling
set(ax, 'XTick', 1:nFilteredScens, ...
        'XTickLabel', filteredScenNames, ...
        'TickLabelInterpreter', 'none', ...
        'FontSize', 11, ...            % General axis font size
        'FontWeight', 'bold', ...      % Bold text
        'XColor', [0 0 0]);            % Strong black color for axis

xtickangle(45); 

% Apply colors to bars
for k = 1:nCities
    b(k).FaceColor = customColors(k,:);
    b(k).EdgeColor = [0.1 0.1 0.1]; % Thin black outline for clean separation
    b(k).LineWidth = 0.8;
end

% --- Enhance Y-Axis Label ---
ylabel('\Delta Total Emissions [%] (for \DeltaParam = +10%)', ...
       'FontSize', 14, ...
       'FontWeight', 'bold', ...
       'Interpreter', 'tex');

title('Sensitivity Comparison: Impact of Significant Parameters', 'FontSize', 16, 'FontWeight', 'bold');
legend(allCityNames, 'Location', 'northeastoutside', 'FontSize', 10);

formulaStr = {'\textbf{Calculation Formula:}', ...
              '', ...
              '$\displaystyle \mathbf{\Delta E [\%] = \left( \frac{E_{p+10\%} - E_{base}}{E_{base}} \right) \times 100}$'};
          
% Create textbox - note the changes in FontSize and FitBoxToText
annotation('textbox', [0.72, 0.12, 0.26, 0.13], ... 
           'String', formulaStr, ...
           'FontSize', 14, ...            % Significantly increased font size
           'BackgroundColor', 'w', ...
           'EdgeColor', 'k', ...
           'LineWidth', 1.2, ...
           'Interpreter', 'latex', ...
           'VerticalAlignment', 'middle', ...
           'Margin', 5);

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
fileName = 'MultiCity_Sensitivity_Comparison.png';
fullFilePath = fullfile(outputDir, fileName);
saveas(fig, fullFilePath);
fprintf('Successfully saved comparison plot to: %s\n', fullFilePath);