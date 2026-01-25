%% =====================================================================
% Plot_Total_Emissions_Over_Time.m
% גרסה מתוקנת להצגת חלונות על המסך ושמירתם
%% =====================================================================
addpath('helpers');

% --- קביעת סדר ערים עקבי ---
try
    cats_cities = getCityCats(AllCities);
    cityNames = cellstr(cats_cities);
catch
    % אם הפונקציה לא קיימת, ניקח את שמות השדות ישירות
    cityNames = fieldnames(AllCities);
end
nCities = numel(cityNames);

scenarios = {'BAU','Moderate','Advanced'};

% שליפת רשימת השנים מהעיר הראשונה
firstCity = cityNames{1};
yearLabels = AllCities.(firstCity).TotalResults.Properties.VariableNames;
yearsNum   = str2double(yearLabels);

%% הגדרות עיצוב
cityColors = turbo(nCities); 
fs_axis   = 16;  
fs_label  = 18;  
fs_title  = 24;  
fs_legend = 13;  

rows.Emission_Total = [7 8 9]; % BAU / Moderate / Advanced

outputDir = 'C:\Users\צור\Documents\MATLAB\NewVersionCities_Partial\Results_Plots\Total_Emissions';
if ~exist(outputDir,'dir'), mkdir(outputDir); end

%% --- לולאה על תרחישים ---
for s = 1:numel(scenarios)
    scenName = scenarios{s};
    rowIdx   = rows.Emission_Total(s);
    
    % פתיחת חלון חדש - מוודא Visible מוגדר כ-'on'
    fig = figure('Name',['Total Emissions – ' scenName], ...
                 'Color','w', 'Units','normalized', ...
                 'Position', [0.1 0.1 0.7 0.7], ... % תופס 70% מהמסך
                 'Visible', 'on'); 
    
    hold on;
    
    for c = 1:nCities
        cityName = cityNames{c};
        
        if isfield(AllCities, cityName)
            TR = AllCities.(cityName).TotalResults;
            % שליפת הנתונים מהשורה הרלוונטית
            yVals = TR{rowIdx, :};   
            xVals = yearsNum;        
            
            % ציור הקווים
            plot(xVals, yVals, '-', 'Color', cityColors(c,:), 'LineWidth', 3, ...
                 'HandleVisibility', 'off'); 
            
            % ציור הנקודות
            scatter(xVals, yVals, 65, ...
                    'MarkerFaceColor', cityColors(c,:), ...
                    'MarkerEdgeColor', [0.2 0.2 0.2], ...
                    'LineWidth', 1, ...
                    'DisplayName', cityName);
        end
    end
    
    hold off;

    % עיצוב
    xlabel('Year', 'FontSize', fs_label, 'FontWeight', 'bold');
    ylabel('Total Emissions (MtCO2eq)', 'FontSize', fs_label, 'FontWeight', 'bold');
    title(['Total Emissions Projections: ', scenName], 'FontSize', fs_title, 'FontWeight', 'bold');
    
    ax = gca;
    ax.FontSize = fs_axis;
    ax.FontWeight = 'bold';
    ax.XGrid = 'on'; ax.YGrid = 'on';
    
    % מקרא
    lgd = legend('Location', 'eastoutside', 'FontSize', fs_legend, 'FontWeight', 'bold');
    title(lgd, 'Cities');
    
    % פקודה שמכריחה את מטלב לצייר את החלון עכשיו
    drawnow;
    
    % שמירה
    saveName = fullfile(outputDir, ['Total_Emissions_', scenName, '.png']);
    saveas(fig, saveName);
    
    fprintf('✔ גרף תרחיש %s הוצג ונשמר.\n', scenName);
end

disp('✔ הסקריפט הסתיים.');