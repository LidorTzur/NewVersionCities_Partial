%% =====================================================================
%  Plot_All_BaseSnapshots.m - Improved for Word-export readability
%% =====================================================================
clearvars -except AllCities;
clc; close all;

% --- Configuration ---
scenario = 'BAU';
baseCol  = 1;
outputDir = 'C:\Users\צור\Documents\MATLAB\NewVersionCities_Partial\Results_Plots\Plot_BaseSnapshot';
if ~exist(outputDir, 'dir'), mkdir(outputDir); end
[catOrder, fieldOrder] = getCityCategorical();

resourceConfigs = struct(...
    'Type', {'Emissions', 'Water', 'Area', 'Area_NoFood', 'Water_GlobalOnly'}, ...
    'Label', {'(A)', '(B)', '(C)', '(D)', '(E)'}, ...
    'TableName', {'TotalEmission1', 'WaterSum1', 'AreaSum1', 'AreaSum1', 'WaterSum1'}, ...
    'AbsUnit', {'MtCO2eq', 'MCM', 'km^2', 'km^2', 'MCM'}, ...
    'PCUnit', {'tCO2e/capita', 'm^3/capita', 'm^2/capita', 'm^2/capita', 'm^3/capita'}, ...
    'TitleModifier', {'Emissions', 'Water Consumption', 'Land Footprint', 'Land Footprint (Excl. Food)', 'Global Water Footprint'} ...
);

for r = 1:numel(resourceConfigs)
    cfg = resourceConfigs(r);
    fprintf('Generating snapshot for: %s...\n', cfg.Type);
    fig = generateBaseSnapshotPlot(AllCities, catOrder, fieldOrder, scenario, baseCol, cfg);
    % High-resolution export so labels stay crisp when pasted into Word
    exportgraphics(fig, fullfile(outputDir, sprintf('BaseSnapshot_AllCities_%s.png', cfg.Type)), ...
        'Resolution', 300);
end

%% =====================================================================
%  Main Plotting Function
%% =====================================================================
function fig = generateBaseSnapshotPlot(AllCities, catOrder, fieldOrder, scenario, baseCol, cfg)
    nCities = numel(fieldOrder);
    cityColors = lines(nCities);
    AbsValues = zeros(nCities, 1);
    PCValues  = zeros(nCities, 1);

    for i = 1:nCities
        C = AllCities.(fieldOrder{i});
        RDB = getScenarioRDB(C, scenario);
        tbl = RDB.(cfg.TableName);
        switch cfg.Type
            case 'Emissions',        AbsValues(i) = tbl{end, baseCol};
            case 'Area',             AbsValues(i) = tbl{end, baseCol};
            case 'Area_NoFood',      AbsValues(i) = sum(tbl{[1, 4], baseCol});
            case 'Water',            AbsValues(i) = sum(tbl{5:6, baseCol});
            case 'Water_GlobalOnly', AbsValues(i) = tbl{6, baseCol};
        end
        PCValues(i) = (AbsValues(i) * 1e6) / (getPopByIndex(C, scenario, baseCol) * 1e6);
    end

    % --- Larger figure canvas gives every element room to breathe ---
    fig = figure('Color', 'w', 'Units', 'pixels', 'Position', [100 100 1900 900]);

    groupSizes = [3, 2, 3, 4];

    % One decimal place for Land Footprint, Water Consumption, and
    % Global Water Footprint; two decimals for everything else.
    oneDecimalTypes = {'Area', 'Water', 'Water_GlobalOnly'};
    if any(strcmp(cfg.Type, oneDecimalTypes))
        valueFormat = '%.1f';
    else
        valueFormat = '%.2f';
    end

    % Left plot
    h1 = subplot(1, 2, 1);
    plotCustomAxes(catOrder, AbsValues, cfg.AbsUnit, sprintf('Total %s', cfg.TitleModifier), cityColors, groupSizes, valueFormat);
    set(h1, 'Position', [0.045, 0.18, 0.42, 0.70]);

    % Right plot
    h2 = subplot(1, 2, 2);
    plotCustomAxes(catOrder, PCValues, cfg.PCUnit, sprintf('Per Capita %s', cfg.TitleModifier), cityColors, groupSizes, valueFormat);
    set(h2, 'Position', [0.545, 0.18, 0.42, 0.70]);

    sgt = sgtitle(sprintf('%s Base Snapshot – %s (2019, BAU)', cfg.Label, cfg.TitleModifier));
    sgt.FontSize = 24;
    sgt.FontWeight = 'bold';

    addFixedGroupLabels();
end

%% =====================================================================
%  Helper: Custom Plotting
%% =====================================================================
function plotCustomAxes(catOrder, values, unit, titleStr, cityColors, groupSizes, valueFormat)
    ax = gca;
    nCities = numel(values);

    % --- Small visual gap between city groups ---
    groupGap = 0.6;
    x = computeGroupedX(nCities, groupSizes, groupGap);

    b = bar(ax, x, values, 'BarWidth', 0.8, 'FaceColor', 'flat');
    b.CData = cityColors;

    grid(ax, 'off');

    % --- Tick labels: enlarged, bold axis box for clarity ---
    set(ax, 'FontSize', 13, 'FontWeight', 'bold', 'TickLabelInterpreter', 'none');
    ax.YAxis.FontSize = 13;
    ax.XAxis.FontSize = 13;

    xticks(x);
    xticklabels(cellstr(catOrder));
    xtickangle(40);

    % --- Axis titles: larger and bold for legibility in Word ---
    ylabel(unit, 'FontSize', 16, 'FontWeight', 'bold');

    % Extra headroom above the tallest bar so value labels never clip
    ylim([0, max(values) * 1.32]);
    xlim([min(x) - 0.8, max(x) + 0.8]);

    % --- Data-value annotations: larger, clearer, offset from bar tip ---
    yRange = max(values) * 1.32;
    for i = 1:nCities
        valStr = sprintf(valueFormat, values(i));
        if contains(valStr, '.')
            valStr = regexprep(valStr, '0+$', '');   % drop trailing zeros
            valStr = regexprep(valStr, '\.$', '');   % drop bare trailing dot
        end
        text(x(i), values(i) + 0.015 * yRange, valStr, ...
            'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
            'FontSize', 13, 'FontWeight', 'bold', 'Rotation', 55, ...
            'Color', [0 0 0]);
    end

    % Group separator lines placed in the middle of each gap
    currIdx = 0;
    for i = 1:numel(groupSizes)-1
        currIdx = currIdx + groupSizes(i);
        gapCenter = (x(currIdx) + x(currIdx+1)) / 2;
        xline(ax, gapCenter, '--k', 'LineWidth', 1.6);
    end

    box(ax, 'on');

    % --- Subplot title: set LAST, explicitly, so the axes FontSize
    %     assignments above cannot shrink it back down ---
    ht = title(titleStr);
    ht.FontSize = 20;
    ht.FontWeight = 'bold';
    ax.TitleFontSizeMultiplier = 1;
end

%% =====================================================================
%  Helper: X positions with a small extra gap between city groups
%% =====================================================================
function x = computeGroupedX(nCities, groupSizes, groupGap)
    x = zeros(1, nCities);
    idx = 0;
    curX = 1;
    for g = 1:numel(groupSizes)
        for k = 1:groupSizes(g)
            idx = idx + 1;
            x(idx) = curX;
            curX = curX + 1;
        end
        curX = curX + groupGap;
    end
end

%% =====================================================================
%  Helper: Fixed group sub-labels beneath the X-axis city codes
%  (repositioned/enlarged slightly so they never collide with the
%   rotated city-code tick labels above them)
%% =====================================================================
function addFixedGroupLabels()
    labels = {'Metropolises', 'Established & Satellites', ['Growth &', newline, 'Cities'], ['Sectoral &', newline, 'Small']};
    xStarts = [0.045, 0.545];
    xSpans  = [0.42, 0.42];
    for side = 1:2
        for i = 1:4
            offset = 0;
            if i == 3, offset = -0.022; end
            if i == 4, offset = -0.015; end
            if i == 2, offset = -0.012; end
            pos = [xStarts(side) + (i-1)*(xSpans(side)/4) + offset, 0.01, xSpans(side)/4, 0.09];
            annotation('textbox', pos, 'String', labels{i}, ...
                'EdgeColor', 'none', 'HorizontalAlignment', 'center', ...
                'FontSize', 13, 'FontWeight', 'bold');
        end
    end
end

%% =====================================================================
%  Data helpers (unchanged)
%% =====================================================================
function RDB = getScenarioRDB(C, scen)
    if strcmp(scen, 'BAU'), RDB = C.BAU_RDB;
    elseif strcmp(scen, 'Moderate'), RDB = C.Moderate_RDB;
    else, RDB = C.Advanced_RDB; end
end
function popM = getPopByIndex(C, scen, baseCol)
    RDB = getScenarioRDB(C, scen);
    popVal = RDB.population{3, baseCol};
    if ischar(popVal) || isstring(popVal), popM = str2double(popVal); else, popM = popVal; end
end

%% =====================================================================
%  Helper: City order and short display codes
%  (fieldOrder = struct field names used to index AllCities;
%   catOrder   = ordinal categorical of the short codes used for display,
%                e.g. on X-axis tick labels)
%% =====================================================================
function [catOrder, fieldOrder] = getCityCategorical(~)
    fieldOrder = {'Tlv', 'RishonLeZion', 'BeerSheva', 'Raanana', 'Modiin', 'Hadera', ...
                  'Afula', 'KiryatGat', 'BeitShemesh', 'MazkeretBatya', 'Rahat', 'Sakhnin'};
    codeOrder  = {'TLV', 'RZ', 'BS', 'RAA', 'MDN', 'HAD', ...
                  'AFL', 'KG', 'BSMS', 'MB', 'RHT', 'SKN'};
    catOrder = categorical(codeOrder, codeOrder, 'Ordinal', true);
end
