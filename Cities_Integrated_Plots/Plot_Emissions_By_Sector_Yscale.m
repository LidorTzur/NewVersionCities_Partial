%% =====================================================================
%  Plot_Emissions_MultiScen_Final_Guaranteed.m
%  Goal: Absolute separation of Total vs Per Capita to fix headers.
%% =====================================================================
addpath('helpers');

% --- 1. הגדרת הקבוצות ---
groupNames = {'Metropolises', 'Established Satellites', 'Growth Cities', 'Sectoral & Small'};
cityGroups = { ...
    {'Tlv', 'RishonLeZion', 'BeerSheva'}, ...
    {'Raanana', 'Modiin'}, ...
    {'Hadera', 'Afula', 'KiryatGat'}, ...
    {'BeitShemesh', 'MazkeretBatya'} ...
};

% --- 2. הגדרות תצוגה ---
fs_axis = 11; fs_title = 15; fs_data = 10; fs_legend = 10; 
targetYears = [2019, 2035, 2050];
scenarios = {'BAU', 'Moderate', 'Advanced'};

% יצירת תיקיית פלט
outputDir = 'Results_Plots\Plot_Emissions_By_Sector\Grouped_Cities_Analysis';
if ~exist(outputDir, 'dir'), mkdir(outputDir); end

for s = 1:numel(scenarios)
    scen = scenarios{s};
    
    % מריצים פעמיים - פעם אחת לכל סוג כדי למנוע טעויות לולאה
    for mode = 1:2
        isPC = (mode == 2); 
        
        if isPC
            type = 'PerCapita';
            headerStr = 'Per Capita Emissions';
            unitStr = 'tCO2e / capita';
        else
            type = 'Total';
            headerStr = 'Total Emissions';
            unitStr = 'MtCO2eq';
        end
        
        fig = figure('Name', [type ' - ' scen], 'Color', 'w', ...
                     'Units', 'normalized', 'Position', [0.05 0.05 0.9 0.85]);
        
        tl = tiledlayout(fig, 2, 2, 'TileSpacing', 'loose', 'Padding', 'compact');
        sgtitle(fig, sprintf('%s by Urban Typology: %s', headerStr, scen), ...
                'FontSize', 22, 'FontWeight', 'bold');

        for g = 1:numel(cityGroups)
            currentCities = cityGroups{g};
            ax = nexttile(tl);
            hold(ax, 'on');
            
            allY = [];
            yearLabels = {};
            cityMidPoints = []; 
            currentX = 1;

            for c = 1:numel(currentCities)
                cityName = currentCities{c};
                if isfield(AllCities, cityName)
                    C = AllCities.(cityName);
                    tbl = getScenarioTableSum(C, scen);
                    cityMidPoints(c) = currentX + 1; 
                    
                    for yr = targetYears
                        colIdx = find(contains(tbl.Properties.VariableNames, num2str(yr)), 1);
                        res = extractSectorMatrix(tbl, sectorOrder, colIdx, colIdx);
                        
                        % שליפת הנתון
                        y_vals = res(:, 2); 
                        if isPC
                            % חלוקה באוכלוסייה לגרף Per Capita
                            pop = getPopMillionsByCol(C, colIdx, scen, tbl.Properties.VariableNames);
                            y_vals = y_vals ./ max(pop, eps); 
                        end
                        
                        allY = [allY, y_vals];
                        yearLabels{end+1} = num2str(yr);
                        currentX = currentX + 1;
                    end
                end
            end
            
            b = bar(ax, allY', 'stacked', 'BarWidth', 0.8);
            for k = 1:numel(b)
                if k <= size(colors,1), b(k).FaceColor = colors(k,:); end
            end
            
            % תוויות מספרים
            yStacked = cumsum(allY, 1);
            yCenters = yStacked - allY/2;
            localMax = max(sum(allY, 1));
            
            for k = 1:size(allY, 2)
                for sect = 1:size(allY, 1)
                    val = allY(sect, k);
                    if val > (localMax * 0.07)
                        txtColor = 'w';
                        if mean(colors(sect,:)) > 0.65, txtColor = 'k'; end
                        text(ax, k, yCenters(sect, k), num2str(val, '%.1f'), ...
                            'HorizontalAlignment', 'center', 'FontSize', fs_data, ...
                            'Color', txtColor, 'FontWeight', 'bold');
                    end
                end
                text(ax, k, sum(allY(:, k)), num2str(sum(allY(:, k)), '%.2f'), ...
                    'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', ...
                    'FontSize', fs_data, 'FontWeight', 'bold');
            end
            
            xticks(ax, 1:numel(yearLabels));
            xticklabels(ax, yearLabels);
            for c = 1:numel(currentCities)
                text(ax, cityMidPoints(c), -localMax*0.12, currentCities{c}, ...
                    'FontSize', fs_axis + 1, 'FontWeight', 'bold', ...
                    'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
            end
            
            title(ax, groupNames{g}, 'FontSize', fs_title, 'FontWeight', 'bold');
            ylabel(ax, unitStr, 'FontWeight', 'bold');
            grid(ax, 'on');
            ylim(ax, [0 localMax * 1.45]); 
        end
        
        lgd = legend(b, cellstr(sectorOrder), 'NumColumns', 3, 'FontSize', fs_legend);
        lgd.Layout.Tile = 'south';
        
        % שמירה - שם הקובץ תואם לתוכן
        saveName = fullfile(outputDir, sprintf('Emissions_%s_Groups_%s.png', type, scen));
        exportgraphics(fig, saveName, 'Resolution', 300);
    end
end