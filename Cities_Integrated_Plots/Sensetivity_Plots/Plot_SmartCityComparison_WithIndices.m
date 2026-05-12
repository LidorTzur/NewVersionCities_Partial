
%% =====================================================================
%  Plot_AllSensitivities_Comparison.m
%  מפיק גרפי השוואה לכל התרחישים - גרסה עם תצוגה
%% =====================================================================

% 1. הגדרת רשימת הערים
% allCityNames = {'Tlv', 'RishonLeZion', 'BeerSheva', 'Raanana', 'Modiin', ...
%                 'Hadera', 'Afula', 'KiryatGat', 'BeitShemesh', 'MazkeretBatya'};
allCityNames = {'Tlv', 'RishonLeZion', 'BeerSheva', 'Raanana', 'Modiin','Hadera', 'Afula', 'KiryatGat','BeitShemesh', 'MazkeretBatya'};

nCities = numel(allCityNames);


outputDir = fullfile('Results_Plots', 'Sensitivity Analysis', 'Elesty');
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

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
    % ניקוי שם הקובץ מתווים בעייתיים
    safeFileName = regexprep(scenarioName, '[^\w\-_]', '_');
    fullFilePath = fullfile(outputDir, ['Ranking_', safeFileName, '.png']);
    saveas(fig, fullFilePath);

    
    % חיווי ב-Command Window כדי שתדעי שהקוד רץ
    fprintf('Successfully created plot for: %s\n', scenarioName);
    
    % אם את לא רוצה 30 חלונות פתוחים, תשאירי את ה-pause או את ה-close
    pause(0.5); % מחכה חצי שנייה בין גרף לגרף כדי שתוכלי לראות
end

fprintf('\nDone! All %d plots are ready in the folder: %s\n', nScenarios, outputDir);