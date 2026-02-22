%% =====================================================================
%  Plot_Sensitivity_Comparison.m
%  מציג את השפעת ניתוח הרגישות (10%+/-) על פליטות בערים השונות
%  מתמקד בשנים 2035 ו-2050
%% =====================================================================
addpath('helpers');
catOrder = getCityCategorical(AllCities); 
customCityOrder = cellstr(catOrder);
nCities  = numel(customCityOrder);

% הגדרת שנים - המודל רץ מ-2019, לכן:
% 2035 היא שנה מספר 17 (2035-2019 + 1)
% 2050 היא שנה מספר 32 (2050-2019 + 1)
idx2035 = 17;
idx2050 = 32;

% צבעים לגרף (חיובי/שלילי)
posColor = [0.85 0.33 0.10]; % אדום-כתום
negColor = [0.00 0.45 0.74]; % כחול

for i = 1:nCities
    cityName = customCityOrder{i};
    if ~isfield(AllCities, cityName) || ~isfield(AllCities.(cityName), 'Sensitivity_RDB')
        continue; 
    end
    
    SR = AllCities.(cityName).Sensitivity_RDB;
    scenNames = SR.RelevantScenarioNames;
    nScens = numel(scenNames);
    
    % שליפת נתונים - שימוש בטבלה EmissionByScenario שנוצרת ב-runSensitivityAnalysis
    % שורה 1: As-Is, שורה 2: +10%, שורה 3: -10%
    data = SR.EmissionByScenario{:, :}; 
    baseValue = data(1, :);
    plus10    = data(2, :);
    minus10   = data(3, :);
    
    % חישוב אחוז השינוי מה-Base
    percPlus  = ((plus10 - baseValue) ./ baseValue) * 100;
    percMinus = ((minus10 - baseValue) ./ baseValue) * 100;

    %% יצירת הגרף
    fig = figure('Name', ['Sensitivity Analysis - ' cityName], 'Color', 'w', 'Position', [100 100 1000 600]);
    ax = axes(fig);
    hold on;
    
    % ציור העמודות
    bPos = barh(ax, 1:nScens, percPlus, 0.4, 'FaceColor', posColor, 'DisplayName', '+10% Change');
    bNeg = barh(ax, 1:nScens, percMinus, 0.4, 'FaceColor', negColor, 'DisplayName', '-10% Change');
    
    % עיצוב צירים
    set(ax, 'YTick', 1:nScens, 'YTickLabel', scenNames, 'FontSize', 12);
    xlabel('Change in Total Emissions (%)', 'FontSize', 14);
    title(['Sensitivity Analysis: ' cityName ' (Target Year)'], 'FontSize', 16);
    grid on;
    legend('Location', 'northeastoutside');
    
    % הוספת קו אפס
    xline(0, 'k-', 'LineWidth', 1.5);
    
    hold off;
    
    % שמירה
    outPath = fullfile('Results_Plots', 'Sensitivity');
    if ~exist(outPath, 'dir'), mkdir(outPath); end
    saveas(fig, fullfile(outPath, ['Sensitivity_' cityName '.png']));
end