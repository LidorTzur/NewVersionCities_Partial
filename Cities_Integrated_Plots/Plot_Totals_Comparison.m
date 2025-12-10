%% Plot_Totals_Comparison.m
% יוצר גרפים של השוואת ערים לפי TotalResults (Base vs Target)

addpath('helpers');

cityNames = fieldnames(AllCities);
cities    = struct2cell(AllCities);
nCities   = numel(cities);

scenarios = {'BAU','Moderate','Advanced'};
baseCol   = 1;
targetCol = Years;

%% אינדקסים ב-TotalResults
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

%% שליפת נתונים
for c = 1:nCities
    TR = cities{c}.TotalResults;
    for m = 1:numel(metrics)
        rset = rows.(metrics{m});
        for s = 1:numel(scenarios)
            r = rset(s);
            dataTotals(c,s,m,1) = TR{r,baseCol};
            dataTotals(c,s,m,2) = TR{r,targetCol};
        end
    end
end

%% הפקת גרפים
for m = 1:numel(metrics)
    metricName = metrics{m};

    figure('Color','w');
    tiledlayout(1,3);

    for s = 1:numel(scenarios)
        nexttile;
        bar(squeeze(dataTotals(:,s,m,:)));
        title([metricName ' – ' scenarios{s}]);
        xticklabels(cityNames);
        xtickangle(45);
        legend({'Base','Target'});
        grid on;
    end
end

disp('✔ סיימתי ליצור את הגרפים של TotalResults Base/Target.');
