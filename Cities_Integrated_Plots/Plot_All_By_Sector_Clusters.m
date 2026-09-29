%% =====================================================================
%  Plot_MultiResource_Final_Publication.m - Improved for Word-export readability
%  Includes both Per-Capita and Absolute-Total figures for each resource.
%% =====================================================================
addpath('helpers');

outputDir = 'C:\Users\צור\Documents\MATLAB\NewVersionCities_Partial\Results_Plots\Plot_All_By_Sector_Clusters';
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

groupNames = {'Metropolises', 'Established Satellites', 'Growth Cities', 'Sectoral & Small'};
cityGroups = { ...
    {'Tlv', 'RishonLeZion', 'BeerSheva'}, ...
    {'Raanana', 'Modiin'}, ...
    {'Hadera', 'Afula', 'KiryatGat'}, ...
    {'BeitShemesh', 'MazkeretBatya', 'Rahat', 'Sakhnin'} ...
};

% --- Manual, figure-normalized tile positions: group 4 (Sectoral &
%     Small, 4 cities x 5 bars = the most crowded panel) gets extra width.
%     Bottom margin (0.14) leaves room for a single, full-width legend row.
tilePositions = { ...
    [0.045, 0.58, 0.42, 0.34], ... % 1: Metropolises          (top-left)
    [0.545, 0.58, 0.42, 0.34], ... % 2: Established Satellites (top-right)
    [0.045, 0.14, 0.34, 0.34], ... % 3: Growth Cities          (bottom-left, still narrower)
    [0.415, 0.14, 0.545, 0.34] ... % 4: Sectoral & Small       (bottom-right, wider but less extreme)
};

cityCodes = getCityCodeMap();

% --- Per-capita configs + their absolute-total counterparts ---
resConfigs = struct(...
    'Name',      {'Emissions',       'Water',        'Land',         'Total_Emissions',    'Total_Water',   'Total_Land'}, ...
    'TableName', {'TotalEmissionSum','WaterSum',      'AreaSum',      'TotalEmissionSum',   'WaterSum',      'AreaSum'}, ...
    'Unit',      {'tCO2e/capita',    'm^3/capita',    'm^2/capita',   'Million tCO2e',      'Million m^3',   'Million m^2'}, ...
    'RowIdx',    {1:7,               1:5,             1:4,            1:7,                  1:5,             1:4}, ...
    'IsTotal',   {false,             false,           false,          true,                 true,            true} ...
);

colLabels = {'Base', '30-M', '40-M', '30-A', '40-A'};
scenList  = {'BAU', 'Moderate', 'Moderate', 'Advanced', 'Advanced'};
yearList  = {'2019', '2030', '2040', '2030', '2040'};

for r = 1:numel(resConfigs)
    cfg = resConfigs(r);
    fig = figure('Name', cfg.Name, 'Color', 'w', 'Units', 'normalized', 'Position', [0.02 0.05 0.95 0.95]);

    for g = 1:numel(cityGroups)
        ax = axes(fig, 'Position', tilePositions{g});
        hold(ax, 'on');
        ax.XColor = 'k';
        ax.YColor = 'k';
        ax.LineWidth = 1.5;
        box(ax, 'on');
        currentCities = cityGroups{g};
        isCrowded = numel(currentCities) > 3; % the "Sectoral & Small" group (4 cities x 5 bars)
        allData = [];

        for c = 1:numel(currentCities)
            C = AllCities.(currentCities{c});
            for i = 1:5
                RDB = getScenarioRDB(C, scenList{i});

                if strcmp(scenList{i}, 'BAU'), sIdx = 1;
                elseif strcmp(scenList{i}, 'Moderate'), sIdx = 2;
                else, sIdx = 3; end

                tbl = RDB.([cfg.TableName, num2str(sIdx)]);
                colIdx = find(contains(tbl.Properties.VariableNames, yearList{i}), 1);
                vals = tbl{cfg.RowIdx, colIdx};

                if cfg.IsTotal
                    % NOTE: the table values are already expressed at
                    % city scale in "Million" units (consistent with the
                    % per-capita calc below: vals ./ popMillions = per
                    % capita), so no further division is needed here.
                    columnValues = vals;
                else
                    pop = getPopMillionsByCol(C, colIdx, scenList{i}, tbl.Properties.VariableNames);
                    columnValues = vals ./ max(pop, eps);
                end
                allData = [allData, columnValues];
            end
        end

        % --- X positions with a small gap between each city's block of bars ---
        nScenPerCity = 5;
        cityGap = 0.7;
        xPos = computeGroupedX(size(allData, 2), nScenPerCity, cityGap);

        % --- Plot Stacked Bars ---
        if isCrowded
            barWidth = 0.75;
        else
            barWidth = 0.75;
        end
        b = bar(ax, xPos, allData', 'stacked', 'BarWidth', barWidth);
        colors = getDarkSectorColors(numel(cfg.RowIdx));
        for k = 1:numel(b), b(k).FaceColor = colors(k,:); end

        % --- Extra headroom above the tallest stack for the Total label
        %     (more for the crowded group so nothing clips) ---
        colSums = sum(allData, 1);
        maxVal = max(colSums);
        if isCrowded
            ylimFactor = 1.32;
        else
            ylimFactor = 1.32;
        end
        ylim(ax, [0, maxVal * ylimFactor]);
        xlim(ax, [min(xPos) - 0.8, max(xPos) + 0.8]);

        % --- Sector value labels ---
        yStacked = cumsum(allData, 1);
        if isCrowded
            labelFontSize = 11.5;
        else
            labelFontSize = 11.5;
        end

        labelRotation = 50;
        numFormat = '%.1f';
        if ~cfg.IsTotal && ismember(cfg.Name, {'Water', 'Land'})
            labelRotation = 70;
            labelFontSize = max(8, labelFontSize - 1);
            numFormat = '%.0f';
        end

        % --- Total label sizing: larger for the per-capita Emissions/Water
        %     charts specifically (per request), rotated steeply everywhere. ---
        if isCrowded
            totalFontSize = 10;
            totalRotation = 55;
            
        else
            totalFontSize = 10;
            totalRotation = 55;
        end
        if ~cfg.IsTotal && ismember(cfg.Name, {'Emissions', 'Water'})
            totalFontSize = totalFontSize + 1;
            totalRotation = 40;
        end

        for col = 1:size(allData, 2)
            colTotal = colSums(col);
            for row = 1:size(allData, 1)
                if allData(row, col) > 0.05 * max(colSums)
                    txtY = yStacked(row, col) - allData(row, col)/2;
                    if cfg.IsTotal
                        % Absolute totals vary hugely by sector -> show share (%) instead
                        pctVal = (allData(row, col) / colTotal) * 100;
                        txtStr = sprintf('%.0f%%', pctVal);
                        rot = labelRotation; % same rotation style as the per-capita labels
                        fsz = max(5, labelFontSize - 4); % shrunk further for the Total charts
                    else
                        txtStr = sprintf(numFormat, allData(row, col));
                        rot = labelRotation;
                        fsz = labelFontSize;
                    end
                    text(ax, xPos(col), txtY, txtStr, ...
                        'HorizontalAlignment', 'center', ...
                        'Rotation', rot, ...
                        'FontSize', fsz, ...
                        'Color', 'w', 'FontWeight', 'bold', ...
                        'Clipping', 'off');
                end
            end

            % --- Total label ABOVE each bar (1 decimal; trailing zeros
            %     dropped), with enough clearance so it never sits on
            %     top of / overlaps the bar itself. ---
            totalVal = colSums(col);
            totalStr = sprintf('%.1f', totalVal);
            totalStr = regexprep(totalStr, '0+$', '');
            totalStr = regexprep(totalStr, '\.$', '');
            % Y-axis label already states the unit is in Millions -> no "M" suffix needed
            
            text(ax, xPos(col), totalVal + (maxVal * 0.07), totalStr, ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
                'FontSize', totalFontSize, 'FontWeight', 'bold', ...
                'Color', [0.1 0.1 0.1], 'Rotation', totalRotation, ...
                'Clipping', 'off');
        end

        % --- Vertical separators between cities, placed at the gap centers ---
        for c = 1:numel(currentCities)-1
            line_height = maxVal * ylimFactor;
            gapCenter = (xPos(c*nScenPerCity) + xPos(c*nScenPerCity + 1)) / 2;
            line(ax, [gapCenter, gapCenter], [0, line_height], ...
                'LineStyle', '--', ...
                'Color', [0.6350, 0.0780, 0.1840], ...
                'LineWidth', 1.5);
        end

        % --- Axis formatting: larger, bolder, clearer tick labels ---
        grid(ax, 'off');
        xticks(ax, xPos);
        xticklabels(ax, repmat(colLabels, 1, numel(currentCities)));
        ax.XAxis.FontWeight = 'bold';
        ax.XAxis.TickLabelRotation = 30;
        if isCrowded
            ax.XAxis.FontSize = 11;
        else
            ax.XAxis.FontSize = 11;
        end

        % --- City code labels beneath each city's block of bars ---
        for c = 1:numel(currentCities)
            blockIdx = (c-1)*nScenPerCity + (1:nScenPerCity);
            cityCenterX = mean(xPos(blockIdx));
            cityLabel = getCityCode(cityCodes, currentCities{c});
            text(ax, cityCenterX, -maxVal*0.24, cityLabel, ...
                'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 12, ...
                'Interpreter', 'none', 'Clipping', 'off');
        end

        % --- Tile title with light background marker (shrunk to save space) ---
        t = title(ax, groupNames{g}, 'FontSize', 11, 'FontWeight', 'bold');
        t.BackgroundColor = [0.94 0.94 0.94];
        t.EdgeColor = [0.8 0.8 0.8];
        t.Margin = 3;
        t.Units = 'normalized';
        t.Position(2) = 0.9;

        ylabel(ax, cfg.Unit, 'FontWeight', 'bold', 'FontSize', 11);
    end

    % --- Legend ---
    C_ref = AllCities.(cityGroups{1}{1});
    tbl_ref = C_ref.BAU_RDB.([cfg.TableName, '1']);
    sectorNames = tbl_ref.Properties.RowNames(cfg.RowIdx);

    lgd = legend(b, sectorNames, 'Orientation', 'horizontal', 'NumColumns', numel(sectorNames), 'FontSize', 12, 'FontWeight', 'bold');
    lgd.Box = 'off';
    lgd.Units = 'normalized';
    lgd.Position = [0.05, 0.015, 0.90, 0.045];

    if cfg.IsTotal
        titleStr = sprintf('Total Absolute %s Footprint (in Millions) by Urban Typology', strrep(cfg.Name, 'Total_', ''));
    else
        titleStr = sprintf('Per Capita %s Footprint by Urban Typology', cfg.Name);
    end
    st = sgtitle(fig, titleStr, 'FontSize', 18, 'FontWeight', 'bold');

    fig.OuterPosition(4) = fig.OuterPosition(4) * 1.11;

    fileName = fullfile(outputDir, sprintf('Footprint_%s.png', cfg.Name));
    exportgraphics(fig, fileName, 'Resolution', 300);
end

fprintf('כל הגרפים נשמרו בהצלחה בתיקייה: %s\n', outputDir);

%% =====================================================================
%  Helper: short display codes for city field names
%% =====================================================================
function map = getCityCodeMap()
    fieldOrder = {'Tlv', 'RishonLeZion', 'BeerSheva', 'Raanana', 'Modiin', 'Hadera', ...
                  'Afula', 'KiryatGat', 'BeitShemesh', 'MazkeretBatya', 'Rahat', 'Sakhnin'};
    codeOrder  = {'TLV', 'RZ', 'BS', 'RAA', 'MDN', 'HAD', ...
                  'AFL', 'KG', 'BSMS', 'MB', 'RHT', 'SKN'};
    map = containers.Map(fieldOrder, codeOrder);
end

%% =====================================================================
%  Helper: X positions with a small gap inserted after every city's
%  block of `blockSize` bars
%% =====================================================================
function x = computeGroupedX(n, blockSize, gap)
    x = zeros(1, n);
    curX = 1;
    for i = 1:n
        x(i) = curX;
        curX = curX + 1;
        if mod(i, blockSize) == 0
            curX = curX + gap;
        end
    end
end

function code = getCityCode(map, fieldName)
    if isKey(map, fieldName)
        code = map(fieldName);
    else
        code = fieldName;
    end
end

%% =====================================================================
%  Helper: a dark, saturated color palette so white bold text always
%  reads clearly on top of it
%% =====================================================================
function colors = getDarkSectorColors(n)
    % יחס הזהב מבטיח שהגוונים יהיו מפוזרים היטב ולא דומים אחד לשני
    goldenRatioConjugate = 0.618033988749895;
    hues = mod((0:n-1)' * goldenRatioConjugate, 1);
    
    colors = zeros(n, 3);
    for i = 1:n
        % רוויה גבוהה (0.75 עד 0.95) כדי שהצבעים יהיו עשירים ולא "מלוכלכים" מדי
        s = 0.75 + 0.2 * mod(i, 2); 
        
        % בהירות נמוכה וקבועה יחסית (סביב 0.4 עד 0.5) כדי להבטיח מראה כהה, 
        % עם וריאציה קטנה מאוד כדי שיהיו ניתנים להבחנה זה לצד זה
        v = 0.40 + 0.12 * mod(i, 3); 
        
        colors(i,:) = hsv2rgb([hues(i), s, v]);
    end
end