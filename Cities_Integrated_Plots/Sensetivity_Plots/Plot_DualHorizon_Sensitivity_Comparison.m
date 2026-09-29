%% =====================================================================
%  Plot_DualHorizon_Sensitivity_Comparison.m
%  סקריפט חדש: השוואת רגישות בין שתי שנות מפתח (2030 מול 2040)
%  מייצר חלון מפוצל (Subplots) לכל תרחיש משמעותי
%% =====================================================================

% 1. הגדרות רשימת הערים ותיקיית פלט
allCityNames = {'Tlv', 'RishonLeZion', 'BeerSheva', 'Raanana', 'Modiin','Hadera', 'Afula', 'KiryatGat','BeitShemesh', 'MazkeretBatya', 'Rahat', 'Sakhnin'};
nCities = numel(allCityNames);
outputDir = 'Results_Plots\Sensitivity Analysis\Dual_Horizon_Comparison';
if ~exist(outputDir, 'dir'), mkdir(outputDir); end

% הגדרת שתי שנות המפתח והאינדקסים שלהן במודל (מבוסס על שנת התחלה 2019)
yearA = 2030; idxA = yearA - 2019 + 1;
yearB = 2040; idxB = yearB - 2019 + 1;

% 2. זיהוי רשימת התרחישים מהעיר הראשונה
firstCity = allCityNames{1};
if isfield(AllCities.(firstCity), 'Sensitivity_RDB_All_Years')
    scenNames = AllCities.(firstCity).Sensitivity_RDB_All_Years.EmissionByScenario{1}.Properties.VariableNames;
    scenNames([6, 13, 14]) = []; % הסרת העמודות שביקשת להשמיט
    nScenarios = numel(scenNames);
else
    error('Sensitivity_RDB_All_Years not found. Please run the model first.');
end

fprintf('Starting Dual-Horizon generation for %d scenarios...\n', nScenarios);

%% 3. לולאת תרחישים הראשית
for s = 1:nScenarios
    scenarioName = scenNames{s};
    
    % מערכים לשמירת מדדי הרגישות של שתי השנים
    elasticity_2030 = zeros(nCities, 1);
    elasticity_2040 = zeros(nCities, 1);
    
    % שליפת הנתונים מהמודל הרב-שנתי
    for i = 1:nCities
        cityName = allCityNames{i};
        if isfield(AllCities, cityName) && isfield(AllCities.(cityName), 'Sensitivity_RDB_All_Years')
            SR = AllCities.(cityName).Sensitivity_RDB_All_Years;
            
            % שליפה עבור שנת 2030
            if idxA <= numel(SR.EmissionByScenario)
                TA = SR.EmissionByScenario{idxA};
                if ismember(scenarioName, TA.Properties.VariableNames)
                    baseValA = TA{1, scenarioName};
                    plusValA = TA{2, scenarioName};
                    if baseValA ~= 0
                        relInputChangePctA = getRelInputChangePct(SR, scenarioName);
                        elasticity_2030(i) = (((plusValA - baseValA) / baseValA) * 100) / relInputChangePctA;
                    end
                end
            end
            
            % שליפה עבור שנת 2040
            if idxB <= numel(SR.EmissionByScenario)
                TB = SR.EmissionByScenario{idxB};
                if ismember(scenarioName, TB.Properties.VariableNames)
                    baseValB = TB{1, scenarioName};
                    plusValB = TB{2, scenarioName};
                    if baseValB ~= 0
                        relInputChangePctB = getRelInputChangePct(SR, scenarioName);
                        elasticity_2040(i) = (((plusValB - baseValB) / baseValB) * 100) / relInputChangePctB;
                    end
                end
            end
            
        end
    end
    
    % סינון תרחישים זניחים: אם בשתי השנים ההשפעה המקסימלית קטנה מ-0.2%, נדלג
    if max(abs(elasticity_2030)) < 0.1 && max(abs(elasticity_2040)) < 0.1
        continue;
    end

    %% 4. יצירת הגרף המפוצל (Visible On)
    fig = figure('Name', ['Comparison - ' scenarioName], 'Color', 'w', 'Position', [100 100 1400 600]);
    
    % צבע עיצובי קבוע לעמודות
    barColor = [0.15 0.45 0.65]; 
    
    % -----------------------------------------------------------------
    % תת-גרף 1: שנת 2030 (צד שמאל)
    % -----------------------------------------------------------------
    ax1 = subplot(1, 2, 1);
    
    % מיון הערים לפי הרגישות של שנת 2030
    [sorted_35, sortIdx_35] = sort(elasticity_2030, 'ascend');
    cities_35 = allCityNames(sortIdx_35);
    
    b1 = bar(ax1, categorical(cities_35, cities_35), sorted_35, 'FaceColor', barColor);
    grid(ax1, 'on');
    title(ax1, ['Mid-Term Horizon: ', num2str(yearA)], 'FontSize', 12, 'FontWeight', 'bold');
    ylabel(ax1, '\Delta Total Emissions [%] per 1% \DeltaParam (Elasticity)');
    xtickangle(ax1, 35);
    
    % הוספת ערכים מעל/מתחת לעמודות
    text(ax1, b1.XEndPoints, b1.YEndPoints, string(round(sorted_35, 2)), ...
        'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 9);
    
    % -----------------------------------------------------------------
    % תת-גרף 2: שנת 2040 (צד ימין)
    % -----------------------------------------------------------------
    ax2 = subplot(1, 2, 2);
    
    % מיון הערים לפי הרגישות של שנת 2040 (כדי לראות אם הדירוג הפנימי השתנה)
    [sorted_50, sortIdx_50] = sort(elasticity_2040, 'ascend');
    cities_50 = allCityNames(sortIdx_50);
    
    b2 = bar(ax2, categorical(cities_50, cities_50), sorted_50, 'FaceColor', barColor * 0.85); % גוון מעט כהה יותר לשוני
    grid(ax2, 'on');
    title(ax2, ['Long-Term Horizon: ', num2str(yearB)], 'FontSize', 12, 'FontWeight', 'bold');
    xtickangle(ax2, 35);
    
    % הוספת ערכים מעל/מתחת לעמודות
    text(ax2, b2.XEndPoints, b2.YEndPoints, string(round(sorted_50, 2)), ...
        'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 9);
    
    % -----------------------------------------------------------------
    % כותרת על-על (Super Title) לכל החלון
    % -----------------------------------------------------------------
    sgtitle(['Sensitivity Comparison: ', strrep(scenarioName, '_', ' ')], 'FontSize', 15, 'FontWeight', 'bold', 'Interpreter', 'none');
    
    %% 5. שמירה אוטומטית וסגירה
    safeFileName = regexprep(scenarioName, '[^\w\-_]', '_');
    fullFilePath = fullfile(outputDir, ['DualHorizon_', safeFileName, '.png']);
    saveas(fig, fullFilePath);
    
    fprintf('Saved comparison plot: %s\n', scenarioName);
    pause(0.4);
    close(fig); 
end

fprintf('\nDone! All dual-horizon plots are saved in: %s\n', outputDir);