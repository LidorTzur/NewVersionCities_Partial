%% =====================================================================
% Plot_PerCapita_Emissions_Over_Time.m
% גרפי פליטה לנפש לאורך השנים לכל הערים ולכל התרחישים
% שימוש באוכלוסייה דינמית לכל שנה
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
scenarios = {'BAU','Moderate','Advanced'};

% שליפת רשימת השנים מהעיר הראשונה
firstCity = cityNames{1};
yearLabels = AllCities.(firstCity).TotalResults.Properties.VariableNames;
yearsNum   = str2double(yearLabels);
nYears     = numel(yearLabels);

%% הגדרות עיצוב
cityColors = turbo(nCities); 
fs_axis   = 16;  
fs_label  = 18;  
fs_title  = 24;  
fs_legend = 13;  

% שורות הפליטה הכוללת בטבלת TotalResults
rows.Emission_Total = [7 8 9]; % BAU / Moderate / Advanced

outputDir = 'C:\Users\צור\Documents\MATLAB\NewVersionCities_Partial\Results_Plots\Plot_Total_Emissions_Over_Time_Capita';
if ~exist(outputDir,'dir'), mkdir(outputDir); end

%% --- לולאה על תרחישים ---
for s = 1:numel(scenarios)
    scenName = scenarios{s};
    rowIdx   = rows.Emission_Total(s);
    
    % פתיחת חלון חדש
    fig = figure('Name',['Per Capita Emissions – ' scenName], ...
                 'Color','w', 'Units','normalized', ...
                 'Position', [0.1 0.1 0.7 0.7], ... 
                 'Visible', 'on'); 
    
    hold on;
    
    for c = 1:nCities
        cityName = cityNames{c};
        
        if isfield(AllCities, cityName)
            C = AllCities.(cityName);
            TR = C.TotalResults;
            
            % 1. שליפת פליטות טוטאליות (MtCO2eq) לכל השנים
            totalEmissions = TR{rowIdx, :}; 
            
            % 2. חילוץ אוכלוסייה לכל שנה בנפרד (במיליונים)
            popPerYear = zeros(1, nYears);
            for yIdx = 1:nYears
                % שימוש בפונקציה שסיפקת כדי לקבל אוכלוסייה לשנה הספציפית
                popPerYear(yIdx) = getPopMillionsByCol(C, yIdx, scenName, yearLabels);
            end
            
            % 3. חישוב פליטה לנפש (tCO2e per capita)
            % MtCO2eq / Millions of People = tCO2e / person
            yValsPC = totalEmissions ./ max(popPerYear, eps); 
            xVals = yearsNum;        
            
            % ציור הקווים
            plot(xVals, yValsPC, '-', 'Color', cityColors(c,:), 'LineWidth', 3, ...
                 'HandleVisibility', 'off'); 
            
            % ציור הנקודות (גודל 65 כפי שביקשת)
            scatter(xVals, yValsPC, 65, ...
                    'MarkerFaceColor', cityColors(c,:), ...
                    'MarkerEdgeColor', [0.2 0.2 0.2], ...
                    'LineWidth', 1, ...
                    'DisplayName', cityName);
        end
    end
    
    hold off;
    
    % עיצוב
    xlabel('Year', 'FontSize', fs_label, 'FontWeight', 'bold');
    ylabel('Emissions per Capita (tCO2e / person)', 'FontSize', fs_label, 'FontWeight', 'bold');
    title(['Per Capita Emissions Projections: ', scenName], 'FontSize', fs_title, 'FontWeight', 'bold');
    
    ax = gca;
    ax.FontSize = fs_axis;
    ax.FontWeight = 'bold';
    ax.XGrid = 'on'; ax.YGrid = 'on';
    
    % מקרא
    lgd = legend('Location', 'eastoutside', 'FontSize', fs_legend, 'FontWeight', 'bold');
    title(lgd, 'Cities');
    
    drawnow;
    
    % שמירה
    saveName = fullfile(outputDir, ['PerCapita_Emissions_', scenName, '.png']);
    saveas(fig, saveName);
    
    fprintf('✔ גרף פר קפיטה תרחיש %s הוצג ונשמר.\n', scenName);
end

disp('✔ הסקריפט הסתיים בהצלחה.');