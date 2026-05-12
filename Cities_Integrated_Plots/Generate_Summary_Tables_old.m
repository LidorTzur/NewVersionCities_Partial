%% =====================================================================
% Generate_Summary_Tables.m
% יוצר 3 טבלאות:
% 1) SummaryTable – long format
% 2) SummaryWide – wide format
% 3) SummaryDiffs – differences between cities
%% =====================================================================

cityNames = fieldnames(AllCities);
cities    = struct2cell(AllCities);
nCities   = numel(cities);

scenarios = {'BAU','Moderate','Advanced'};

baseCol   = 1;
targetCol = Years;

%% הגדרת מדדים מתוך TotalResults
rows.Emission_Local  = [1 2 3];
rows.Emission_Global = [4 5 6];
rows.Emission_Total  = [7 8 9];
rows.Area_Local      = [10 11 12];
rows.Area_Global     = [13 14 15];
rows.Area_Total      = [16 17 18];
rows.Water_Local     = [19 20 21];
rows.Water_Global    = [22 23 24];
rows.Water_Total     = [25 26 27];

metrics = fieldnames(rows);

%% =====================================================================
% 1) יצירת SummaryTable (long format)
%% =====================================================================

summaryRows = {};

for c = 1:nCities
    TR = cities{c}.TotalResults;

    for s = 1:numel(scenarios)
        scen = scenarios{s};
        for m = 1:numel(metrics)

            rset = rows.(metrics{m});
            r    = rset(s);

            BaseVal   = TR{r, baseCol};
            TargetVal = TR{r, targetCol};

            summaryRows(end+1, :) = { ...
                cityNames{c}, ...
                scen, ...
                metrics{m}, ...
                BaseVal, ...
                TargetVal };
        end
    end
end

SummaryTable = cell2table(summaryRows, ...
    'VariableNames', {'City','Scenario','Metric','BaseValue','TargetValue'});

writetable(SummaryTable, 'Results_Plots/SummaryTable_Long.xlsx');

disp('✔ SummaryTable (long) נוצר בהצלחה.');

%% =====================================================================
% 2) יצירת SummaryWide (wide format)
%% =====================================================================

wideRows = {};      % Scenario, Metric
wideVals = [];      % ערכים לכל הערים

for s = 1:numel(scenarios)
    scen = scenarios{s};

    for m = 1:numel(metrics)
        metric = metrics{m};

        rowVals = [];

        for c = 1:nCities
            TR = cities{c}.TotalResults;
            r  = rows.(metric)(s);

            rowVals = [rowVals, TR{r,baseCol}, TR{r,targetCol}];
        end

        wideRows(end+1,:) = {scen, metric};
        wideVals(end+1,:) = rowVals;
    end
end

% שמות עמודות
safeCityNames = regexprep(cityNames,'[^a-zA-Z0-9]','_');

colNames = {};
for c = 1:nCities
    colNames{end+1} = [safeCityNames{c}, '_Base'];
    colNames{end+1} = [safeCityNames{c}, '_Target'];
end

SummaryWide = cell2table(wideRows, 'VariableNames', {'Scenario','Metric'});
SummaryWide = [SummaryWide array2table(wideVals, 'VariableNames', colNames)];

writetable(SummaryWide, 'Results_Plots/SummaryTable_Wide.xlsx');

disp('✔ SummaryTable (wide) נוצר בהצלחה.');

%% =====================================================================
% 3) יצירת SummaryDiffs (הפרשי ערים)
%% =====================================================================

diffVals  = [];
diffNames = {};

for i = 1:nCities-1
    for j = i+1:nCities

        for valType = ["Base","Target"]

            colA = [safeCityNames{i}, '_', char(valType)];
            colB = [safeCityNames{j}, '_', char(valType)];

            diffName = [safeCityNames{i}, '_minus_', safeCityNames{j}, '_', char(valType)];

            diffNames{end+1} = diffName;
            diffVals(:,end+1) = SummaryWide.(colA) - SummaryWide.(colB);
        end
    end
end

SummaryDiffs = [SummaryWide(:,1:2), array2table(diffVals, 'VariableNames', diffNames)];

writetable(SummaryDiffs, 'Results_Plots/SummaryTable_Diffs.xlsx');

disp('✔ SummaryDiffs נוצר בהצלחה.');
disp('✔ סיימתי להפיק את כל שלוש טבלאות הסיכום.');
