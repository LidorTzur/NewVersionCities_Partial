%% הגדרות נתיבים ונתונים
baseYear = '2019';
% הנתיב המדויק שביקשת
targetPath = 'C:\Users\צור\Documents\MATLAB\NewVersionCities_Partial\Results_Plots\Aggregated_Figures';

% יצירת התיקייה במידה ואינה קיימת
if ~exist(targetPath, 'dir')
    mkdir(targetPath);
end

cityList = fieldnames(AllCities);
numCities = numel(cityList);
sectorsE = {'Electricity', 'Transportation', 'Food', 'Construction', 'Water'};

all_e_pct = zeros(numCities, numel(sectorsE));

%% איסוף נתונים מכל הערים (תרחיש BAU)
for i = 1:numCities
    city = cityList{i};
    % שליפת טבלת הפליטות
    eTab = AllCities.(city).BAU_RDB.TotalEmissionSum1;
    
    eVals = [eTab{sectorsE{1}, baseYear}, ...
             eTab{sectorsE{2}, baseYear}, ...
             eTab{sectorsE{3}, baseYear}, ...
             eTab{sectorsE{4}, baseYear}, ...
             eTab{sectorsE{5}, baseYear}];
         
    totalE = eTab{'Total', baseYear};
    all_e_pct(i, :) = (eVals / totalE) * 100;
end

%% יצירת הגרף
hFig = figure('Color', 'w', 'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.7]);
hBar = bar(all_e_pct, 'stacked', 'FaceColor', 'flat');

% הגדרת צבעים (חשמל-כחול, תחבורה-אדום, מזון-ירוק, בנייה-סגול, מים-צהוב)
colors = [0.2 0.4 0.6; 0.8 0.3 0.3; 0.4 0.7 0.4; 0.6 0.4 0.8; 0.9 0.8 0.1];
for k = 1:numel(hBar)
    hBar(k).FaceColor = colors(k,:);
end

% הוספת תוויות אחוזים (Labels) בתוך המלבנים
for i = 1:numCities
    currentBase = 0;
    for j = 1:numel(sectorsE)
        val = all_e_pct(i, j);
        if val > 3 % מציג מספר רק אם המקטע גדול מ-3% כדי למנוע צפיפות
            % מיקום הטקסט במרכז המקטע
            textPos = currentBase + val/2;
            text(i, textPos, sprintf('%.0f%%', val), ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'Color', 'w', 'FontSize', 9, 'FontWeight', 'bold');
        end
        currentBase = currentBase + val;
    end
end

%% עיצוב הגרף
set(gca, 'XTick', 1:numCities, 'XTickLabel', cityList, 'TickLabelInterpreter', 'none');
xtickangle(45);
ylabel('GHG Emissions Breakdown (%)');
title(['Sectoral Emissions Breakdown by City (Year: ', baseYear, ')']);
legend(sectorsE, 'Location', 'northeastoutside');
grid on;
set(gca, 'Layer', 'top');

%% שמירה לתיקייה המבוקשת
fileName = ['Aggregated_Emissions_Comparison_', baseYear, '.png'];
fullSavePath = fullfile(targetPath, fileName);

% שמירה ברזולוציה גבוהה לתזה
exportgraphics(hFig, fullSavePath, 'Resolution', 300);

fprintf('\n>>> הגרף נשמר בהצלחה בנתיב:\n%s\n', fullSavePath);

%% הדפסת הפסקה הממוצעת לפרק התוצאות
avg_e = mean(all_e_pct);
fprintf('\n--- TEXT FOR YOUR THESIS (AVERAGE OF ALL CITIES) ---\n');
fprintf('Analysis of the overall urban model (averaged over 10 cities) shows that ');
fprintf('electricity is the main source (%.0f%%), followed by transportation (%.0f%%), ', avg_e(1), avg_e(2));
fprintf('food (%.0f%%), construction (%.0f%%), and water (%.0f%%).\n', avg_e(3), avg_e(4), avg_e(5));