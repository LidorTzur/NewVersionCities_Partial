%% =====================================================================
%  Plot_Longitudinal_Elasticity_Trends.m
%  סקריפט חדש: ניתוח דינמי של מדדי אלסטיות לאורך ציר הזמן (Longitudinal Analysis)
%  מציג מגמות דעיכה/רוויה ומטריצות חום השוואתיות של Elasticity Index
%% =====================================================================

% 1. הגדרות בסיס וערים
allCityNames = {'Tlv', 'RishonLeZion', 'BeerSheva', 'Raanana', 'Modiin','Hadera', 'Afula', 'KiryatGat','BeitShemesh', 'MazkeretBatya'};
nCities = numel(allCityNames);
outputDir = fullfile('Results_Plots', 'Sensitivity Analysis', 'Temporal_Elasticity_Trends');
if ~exist(outputDir, 'dir'), mkdir(outputDir); end

% הגדרת ציר השנים לניתוח המגמה (מ-2025 עד 2050 בקפיצות של 5 שנים)
trendYears = 2025:5:2050;
nYears = numel(trendYears);

% 2. שליפת שמות התרחישים וסינון ראשוני מהעיר הראשונה
firstCity = allCityNames{1};
if isfield(AllCities.(firstCity), 'Sensitivity_RDB_All_Years')
    scenNames = AllCities.(firstCity).Sensitivity_RDB_All_Years.EmissionByScenario{1}.Properties.VariableNames;
    scenNames([6, 13, 14]) = []; % השמטת העמודות שביקשת להסיר
    nScens = numel(scenNames);
else
    error('Sensitivity_RDB_All_Years not found. Run the simulation first.');
end

%% 3. בניית מערך נתונים מלא של מדדי אלסטיות: [ערים X תרחישים X שנים]
trendTensor = zeros(nCities, nScens, nYears);

for y = 1:nYears
    currentYear = trendYears(y);
    yearIdx = currentYear - 2019 + 1; % אינדקס סלולרי במודל
    
    for i = 1:nCities
        cityName = allCityNames{i};
        if isfield(AllCities, cityName) && isfield(AllCities.(cityName), 'Sensitivity_RDB_All_Years')
            SR = AllCities.(cityName).Sensitivity_RDB_All_Years;
            
            if yearIdx <= numel(SR.EmissionByScenario)
                T = SR.EmissionByScenario{yearIdx};
                for s = 1:nScens
                    targetName = scenNames{s};
                    if ismember(targetName, T.Properties.VariableNames)
                        baseVal = T{1, targetName};
                        plusVal = T{2, targetName};
                        if baseVal ~= 0
                            percChange = ((plusVal - baseVal) / baseVal) * 100;
                            trendTensor(i, s, y) = percChange / 10; % נרמול למדד אלסטיות (1% שינוי בפרמטר)
                        end
                    end
                end
            end
        end
    end
end

%% 3.1. סינון תרחישים זניחים (סף אלסטיות של 0.02 באחת השנים לפחות, שווה ערך ל-0.2% שינוי)
threshold = 0.02;
maxImpact = max(max(abs(trendTensor), [], 1), [], 3);
significantIdx = maxImpact > threshold;
filteredScenNames = scenNames(significantIdx);
nFilteredScens = numel(filteredScenNames);
filteredTensor = trendTensor(:, significantIdx, :);

%% =====================================================================
%  פלוט מס' 1: גרפי קו של מגמת השינוי באלסטיות לאורך השנים (לכל תרחיש בנפרד)
%  מיועד להראות בצורה מובהקת כיצד האלסטיות משתנה ודועכת בזמן (רוויה)
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
    0.60, 0.40, 0.20   % MazkeretBatya (Brown)
];

fprintf('Generating %d temporal elasticity trend line plots...\n', nFilteredScens);
for s = 1:nFilteredScens
    scenName = filteredScenNames{s};
    
    fig = figure('Name', ['ElasticityTrend - ' scenName], 'Color', 'w', 'Position', [150 150 950 600]);
    ax = axes(fig);
    hold on;
    
    % ריצה על פני הערים וציור קו לכל עיר לאורך השנים
    for i = 1:nCities
        yData = squeeze(filteredTensor(i, s, :)); % נתוני האלסטיות של עיר i לאורך השנים
        plot(ax, trendYears, yData, '-o', 'LineWidth', 2, ...
             'Color', customColors(i,:), 'MarkerFaceColor', customColors(i,:), ...
             'MarkerSize', 6);
    end
    
    grid on;
    set(ax, 'FontSize', 12, 'FontWeight', 'bold', 'XTick', trendYears);
    xlabel('Forecast Year', 'FontSize', 13);
    ylabel('Elasticity (\Delta% Emissions / 1% \DeltaParam)', 'FontSize', 13);
    title(['Elasticity Index Evolution (2025-2050): ', strrep(scenName,'_',' ')], 'FontSize', 14, 'FontWeight', 'bold');
    
    legend(allCityNames, 'Location', 'northeastoutside', 'FontSize', 10);
    yline(0, 'k--', 'LineWidth', 1.2); % קו אפס לייחוס
    
    % שמירה
    safeName = regexprep(scenName, '[^\w\-_]', '_');
    saveas(fig, fullfile(outputDir, ['ElasticityTrend_' safeName '.png']));
    close(fig);
end

%% =====================================================================
%  פלוט מס' 2: מטריצת חום (Heatmap) השוואתית בין שנות מפתח (2035 מול 2050)
%  גרסה מתוקנת העובדת עם tiledlayout למניעת שגיאות אובייקט
%% =====================================================================
fprintf('Generating System-Wide Elasticity Heatmaps for 2035 and 2050...\n');

% שליפת האינדקסים המדויקים במערך עבור השנים 2035 ו-2050
idx2035 = find(trendYears == 2035);
idx2050 = find(trendYears == 2050);

if ~isempty(idx2035) && ~isempty(idx2050)
    % יצירת פיגור משותף
    figHeat = figure('Name', 'System-Wide Elasticity Heatmap', 'Color', 'w', 'Position', [50 50 1400 700]);
    
    % יצירת פריסת אריחים מפוצלת (שורה אחת, שתי עמודות)
    t = tiledlayout(figHeat, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    % נקה שמות תרחישים לתצוגה יפה בלי קווים תחתונים
    cleanScenNames = strrep(filteredScenNames, '_', ' ');
    
    % הגדרת גבולות קבועים לצבעים (כדי שהצבעים בשני הגרפים יהיו ברי השוואה)
    colorRange = [min(filteredTensor(:)) max(filteredTensor(:))];
    
    % --- תת-גרף שמאל: שנת 2035 ---
    nexttile(t); % עובר לאריח הראשון
    data2035 = filteredTensor(:, :, idx2035);
    h1 = heatmap(figHeat, cleanScenNames, allCityNames, data2035, ...
        'Colormap', jet, 'ColorLimits', colorRange);
    h1.Title = 'Elasticity Index - Year 2035';
    h1.XLabel = 'Policy Parameters';
    h1.YLabel = 'Cities';
    
    % --- תת-גרף ימין: שנת 2050 ---
    nexttile(t); % עובר לאריח השני
    data2050 = filteredTensor(:, :, idx2050);
    h2 = heatmap(figHeat, cleanScenNames, allCityNames, data2050, ...
        'Colormap', jet, 'ColorLimits', colorRange);
    h2.Title = 'Elasticity Index - Year 2050';
    h2.XLabel = 'Policy Parameters';
    h2.YLabel = ''; % נשאיר ריק כי הגרפים צמודים
    
    % שמירת מפת החום המשותפת
    saveas(figHeat, fullfile(outputDir, 'System_Elasticity_Heatmap_Comparison.png'));
    fprintf('Successfully saved system-wide elasticity heatmap comparison.\n');
end

fprintf('\nAll new trend and heatmap elasticity plots are ready in: %s\n', outputDir);