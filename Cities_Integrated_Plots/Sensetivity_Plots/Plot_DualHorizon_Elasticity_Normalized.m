% %% =====================================================================
% %  Plot_DualHorizon_Elasticity_Normalized.m
% %  סקריפט חדש: השוואת מדדי אלסטיות מנורמלים (1% שינוי בפרמטר)
% %  מציג את שנות המפתח 2030 מול 2040 זה לצד זה (Subplots)
% %% =====================================================================
% 
% % 1. הגדרות רשימת הערים ותיקיית פלט ממוקדת לאלסטיות
% allCityNames = {'Tlv', 'RishonLeZion', 'BeerSheva', 'Raanana', 'Modiin','Hadera', 'Afula', 'KiryatGat','BeitShemesh', 'MazkeretBatya', 'Rahat', 'Sakhnin'};
% nCities = numel(allCityNames);
% outputDir = fullfile('Results_Plots', 'Sensitivity Analysis', 'Dual_Horizon_Elasticity');
% if ~exist(outputDir, 'dir'), mkdir(outputDir); end
% 
% % הגדרת שתי שנות המפתח והאינדקסים שלהן (לפי בסיס מודל 2019)
% yearA = 2030; idxA = yearA - 2019 + 1;
% yearB = 2040; idxB = yearB - 2019 + 1;
% 
% % 2. זיהוי רשימת התרחישים וסינון העמודות מהעיר הראשונה
% firstCity = allCityNames{1};
% if isfield(AllCities.(firstCity), 'Sensitivity_RDB_All_Years')
%     scenNames = AllCities.(firstCity).Sensitivity_RDB_All_Years.EmissionByScenario{1}.Properties.VariableNames;
%     scenNames([6, 13, 14]) = []; % השמטת העמודות שביקשת להסיר
%     nScenarios = numel(scenNames);
% else
%     error('Sensitivity_RDB_All_Years not found. Please run the model first.');
% end
% 
% fprintf('Starting Normalized Elasticity generation for %d scenarios...\n', nScenarios);
% 
% %% 3. לולאת תרחישים הראשית
% for s = 1:nScenarios
%     scenarioName = scenNames{s};
% 
%     % מערכים לשמירת מדדי האלסטיות המנורמלים (חלקי 10)
%     elasticity_2030 = zeros(nCities, 1);
%     elasticity_2040 = zeros(nCities, 1);
% 
%     % שליפת הנתונים מהמודל הדינמי הרב-שנתי
%     for i = 1:nCities
%         cityName = allCityNames{i};
%         if isfield(AllCities, cityName) && isfield(AllCities.(cityName), 'Sensitivity_RDB_All_Years')
%             SR = AllCities.(cityName).Sensitivity_RDB_All_Years;
% 
%             % שליפה וחישוב אלסטיות מנורמלת עבור שנת 2030
%             if idxA <= numel(SR.EmissionByScenario)
%                 TA = SR.EmissionByScenario{idxA};
%                 if ismember(scenarioName, TA.Properties.VariableNames)
%                     baseValA = TA{1, scenarioName};
%                     plusValA = TA{2, scenarioName};
%                     if baseValA ~= 0
%                         percChangeA = ((plusValA - baseValA) / baseValA) * 100;
%                         elasticity_2030(i) = percChangeA / 10; % נרמול ל-1% שינוי בפרמטר
%                     end
%                 end
%             end
% 
%             % שליפה וחישוב אלסטיות מנורמלת עבור שנת 2040
%             if idxB <= numel(SR.EmissionByScenario)
%                 TB = SR.EmissionByScenario{idxB};
%                 if ismember(scenarioName, TB.Properties.VariableNames)
%                     baseValB = TB{1, scenarioName};
%                     plusValB = TB{2, scenarioName};
%                     if baseValB ~= 0
%                         percChangeB = ((plusValB - baseValB) / baseValB) * 100;
%                         elasticity_2040(i) = percChangeB / 10; % נרמול ל-1% שינוי בפרמטר
%                     end
%                 end
%             end
% 
%         end
%     end
% 
%     % סינון תרחישים זניחים: אם בשתי השנים המדד המוחלט קטן מ-0.02 (מקביל ל-0.2% מקודם), נדלג
%     if max(abs(elasticity_2030)) < 0.02 && max(abs(elasticity_2040)) < 0.02
%         continue;
%     end
% 
%     %% 4. יצירת הגרף המפוצל (Visible On)
%     fig = figure('Name', ['Elasticity - ' scenarioName], 'Color', 'w', 'Position', [100 100 1400 600]);
% 
%     % צבע עיצובי אחיד ומקצועי לעמודות
%     barColor = [0.15 0.45 0.65]; 
% 
%     % -----------------------------------------------------------------
%     % תת-גרף 1: שנת 2030 (צד שמאל)
%     % -----------------------------------------------------------------
%     ax1 = subplot(1, 2, 1);
% 
%     % מיון הערים לפי מדד האלסטיות של שנת 2030
%     [sorted_30, sortIdx_30] = sort(elasticity_2030, 'ascend');
%     cities_30 = allCityNames(sortIdx_30);
% 
%     b1 = bar(ax1, categorical(cities_30, cities_30), sorted_30, 'FaceColor', barColor);
%     grid(ax1, 'on');
%     title(ax1, ['Mid-Term Horizon: ', num2str(yearA)], 'FontSize', 12, 'FontWeight', 'bold');
%     ylabel(ax1, 'Elasticity (\Delta% Emissions / 1% \DeltaParam)');
%     xtickangle(ax1, 30);
% 
%     % הוספת ערכים מעל העמודות בדיוק של 3 ספרות אחרי הנקודה (כמו שביקשת)
%     text(ax1, b1.XEndPoints, b1.YEndPoints, string(round(sorted_30, 3)), ...
%         'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 9);
% 
%     % -----------------------------------------------------------------
%     % תת-גרף 2: שנת 2040 (צד ימין)
%     % -----------------------------------------------------------------
%     ax2 = subplot(1, 2, 2);
% 
%     % מיון הערים לפי מדד האלסטיות של שנת 2040
%     [sorted_40, sortIdx_40] = sort(elasticity_2040, 'ascend');
%     cities_40 = allCityNames(sortIdx_40);
% 
%     b2 = bar(ax2, categorical(cities_40, cities_40), sorted_40, 'FaceColor', barColor * 0.85);
%     grid(ax2, 'on');
%     title(ax2, ['Long-Term Horizon: ', num2str(yearB)], 'FontSize', 12, 'FontWeight', 'bold');
%     xtickangle(ax2, 30);
% 
%     % הוספת ערכים מעל העמודות
%     text(ax2, b2.XEndPoints, b2.YEndPoints, string(round(sorted_40, 3)), ...
%         'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 9);
% 
%     % -----------------------------------------------------------------
%     % כותרת על-על (Super Title) לחלון כולו
%     % -----------------------------------------------------------------
%     sgtitle(['Elasticity Comparison: ', strrep(scenarioName, '_', ' ')], 'FontSize', 15, 'FontWeight', 'bold', 'Interpreter', 'none');
% 
%     %% 5. שמירה אוטומטית וסגירה מבוקרת
%     safeFileName = regexprep(scenarioName, '[^\w\-_]', '_');
%     fullFilePath = fullfile(outputDir, ['DualElasticity_', safeFileName, '.png']);
%     saveas(fig, fullFilePath);
% 
%     fprintf('Saved comparison plot: %s\n', scenarioName);
%     pause(0.4);
%     close(fig); 
% end
% 
% fprintf('\nDone! All dual-horizon elasticity plots are saved in: %s\n', outputDir);


%% =====================================================================
%  Plot_All_DualHorizon_Elasticity_Unified.m
%  סקריפט מאוחד: פליטות, מים ושטח - השוואת מדדי אלסטיות מנורמלים (2030 מול 2040)
%% =====================================================================

% 1. הגדרות רשימת הערים
allCityNames = {'Tlv', 'RishonLeZion', 'BeerSheva', 'Raanana', 'Modiin','Hadera', 'Afula', 'KiryatGat','BeitShemesh', 'MazkeretBatya', 'Rahat', 'Sakhnin'};
nCities = numel(allCityNames);

% הגדרת שתי שנות המפתח והאינדקסים שלהן (לפי בסיס מודל 2019)
yearA = 2030; idxA = yearA - 2019 + 1;
yearB = 2040; idxB = yearB - 2019 + 1;

% הגדרת תיקיית האב הראשית של הפליטות
baseOutputDir = fullfile('Results_Plots', 'Sensitivity Analysis');
if ~exist(baseOutputDir, 'dir'), mkdir(baseOutputDir); end

% הגדרת המדדים והתיקיות היחסיות שלהם (מים ושטח ישמרו כתת-תיקיות תחת הפליטות)
metricsConfig = {
    'EmissionByScenario', fullfile('Dual_Horizon_Elasticity');  ... % תיקיית הפליטות המקורית
    'WaterByScenario',    fullfile('Dual_Horizon_Elasticity', 'Water_SubFolder'); ... % תת-תיקיה למים
    'AreaByScenario',     fullfile('Dual_Horizon_Elasticity', 'Area_SubFolder')      ... % תת-תיקיה לשטח
};

firstCity = allCityNames{1};

%% 2. רצה על כל מדד בנפרד (פליטות, מים, שטחים)
for m = 1:size(metricsConfig, 1)
    currentMetric = metricsConfig{m, 1};
    outputDir = fullfile(baseOutputDir, metricsConfig{m, 2});
    if ~exist(outputDir, 'dir'), mkdir(outputDir); end
    
    % בדיקה האם השדה קיים במבנה הנתונים של העיר הראשונה
    if ~(isfield(AllCities.(firstCity), 'Sensitivity_RDB_All_Years') && ...
         isfield(AllCities.(firstCity).Sensitivity_RDB_All_Years, currentMetric))
        warning('Metric %s not found in structure. Skipping...', currentMetric);
        continue;
    end
    
    % שליפת שמות התרחישים
    metricCellTable = AllCities.(firstCity).Sensitivity_RDB_All_Years.(currentMetric);
    scenNames = metricCellTable{1}.Properties.VariableNames;
    
    % אם מדובר בפליטות, נסנן את העמודות המבוקשות כמו במקור שלך
    if strcmp(currentMetric, 'EmissionByScenario')
        if numel(scenNames) >= 14
            scenNames([6, 13, 14]) = []; 
        end
    end
    
    nScenarios = numel(scenNames);
    fprintf('\n---------------------------------------------------\n');
    fprintf('Processing metric: %s (%d scenarios)\n', currentMetric, nScenarios);
    fprintf('---------------------------------------------------\n');
    
    %% 3. לולאת תרחישים הראשית למדד הנוכחי
    for s = 1:nScenarios
        scenarioName = scenNames{s};
        
        elasticity_2030 = zeros(nCities, 1);
        elasticity_2040 = zeros(nCities, 1);
        
        % שליפת הנתונים מכל עיר
        for i = 1:nCities
            cityName = allCityNames{i};
            if isfield(AllCities, cityName) && isfield(AllCities.(cityName), 'Sensitivity_RDB_All_Years')
                SR = AllCities.(cityName).Sensitivity_RDB_All_Years;
                
                if isfield(SR, currentMetric)
                    currCell = SR.(currentMetric);
                    
                    % 2030
                    if idxA <= numel(currCell)
                        TA = currCell{idxA};
                        if istable(TA) && ismember(scenarioName, TA.Properties.VariableNames)
                            baseValA = TA{1, scenarioName};
                            plusValA = TA{2, scenarioName};
                            if baseValA ~= 0
                                percChangeA = ((plusValA - baseValA) / baseValA) * 100;
                                relInputChangePct = getRelInputChangePct(SR, scenarioName); % ראה פונקציית עזר למטה
                                elasticity_2030(i) = percChangeA / relInputChangePct;
                            end
                        end
                    end
                    
                    % 2040
                    if idxB <= numel(currCell)
                        TB = currCell{idxB};
                        if istable(TB) && ismember(scenarioName, TB.Properties.VariableNames)
                            baseValB = TB{1, scenarioName};
                            plusValB = TB{2, scenarioName};
                            if baseValB ~= 0
                                percChangeB = ((plusValB - baseValB) / baseValB) * 100;
                                relInputChangePct = getRelInputChangePct(SR, scenarioName);
                                elasticity_2040(i) = percChangeB / relInputChangePct;
                            end
                        end
                    end
                end
            end
        end
        
        % סינון תרחישים זניחים
        if max(abs(elasticity_2030)) < 0.02 && max(abs(elasticity_2040)) < 0.02
            continue;
        end
        
        %% 4. יצירת הגרף המפוצל
        fig = figure('Name', [currentMetric ' - ' scenarioName], 'Color', 'w', 'Position', [100 100 1400 600]);
        
        % התאמת צבעים לפי סוג המדד לשמירה על שפה ויזואלית ברורה
        if contains(currentMetric, 'Emission')
            barColor = [0.15 0.45 0.65]; % כחול-אפור (מקור)
        elseif contains(currentMetric, 'Water')
            barColor = [0.10 0.50 0.70]; % כחול-מים
        else
            barColor = [0.25 0.55 0.35]; % ירוק-שטח/קרקע
        end
        
        % תת-גרף 1: 2030
        ax1 = subplot(1, 2, 1);
        [sorted_30, sortIdx_30] = sort(elasticity_2030, 'ascend');
        cities_30 = allCityNames(sortIdx_30);
        
        b1 = bar(ax1, categorical(cities_30, cities_30), sorted_30, 'FaceColor', barColor);
        grid(ax1, 'on');
        title(ax1, ['Mid-Term Horizon: ', num2str(yearA)], 'FontSize', 12, 'FontWeight', 'bold');
        ylabel(ax1, ['Elasticity (\Delta% ', strrep(currentMetric, 'ByScenario', ''), ' / 1% \DeltaParam)']);
        xtickangle(ax1, 30);
        
        text(ax1, b1.XEndPoints, b1.YEndPoints, string(round(sorted_30, 3)), ...
            'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 9);
        
        % תת-גרף 2: 2040
        ax2 = subplot(1, 2, 2);
        [sorted_40, sortIdx_40] = sort(elasticity_2040, 'ascend');
        cities_40 = allCityNames(sortIdx_40);
        
        b2 = bar(ax2, categorical(cities_40, cities_40), sorted_40, 'FaceColor', barColor * 0.85);
        grid(ax2, 'on');
        title(ax2, ['Long-Term Horizon: ', num2str(yearB)], 'FontSize', 12, 'FontWeight', 'bold');
        xtickangle(ax2, 30);
        
        text(ax2, b2.XEndPoints, b2.YEndPoints, string(round(sorted_40, 3)), ...
            'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 9);
        
        % כותרת על
        sgtitle(['Elasticity Comparison (', strrep(currentMetric, 'ByScenario', ''), '): ', ...
                 strrep(scenarioName, '_', ' ')], 'FontSize', 15, 'FontWeight', 'bold', 'Interpreter', 'none');
        
        %% 5. שמירה וסגירה
        safeFileName = regexprep(scenarioName, '[^\w\-_]', '_');
        fullFilePath = fullfile(outputDir, ['DualElasticity_', safeFileName, '.png']);
        saveas(fig, fullFilePath);
        
        fprintf('Saved: [%s] -> %s\n', currentMetric, scenarioName);
        pause(0.3);
        close(fig);
    end
end

fprintf('\nAll plots for Emissions, Water, and Area have been successfully generated and organized!\n');
