% %% =====================================================================
% %  Plot_CityEfficiencyRanking_EN.m
% %  מתוקן: גישה ישירה לפי שורה 3 והכפלה במיליון
% %% =====================================================================
% 
% % 1. הגדרת רשימת הערים
% allCityNames = {'Tlv', 'RishonLeZion', 'BeerSheva', 'Raanana', 'Modiin', ...
%                 'Hadera', 'Afula', 'KiryatGat', 'BeitShemesh', 'MazkeretBatya'};
% nCities = numel(allCityNames);
% 
% % 2. הגדרת אינדקסים קבועים (לפי מה שהגדרת)
% popIdx = 4; % העמודה ב-Sensitivity שמייצגת את האוכלוסייה (שורה 3 בנתונים)
% deviationDir = 2; % שורה 2 ב-Sensitivity מייצגת +10%
% 
% efficiencyIndex = zeros(nCities, 1);
% actualPopulationBase = zeros(nCities, 1);
% 
% %% 3. Data Processing
% for i = 1:nCities
%     cityName = allCityNames{i};
%     C = AllCities.(cityName);
% 
%     % בדיקת קיום נתונים
%     if ~isfield(C, 'Sensitivity_RDB') || ~isfield(C, 'BAU_RDB')
%         continue;
%     end
% 
%     % --- שליפת אוכלוסייה משורה 3 ועמודה אחרונה (השנה הכי רחוקה) ---
%     targetYearCol = size(C.BAU_RDB.population, 2);
%     % הכפלה במיליון לפי הגדרתך
%     popRawValue = C.BAU_RDB.population{3, targetYearCol}; 
%     actualPopulationBase(i) = popRawValue * 1000000; 
% 
%     % --- שליפת פליטות מניתוח הרגישות ---
%     SR = C.Sensitivity_RDB;
% 
%     % גישה ישירה לפי popIdx שקבענו כ-3
%     baseVal = SR.EmissionByScenario{1, popIdx};
%     plusVal = SR.EmissionByScenario{2, popIdx};
% 
%     % חישוב אחוז השינוי
%     % אם זה עדיין 0, נבדוק אם יש בכלל הבדל בין השורות ב-Table
%     percChange = ((plusVal - baseVal) / baseVal) * 100;
% 
%     % חישוב אינדקס האלסטיות (חלוקה ב-10 אחוז סטייה)
%     efficiencyIndex(i) = percChange / 10; 
% 
%     fprintf('City: %-15s | Pop: %12.0f | Index: %.4f\n', ...
%             cityName, actualPopulationBase(i), efficiencyIndex(i));
% end
% 
% %% 4. Visualization
% fig = figure('Name', 'City Efficiency Ranking', 'Color', 'w', 'Position', [100 100 1000 650]);
% ax = axes(fig);
% 
% [sortedIndex, sortIdx] = sort(efficiencyIndex, 'ascend');
% sortedCities = allCityNames(sortIdx);
% 
% b = bar(ax, categorical(sortedCities, sortedCities), sortedIndex, 'FaceColor', [0.2 0.4 0.6]);
% grid on;
% 
% ylabel('Emission Elasticity (\Delta% Emissions / 1% \DeltaPopulation)');
% title('City Efficiency Ranking: Population Impact Index', 'FontSize', 14);
% subtitle(['Based on Row 3 Population Data (x1,000,000) | Year Index: ', num2str(targetYearCol)]);
% 
% % הוספת ערכים מעל העמודות
% text(b.XEndPoints, b.YEndPoints, string(round(sortedIndex, 3)), ...
%     'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
% 
% % קו ייחוס ב-1.0
% hold on;
% yline(1.0, '--r', 'Linear Scaling (1.0)', 'LineWidth', 1.5);
% 
% %% 5. Save
% outputDir = fullfile('Results_Plots', 'Comparison');
% if ~exist(outputDir, 'dir'), mkdir(outputDir); end
% saveas(fig, fullfile(outputDir, 'City_Efficiency_Ranking_Fixed.png'));





%% =====================================================================
%  Plot_AllSensitivities_Comparison.m
%  מפיק גרפי השוואה לכל התרחישים - גרסה עם תצוגה
%% =====================================================================

% 1. הגדרת רשימת הערים
allCityNames = {'Tlv', 'RishonLeZion', 'BeerSheva', 'Raanana', 'Modiin', ...
                'Hadera', 'Afula', 'KiryatGat', 'BeitShemesh', 'MazkeretBatya'};
nCities = numel(allCityNames);

% 2. זיהוי רשימת התרחישים
firstCity = allCityNames{1};
scenNames = AllCities.(firstCity).Sensitivity_RDB.RelevantScenarioNames;
nScenarios = numel(scenNames);

% הגדרת השנה (לפי עמודה אחרונה ב-BAU)
targetYearCol = size(AllCities.(firstCity).BAU_RDB.population, 2);
actualYear = 2019 + (targetYearCol - 1);

fprintf('Starting to generate %d plots...\n', nScenarios);

%% 3. לולאת תרחישים
for s = 1:nScenarios
    scenarioName = scenNames{s};
    efficiencyIndex = zeros(nCities, 1);
    
    for i = 1:nCities
        cityName = allCityNames{i};
        C = AllCities.(cityName);
        if isfield(C, 'Sensitivity_RDB')
            SR = C.Sensitivity_RDB;
            baseVal = SR.EmissionByScenario{1, s};
            plusVal = SR.EmissionByScenario{2, s};
            
            if baseVal ~= 0
                percChange = ((plusVal - baseVal) / baseVal) * 100;
                efficiencyIndex(i) = percChange / 10;
            else
                efficiencyIndex(i) = 0;
            end
        end
    end
    
    %% 4. יצירת הגרף (הפעם עם Visible On כדי שתראי אותם)
    fig = figure('Name', scenarioName, 'Color', 'w', 'Position', [200 200 900 600]);
    ax = axes(fig);
    
    [sortedIndex, sortIdx] = sort(efficiencyIndex, 'ascend');
    sortedCities = allCityNames(sortIdx);
    
    b = bar(ax, categorical(sortedCities, sortedCities), sortedIndex, 'FaceColor', [0.1 0.4 0.6]);
    grid on;
    
    title(['Sensitivity: ', scenarioName], 'FontSize', 13, 'Interpreter', 'none');
    subtitle(['Year: ', num2str(actualYear), ' | Elasticity Index']);
    ylabel('Elasticity (\Delta% Emissions / 1% \DeltaParam)');
    
    text(b.XEndPoints, b.YEndPoints, string(round(sortedIndex, 3)), ...
        'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    
    hold on; yline(1.0, '--r');
    
    %% 5. שמירה אוטומטית
    outputDir = fullfile('Results_Plots', 'All_Sensitivities');
    if ~exist(outputDir, 'dir'), mkdir(outputDir); end
    safeFileName = regexprep(scenarioName, '[^\w'']', '_');
    saveas(fig, fullfile(outputDir, ['Ranking_', safeFileName, '.png']));
    
    % חיווי ב-Command Window כדי שתדעי שהקוד רץ
    fprintf('Successfully created plot for: %s\n', scenarioName);
    
    % אם את לא רוצה 30 חלונות פתוחים, תשאירי את ה-pause או את ה-close
    pause(0.5); % מחכה חצי שנייה בין גרף לגרף כדי שתוכלי לראות
end

fprintf('\nDone! All %d plots are ready in the folder: %s\n', nScenarios, outputDir);