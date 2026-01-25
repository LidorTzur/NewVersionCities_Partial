%% =====================================================================
% Plot_Population_Comparison.m
% מפיק גרף השוואת אוכלוסייה בין שנת הבסיס לשנת היעד
%% =====================================================================
addpath('helpers');

% --- קביעת סדר ערים עקבי ---
try
    cats_cities = getCityCats(AllCities);
    cityNames = cellstr(cats_cities);
catch
    cityNames = fieldnames(AllCities);
end

nCities = numel(cityNames);
scen = 'BAU'; 

% שליפת תוויות השנים
firstCity = cityNames{1};
yearLabels = AllCities.(firstCity).TotalResults.Properties.VariableNames;
baseYearIdx = 1;          % 2019
targetYearIdx = numel(yearLabels); % 2050

% הכנת מערכים
popData = zeros(nCities, 2); % עמודה 1: 2019, עמודה 2: 2050

for i = 1:nCities
    cityName = cityNames{i};
    if isfield(AllCities, cityName)
        C = AllCities.(cityName);
        popData(i, 1) = getPopMillionsByCol(C, baseYearIdx, scen, yearLabels);
        popData(i, 2) = getPopMillionsByCol(C, targetYearIdx, scen, yearLabels);
    end
end

%% --- יצירת הגרף ---
fig = figure('Name', 'Population Growth Comparison', 'Color', 'w', ...
             'Units', 'normalized', 'Position', [0.1 0.1 0.7 0.7]);

% יצירת גרף עמודות מקובץ (Grouped Bar Chart)
b = bar(popData, 'grouped', 'BarWidth', 0.8);

% הגדרת צבעים (כחול ל-2019, כתום ל-2050)
b(1).FaceColor = [0.2 0.4 0.6]; b(1).DisplayName = '2019 (Base)';
b(2).FaceColor = [0.8 0.4 0.2]; b(2).DisplayName = '2050 (Target)';

% הוספת תוויות מספרים מעל העמודות (בלבן או שחור לפי הצורך)
for k = 1:2
    xPos = b(k).XEndPoints;
    yVal = b(k).YData;
    for j = 1:numel(xPos)
        text(xPos(j), yVal(j), sprintf('%.2f', yVal(j)), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
            'FontSize', 11, 'FontWeight', 'bold');
    end
end

% עיצוב צירים
set(gca, 'XTick', 1:nCities, 'XTickLabel', cityNames, ...
    'XTickLabelRotation', 45, 'FontSize', 14, 'FontWeight', 'bold');

ylabel('Population (Millions)', 'FontSize', 16, 'FontWeight', 'bold');
title('Population Growth: 2019 vs 2050 (Millions)', 'FontSize', 20, 'FontWeight', 'bold');
grid on;
legend('Location', 'northeast', 'FontSize', 14);

% שמירה
outputDir = 'C:\Users\צור\Documents\MATLAB\NewVersionCities_Partial\Results_Plots\Population';
if ~exist(outputDir,'dir'), mkdir(outputDir); end
saveas(fig, fullfile(outputDir, 'Population_Comparison_2019_2050.png'));

%[Image of a grouped bar chart comparing population in 2019 and 2050 for different cities]

disp('✔ גרף השוואת אוכלוסייה הופק ונשמר.');