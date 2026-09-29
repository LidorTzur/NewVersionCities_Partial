% %% =====================================================================
% %  Plot_Longitudinal_Elasticity_Trends.m
% %  סקריפט חדש: ניתוח דינמי של מדדי אלסטיות לאורך ציר הזמן (Longitudinal Analysis)
% %  מציג מגמות דעיכה/רוויה ומטריצות חום השוואתיות של Elasticity Index
% %% =====================================================================
% 
% % 1. הגדרות בסיס וערים
% allCityNames = {'Tlv', 'RishonLeZion', 'BeerSheva', 'Raanana', 'Modiin','Hadera', 'Afula', 'KiryatGat','BeitShemesh', 'MazkeretBatya', 'Rahat', 'Sakhnin'};
% nCities = numel(allCityNames);
% outputDir = fullfile('Results_Plots', 'Sensitivity Analysis', 'Temporal_Elasticity_Trends');
% if ~exist(outputDir, 'dir'), mkdir(outputDir); end
% 
% % הגדרת ציר השנים לניתוח המגמה (מ-2025 עד 2050 בקפיצות של 5 שנים)
% trendYears = 2025:5:2040;
% nYears = numel(trendYears);
% 
% % 2. שליפת שמות התרחישים וסינון ראשוני מהעיר הראשונה
% firstCity = allCityNames{1};
% if isfield(AllCities.(firstCity), 'Sensitivity_RDB_All_Years')
%     scenNames = AllCities.(firstCity).Sensitivity_RDB_All_Years.EmissionByScenario{1}.Properties.VariableNames;
%     scenNames([6, 13, 14]) = []; % השמטת העמודות שביקשת להסיר
%     nScens = numel(scenNames);
% else
%     error('Sensitivity_RDB_All_Years not found. Run the simulation first.');
% end
% 
% %% 3. בניית מערך נתונים מלא של מדדי אלסטיות: [ערים X תרחישים X שנים]
% trendTensor = zeros(nCities, nScens, nYears);
% 
% for y = 1:nYears
%     currentYear = trendYears(y);
%     yearIdx = currentYear - 2019 + 1; % אינדקס סלולרי במודל
% 
%     for i = 1:nCities
%         cityName = allCityNames{i};
%         if isfield(AllCities, cityName) && isfield(AllCities.(cityName), 'Sensitivity_RDB_All_Years')
%             SR = AllCities.(cityName).Sensitivity_RDB_All_Years;
% 
%             if yearIdx <= numel(SR.EmissionByScenario)
%                 T = SR.EmissionByScenario{yearIdx};
%                 for s = 1:nScens
%                     targetName = scenNames{s};
%                     if ismember(targetName, T.Properties.VariableNames)
%                         baseVal = T{1, targetName};
%                         plusVal = T{2, targetName};
%                         if baseVal ~= 0
%                             percChange = ((plusVal - baseVal) / baseVal) * 100;
%                             trendTensor(i, s, y) = percChange / 10; % נרמול למדד אלסטיות (1% שינוי בפרמטר)
%                         end
%                     end
%                 end
%             end
%         end
%     end
% end
% 
% %% 3.1. סינון תרחישים זניחים (סף אלסטיות של 0.02 באחת השנים לפחות, שווה ערך ל-0.2% שינוי)
% threshold = 0.002;
% maxImpact = max(max(abs(trendTensor), [], 1), [], 3);
% significantIdx = maxImpact > threshold;
% filteredScenNames = scenNames(significantIdx);
% nFilteredScens = numel(filteredScenNames);
% filteredTensor = trendTensor(:, significantIdx, :);
% 
% %% =====================================================================
% %  פלוט מס' 1: גרפי קו של מגמת השינוי באלסטיות לאורך השנים (לכל תרחיש בנפרד)
% %  מיועד להראות בצורה מובהקת כיצד האלסטיות משתנה ודועכת בזמן (רוויה)
% % =====================================================================
% customColors = [
%     0.15, 0.15, 0.50;  % Tlv (Navy)
%     0.85, 0.33, 0.10;  % RishonLeZion (Orange)
%     0.10, 0.60, 0.20;  % BeerSheva (Green)
%     0.45, 0.20, 0.60;  % Raanana (Purple)
%     0.00, 0.75, 0.75;  % Modiin (Turquoise)
%     0.65, 0.10, 0.10;  % Hadera (Red)
%     0.95, 0.75, 0.00;  % Afula (Yellow)
%     0.40, 0.40, 0.40;  % KiryatGat (Gray)
%     0.20, 0.80, 0.50;  % BeitShemesh (Mint)
%     0.60, 0.40, 0.20   % MazkeretBatya (Brown)
%     0.75, 0.00, 0.75;  % Rahat (Magenta)
%     0.00, 0.45, 0.74   % Sakhnin (Light Blue)
% ];
% 
% fprintf('Generating %d temporal elasticity trend line plots...\n', nFilteredScens);
% for s = 1:nFilteredScens
%     scenName = filteredScenNames{s};
% 
%     fig = figure('Name', ['ElasticityTrend - ' scenName], 'Color', 'w', 'Position', [150 150 950 600]);
%     ax = axes(fig);
%     hold on;
% 
%     % ריצה על פני הערים וציור קו לכל עיר לאורך השנים
%     for i = 1:nCities
%         yData = squeeze(filteredTensor(i, s, :)); % נתוני האלסטיות של עיר i לאורך השנים
%         plot(ax, trendYears, yData, '-o', 'LineWidth', 2, ...
%              'Color', customColors(i,:), 'MarkerFaceColor', customColors(i,:), ...
%              'MarkerSize', 6);
%     end
% 
%     grid on;
%     set(ax, 'FontSize', 12, 'FontWeight', 'bold', 'XTick', trendYears);
%     xlabel('Forecast Year', 'FontSize', 13);
%     ylabel('Elasticity (\Delta% Emissions / 1% \DeltaParam)', 'FontSize', 13);
%     title(['Elasticity Index Evolution (2025-2040): ', strrep(scenName,'_',' ')], 'FontSize', 14, 'FontWeight', 'bold');
% 
%     legend(allCityNames, 'Location', 'northeastoutside', 'FontSize', 10);
%     yline(0, 'k--', 'LineWidth', 1.2); % קו אפס לייחוס
% 
%     % שמירה
%     safeName = regexprep(scenName, '[^\w\-_]', '_');
%     saveas(fig, fullfile(outputDir, ['ElasticityTrend_' safeName '.png']));
%     close(fig);
% end
% 
% %% =====================================================================
% %  פלוט מס' 2: מטריצת חום (Heatmap) השוואתית בין שנות מפתח (2035 מול 2050)
% %  גרסה מתוקנת העובדת עם tiledlayout למניעת שגיאות אובייקט
% %% =====================================================================
% fprintf('Generating System-Wide Elasticity Heatmaps for 2030 and 2040...\n');
% 
% % שליפת האינדקסים המדויקים במערך עבור השנים 2035 ו-2050
% idx2030 = find(trendYears == 2030);
% idx2040 = find(trendYears == 2040);
% 
% if ~isempty(idx2030) && ~isempty(idx2040)
%     % יצירת פיגור משותף
%     figHeat = figure('Name', 'System-Wide Elasticity Heatmap', 'Color', 'w', 'Position', [50 50 1400 700]);
% 
%     % יצירת פריסת אריחים מפוצלת (שורה אחת, שתי עמודות)
%     t = tiledlayout(figHeat, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
% 
%     % נקה שמות תרחישים לתצוגה יפה בלי קווים תחתונים
%     cleanScenNames = strrep(filteredScenNames, '_', ' ');
% 
%     % הגדרת גבולות קבועים לצבעים (כדי שהצבעים בשני הגרפים יהיו ברי השוואה)
%     colorRange = [min(filteredTensor(:)) max(filteredTensor(:))];
% 
%     % --- תת-גרף שמאל: שנת 2035 ---
%     nexttile(t); % עובר לאריח הראשון
%     data2030 = filteredTensor(:, :, idx2030);
%     h1 = heatmap(figHeat, cleanScenNames, allCityNames, data2030, ...
%         'Colormap', jet, 'ColorLimits', colorRange);
%     h1.Title = 'Elasticity Index - Year 2030';
%     h1.XLabel = 'Policy Parameters';
%     h1.YLabel = 'Cities';
% 
%     % --- תת-גרף ימין: שנת 2050 ---
%     nexttile(t); % עובר לאריח השני
%     data2040 = filteredTensor(:, :, idx2040);
%     h2 = heatmap(figHeat, cleanScenNames, allCityNames, data2040, ...
%         'Colormap', jet, 'ColorLimits', colorRange);
%     h2.Title = 'Elasticity Index - Year 2040';
%     h2.XLabel = 'Policy Parameters';
%     h2.YLabel = ''; % נשאיר ריק כי הגרפים צמודים
% 
%     % שמירת מפת החום המשותפת
%     saveas(figHeat, fullfile(outputDir, 'System_Elasticity_Heatmap_Comparison.png'));
%     fprintf('Successfully saved system-wide elasticity heatmap comparison.\n');
% end
% 
% fprintf('\nAll new trend and heatmap elasticity plots are ready in: %s\n', outputDir);




%% =====================================================================
%  Plot_Longitudinal_Elasticity_Trends_AllMetrics.m
%  סקריפט מאוחד: ניתוח דינמי של מדדי אלסטיות לאורך ציר הזמן (פליטות, מים ושטח)
%% =====================================================================

% 1. הגדרות בסיס וערים
allCityNames = {'Tlv', 'RishonLeZion', 'BeerSheva', 'Raanana', 'Modiin','Hadera', 'Afula', 'KiryatGat','BeitShemesh', 'MazkeretBatya', 'Rahat', 'Sakhnin'};
nCities = numel(allCityNames);

% הגדרת ציר השנים לניתוח המגמה (מ-2025 עד 2040 בקפיצות של 5 שנים)
trendYears = 2025:5:2040;
nYears = numel(trendYears);

% הגדרת תיקיית האב הראשית של הפליטות
baseOutputDir = fullfile('Results_Plots', 'Sensitivity Analysis', 'Temporal_Elasticity_Trends');
if ~exist(baseOutputDir, 'dir'), mkdir(baseOutputDir); end

% הגדרת המדדים והתיקיות היחסיות שלהם (מים ושטח יישמרו כתת-תיקיות תחת הפליטות)
metricsConfig = {
    'EmissionByScenario', '';                                      ... % פליטות (בתיקייה הראשית)
    'WaterByScenario',    fullfile('Water_SubFolder');             ... % תת-תיקיה למים
    'AreaByScenario',     fullfile('Area_SubFolder')                   ... % תת-תיקיה לשטח
};

firstCity = allCityNames{1};

%% 2. ריצה ראשית על כל מדד בנפרד (פליטות, מים, שטחים)
for m = 1:size(metricsConfig, 1)
    currentMetric = metricsConfig{m, 1};
    
    if isempty(metricsConfig{m, 2})
        outputDir = baseOutputDir;
    else
        outputDir = fullfile(baseOutputDir, metricsConfig{m, 2});
    end
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
    
    nScens = numel(scenNames);
    fprintf('\n===================================================\n');
    fprintf('Processing Longitudinal Analysis for: %s (%d scenarios)\n', currentMetric, nScens);
    fprintf('===================================================\n');
    
    %% 3. בניית מערך נתונים מלא של מדדי אלסטיות: [ערים X תרחישים X שנים]
    trendTensor = zeros(nCities, nScens, nYears);
    for y = 1:nYears
        currentYear = trendYears(y);
        yearIdx = currentYear - 2019 + 1; % אינדקס סלולרי במודל
        
        for i = 1:nCities
            cityName = allCityNames{i};
            if isfield(AllCities, cityName) && isfield(AllCities.(cityName), 'Sensitivity_RDB_All_Years')
                SR = AllCities.(cityName).Sensitivity_RDB_All_Years;
                
                if isfield(SR, currentMetric)
                    currCell = SR.(currentMetric);
                    if yearIdx <= numel(currCell)
                        T = currCell{yearIdx};
                        if istable(T)
                            for s = 1:nScens
                                targetName = scenNames{s};
                                if ismember(targetName, T.Properties.VariableNames)
                                    baseVal = T{1, targetName};
                                    plusVal = T{2, targetName};
                                    if baseVal ~= 0
                                        percChange = ((plusVal - baseVal) / baseVal) * 100;
                                        relInputChangePct = getRelInputChangePct(SR, targetName);
                                        trendTensor(i, s, y) = percChange / relInputChangePct;
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    %% 3.1. סינון תרחישים זניחים (סף אלסטיות של 0.002 באחת השנים לפחות)
    threshold = 0.00;
    maxImpact = max(max(abs(trendTensor), [], 1), [], 3);
    significantIdx = maxImpact > threshold;
    filteredScenNames = scenNames(significantIdx);
    nFilteredScens = numel(filteredScenNames);
    
    if nFilteredScens == 0
        fprintf('No significant scenarios found for metric %s. Skipping plots...\n', currentMetric);
        continue;
    end
    
    filteredTensor = trendTensor(:, significantIdx, :);
    
    %% =====================================================================
    %  פלוט מס' 1: גרפי קו של מגמת השינוי באלסטיות לאורך השנים
    % =====================================================================
    customColors = [
        0.15, 0.15, 0.50;  % Tlv (Navy)
        0.85, 0.33, 0.10;  % RishonLeZion (Orange)
        0.10, 0.60, 0.20;  % BeerSheva (Green)
        0.45, 0.20, 0.60;  % Raanana (Purple)
        0.00, 0.75, 0.75;  % Modiin (Turquoise)
        0.65, 0.10, 0.10;  % Hadera (Red)
        0.95, 0.75, 0.00;  % Afula (Yellow)
        0.40, 0.40, 0.40;  % KiryatGat (Gray)
        0.20, 0.80, 0.50;  % BeitShemesh (Mint)
        0.60, 0.40, 0.20;  % MazkeretBatya (Brown)
        0.75, 0.00, 0.75;  % Rahat (Magenta)
        0.00, 0.45, 0.74   % Sakhnin (Light Blue)
    ];
    
    fprintf('Generating %d temporal trend line plots for %s...\n', nFilteredScens, currentMetric);
    metricShortName = strrep(currentMetric, 'ByScenario', '');
    
    for s = 1:nFilteredScens
        scenName = filteredScenNames{s};
        
        fig = figure('Name', ['ElasticityTrend (' metricShortName ') - ' scenName], 'Color', 'w', 'Position', [150 150 950 600]);
        ax = axes(fig);
        hold on;
        
        for i = 1:nCities
            yData = squeeze(filteredTensor(i, s, :));
            plot(ax, trendYears, yData, '-o', 'LineWidth', 2, ...
                 'Color', customColors(i,:), 'MarkerFaceColor', customColors(i,:), ...
                 'MarkerSize', 6);
        end
        
        grid on;
        set(ax, 'FontSize', 12, 'FontWeight', 'bold', 'XTick', trendYears);
        xlabel('Forecast Year', 'FontSize', 13);
        ylabel(['Elasticity (\Delta% ', metricShortName, ' / 1% \DeltaParam)'], 'FontSize', 13);
        title(['Elasticity Evolution (2025-2040) [', metricShortName, ']: ', strrep(scenName,'_',' ')], 'FontSize', 13, 'FontWeight', 'bold');
        
        legend(allCityNames, 'Location', 'northeastoutside', 'FontSize', 10);
        yline(0, 'k--', 'LineWidth', 1.2);
        
        safeName = regexprep(scenName, '[^\w\-_]', '_');
        saveas(fig, fullfile(outputDir, ['ElasticityTrend_' safeName '.png']));
        close(fig);
    end
    
    %% =====================================================================
    %  פלוט מס' 2: מטריצת חום (Heatmap) השוואתית בין שנות מפתח (2030 מול 2040)
    % =====================================================================
    fprintf('Generating System-Wide Elasticity Heatmaps (2030 vs 2040) for %s...\n', currentMetric);
    idx2030 = find(trendYears == 2030);
    idx2040 = find(trendYears == 2040);
    
    if ~isempty(idx2030) && ~isempty(idx2040)
        figHeat = figure('Name', ['System Elasticity Heatmap - ' metricShortName], 'Color', 'w', 'Position', [50 50 1400 700]);
        t = tiledlayout(figHeat, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
        
        cleanScenNames = strrep(filteredScenNames, '_', ' ');
        colorRange = [min(filteredTensor(:)) max(filteredTensor(:))];
        
        % --- תת-גרף שמאל: שנת 2030 ---
        nexttile(t);
        data2030 = filteredTensor(:, :, idx2030);
        h1 = heatmap(figHeat, cleanScenNames, allCityNames, data2030, ...
            'Colormap', jet, 'ColorLimits', colorRange);
        h1.Title = ['Elasticity Index - 2030 (', metricShortName, ')'];
        h1.XLabel = 'Policy Parameters';
        h1.YLabel = 'Cities';

        % --- תת-גרף ימין: שנת 2040 ---
        nexttile(t);
        data2040 = filteredTensor(:, :, idx2040);
        h2 = heatmap(figHeat, cleanScenNames, allCityNames, data2040, ...
            'Colormap', jet, 'ColorLimits', colorRange);
        h2.Title = ['Elasticity Index - 2040 (', metricShortName, ')'];
        h2.XLabel = 'Policy Parameters';
        h2.YLabel = '';
        
        saveas(figHeat, fullfile(outputDir, 'System_Elasticity_Heatmap_Comparison.png'));
        close(figHeat);
        fprintf('Successfully saved heatmap comparison for %s.\n', currentMetric);
    end
end

fprintf('\nAll longitudinal trend lines and heatmaps for Emissions, Water, and Area are ready!\n');
