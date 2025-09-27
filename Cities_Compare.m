
%% השוואת ערים לפי TotalResults ופליטות מפורקות
% הגדרות קלט – שים כאן את ה־ResultsDataBase של כל עיר
% cities    = {ResultsDataBase_BeerSheva, ResultsDataBase_Rashlaz, ResultsDataBase_BeitShemesh}; 
% cityNames = {'Beer-Sheva','Rishon LeZion', 'Beit Shemesh'};


% שליפה מתוך ה־struct
cityCode  = fieldnames(AllCities);          % {'BeerSheva','Rashlaz','BeitShemesh'}
cities    = cellfun(@(f) AllCities.(f), cityCode, 'UniformOutput', false);
cityNames = cityCode;

% שמות ידידותיים לגרפים/טבלאות
% cityNames = strrep(cityTags,'BeerSheva','Beer-Sheva');
% cityNames = strrep(cityNames,'Rashlaz','Rishon LeZion');
% cityNames = strrep(cityNames,'BeitShemesh','Beit Shemesh');


baseCol   = 1;   % אינדקס שנת בסיס (למשל 1 עבור 2019)
targetCol = 32;  % אינדקס שנת יעד (למשל 2050)

scenarios = {'BAU','Moderate','Advanced'};
nCities   = numel(cities);

%% --------- 1) שליפה לפי אינדקסי שורות ב-TotalResults ---------
% לפי הסדר שציינת (שורות קבועות)
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
dataTotals = nan(nCities, numel(scenarios), numel(metrics), 2);

for c = 1:nCities
    TR = cities{c}.TotalResults;

    for m = 1:numel(metrics)
        idxRows = rows.(metrics{m});
        for s = 1:3
            r = idxRows(s);
            dataTotals(c,s,m,1) = TR{r, baseCol};   % Base
            dataTotals(c,s,m,2) = TR{r, targetCol}; % Target
        end
    end
end

%% ציור Totals – Base ו-Target
for m = 1:numel(metrics)
    met = metrics{m};
    % Base
    figure('Name',[met,' Base'],'Color','w');
    Y = squeeze(dataTotals(:,:,m,1));
    bar(Y); grid on;
    title([met,' – Base']);
    set(gca,'XTick',1:nCities,'XTickLabel',cityNames);
    legend(scenarios,'Location','bestoutside');

    % Target
    figure('Name',[met,' Target'],'Color','w');
    Y = squeeze(dataTotals(:,:,m,2));
    bar(Y); grid on;
    title([met,' – Target']);
    set(gca,'XTick',1:nCities,'XTickLabel',cityNames);
    legend(scenarios,'Location','bestoutside');
end

%% --------- 2) פירוק פליטות לפי סקטורים (TotalEmission1/2/3) ---------
colorsEm = lines(11); % צבעים אוטומטיים

for s = 1:3
    scen = scenarios{s};
    figure('Name',['Emissions by Sectors – ',scen],'Color','w');
    t = tiledlayout(ceil(nCities/2),2,'TileSpacing','compact');
    title(t,['Emissions by Sectors (',scen,') Base vs Target']);

    % איסוף מקסימום עבור ylim אחיד
    yMax = 0;
    yCells = cell(1,nCities);
    for c = 1:nCities
        switch scen
            case 'BAU',      tbl = cities{c}.BAU_RDB.TotalEmission1;
            case 'Moderate', tbl = cities{c}.Moderate_RDB.TotalEmission2;
            case 'Advanced', tbl = cities{c}.Advanced_RDB.TotalEmission3;
        end
        y = [tbl{1:11, baseCol}, tbl{1:11, targetCol}];
        yCells{c} = y;
        yMax = max(yMax, max(y(:)));
    end
    ylimVals = [0 ceil(yMax*1.1)];

    % ציור
    for c = 1:nCities
        y = yCells{c};
        nexttile;
        b = bar(categorical({'Base','Target'}), y','stacked');
        for i=1:11, set(b(i),'FaceColor',colorsEm(i,:)); end
        ylim(ylimVals);
        title(cityNames{c});
        ylabel('MtCO2Eq');
        legend(flip(b), flip(tbl.Properties.RowNames(1:11)), ...
            'NumColumns',2,'Location','southoutside','FontSize',7);
    end
end







%% --------- 4) גרפי פיזור: פליטה כוללת לאורך השנים ---------
years = cities{1}.TotalResults.Properties.VariableNames; 
% בהנחה שעמודות הן שנים: {'2019','2020',...,'2050'}
% אם זה מספרי אינדקס בלבד – תעדכן כאן ידנית.

% מציאת אינדקסים של Emission_Total (באינדקסי שורה קבועים)
rows.Emission_Total = [7 8 9]; % BAU, Moderate, Advanced לפי ההגדרה שלך

colors = lines(nCities); % צבע שונה לכל עיר

for s = 1:numel(scenarios)
    scen = scenarios{s};
    r = rows.Emission_Total(s); % שורת הפליטות הכוללת המתאימה לתרחיש הזה

    figure('Name',['Emission Total – ',scen],'Color','w');
    hold on;
    for c = 1:nCities
        TR = cities{c}.TotalResults;
        yVals = TR{r, :};  % כל השנים
        xVals = 1:numel(yVals); % אינדקסי שנים
        scatter(xVals, yVals, 30, 'MarkerEdgeColor',colors(c,:), ...
                'DisplayName', cityNames{c});
        plot(xVals, yVals, '-','Color',colors(c,:), 'LineWidth',1.5);
    end
    hold off;

    % כיתוב ציר X עם שמות השנים האמיתיים
    set(gca,'XTick',1:numel(years),'XTickLabel',years,'XTickLabelRotation',45);
    xlabel('Year'); ylabel('Emission Total (MtCO2Eq)');
    title(['Total Emissions over Time – ',scen]);
    legend('Location','bestoutside');
    grid on; box off;
end



%% --------- 3) יצירת טבלת סיכום ליצוא ---------
summaryRows = {};
summaryVals = [];

for c = 1:nCities
    for s = 1:numel(scenarios)
        for m = 1:numel(metrics)
            % הוסף שורה לטבלה
            summaryRows{end+1,1} = cityNames{c};
            summaryRows{end,2}   = scenarios{s};
            summaryRows{end,3}   = metrics{m};
            summaryRows{end,4}   = dataTotals(c,s,m,1); % Base
            summaryRows{end,5}   = dataTotals(c,s,m,2); % Target
        end
    end
end

SummaryTable = cell2table(summaryRows, ...
    'VariableNames', {'City','Scenario','Metric','BaseValue','TargetValue'});

%% הצגה במסך
disp(SummaryTable);

%% כתיבה ל-Excel (שמור קובץ בשם ResultsSummary.xlsx)
writetable(SummaryTable,'ResultsSummary.xlsx');








%% --------- 3b) טבלת סיכום בפורמט wide: ערים כעמודות ---------
%% --------- 3b) טבלת סיכום בפורמט wide: ערים כעמודות ---------
wideRows = {};
wideVals = [];

for s = 1:numel(scenarios)
    for m = 1:numel(metrics)
        wideRows{end+1,1} = scenarios{s};
        wideRows{end,2}   = metrics{m};
        rowVals = [];
        for c = 1:nCities
            rowVals = [rowVals, dataTotals(c,s,m,1), dataTotals(c,s,m,2)]; % Base, Target
        end
        wideVals = [wideVals; rowVals];
    end
end

% נרמול שמות לערים – בלי תווים בעייתיים
safeCityNames = regexprep(cityNames,'[^a-zA-Z0-9]','_'); 

% כותרות לעמודות
colNames = {};
for c = 1:nCities
    colNames{end+1} = [safeCityNames{c}, '_Base'];
    colNames{end+1} = [safeCityNames{c}, '_Target'];
end

% יצירת טבלה – קודם עמודות טקסט, ואז מספרים
SummaryWide = cell2table(wideRows, 'VariableNames', {'Scenario','Metric'});
SummaryWide = [SummaryWide array2table(wideVals, 'VariableNames', colNames)];

disp(SummaryWide);
writetable(SummaryWide,'ResultsSummary_Wide.xlsx');



%% --------- 3c) טבלת הפרשים בין ערים ---------
diffVals = [];
diffNames = {};

for i = 1:nCities-1
    for j = i+1:nCities
        for valType = ["Base","Target"]
            colA = [safeCityNames{i}, '_', char(valType)]; % המרה ל-char
            colB = [safeCityNames{j}, '_', char(valType)];
            diffNames{end+1} = [safeCityNames{i}, '_minus_', safeCityNames{j}, '_', char(valType)];

            % שימוש ב-char כדי לגשת לעמודות
            diffCol = SummaryWide.(colA) - SummaryWide.(colB);
            diffVals = [diffVals, diffCol];
        end
    end
end

SummaryDiffs = [SummaryWide(:,1:2), array2table(diffVals,'VariableNames',diffNames)];

disp(SummaryDiffs);
writetable(SummaryDiffs,'ResultsSummary_Diffs.xlsx');
