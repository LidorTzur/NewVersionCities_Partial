%% =====================================================================
%  Plot_Sectoral_Share_Only_Full.m - Improved for Word-export readability
%% =====================================================================
clearvars -except AllCities; clc; close all;
[catOrder, fieldOrder] = getCityCategorical();
scenario = 'BAU';
baseCol  = 1;
outputDir = 'C:\Users\צור\Documents\MATLAB\NewVersionCities_Partial\Results_Plots\Plot_BaseSnapshot_Sectors\Plot_Share_Only';
if ~exist(outputDir, 'dir'), mkdir(outputDir); end

resConfigs = struct(...
    'Type', {'Emissions', 'Water_Total', 'Area_NoFood', 'Area'}, ...
    'Label', {'(A)', '(B)', '(C)', '(D)'}, ...
    'Title', {'Emissions', 'Water Consumption', 'Land Footprint (Excl. Food)', 'Land Footprint'} ...
);

for r = 1:numel(resConfigs)
    cfg = resConfigs(r);
    [AbsMat, TotalRow, sectorNames] = extractDataForResource(AllCities, cfg.Type, fieldOrder, scenario, baseCol);
    PctMat = (AbsMat ./ TotalRow) * 100;

    % For the Area_NoFood (Land Footprint, excl. food) graph only: show
    % the per-capita total (excl. food) above each bar, so the reader
    % isn't left with only the percentage breakdown.
    pcNoFoodLabels = [];
    pcUnit = '';
    if strcmp(cfg.Type, 'Area_NoFood')
        absNoFood = sum(AbsMat, 2);
        popMillions = zeros(numel(fieldOrder), 1);
        for i = 1:numel(fieldOrder)
            popMillions(i) = getPopMillionsByCol(AllCities.(fieldOrder{i}), baseCol, scenario);
        end
        pcNoFoodLabels = (absNoFood * 1e6) ./ (max(popMillions, eps) * 1e6);
        pcUnit = 'm^2/cap';
    end

    fig = createShareOnlyWindow(catOrder, PctMat, sectorNames, cfg, pcNoFoodLabels, pcUnit);
    % High-resolution export so labels stay crisp when pasted into Word
    exportgraphics(fig, fullfile(outputDir, [cfg.Type '_Share_Only.png']), 'Resolution', 300);
end

%% =====================================================================
%  Main Plotting Function
%% =====================================================================
function fig = createShareOnlyWindow(catOrder, Pct, sNames, cfg, pcNoFoodLabels, pcUnit)
    nCities = numel(catOrder);
    groupSizes = [3, 2, 3, 4];
    groupGap = 0.6;
    x = computeGroupedX(nCities, groupSizes, groupGap);

    % --- Larger figure canvas gives every element room to breathe ---
    fig = figure('Name', ['Share_' cfg.Type], 'Color', 'w', 'Units', 'pixels', 'Position', [200 200 1300 800]);

    colors = lines(size(Pct, 2));

    % --- Room reserved below the axes for tick labels + group labels ---
    ax = axes('Position', [0.09, 0.24, 0.85, 0.64]);
    b = bar(ax, x, Pct, 'stacked', 'BarWidth', 0.8);
    for s = 1:numel(b), b(s).FaceColor = colors(s,:); end

    applyCustomAxes(ax, catOrder, x, 'Share (%)', groupSizes);
    ylim(ax, [0 124]);
    xlim(ax, [min(x) - 0.8, max(x) + 0.8]);
    addLabels(ax, x, Pct, '%.0f%%');

    % --- Area (Land Footprint) graph only: per-capita total EXCLUDING
    %     food, above each bar ---
    if ~isempty(pcNoFoodLabels)
        for j = 1:numel(pcNoFoodLabels)
            valStr = sprintf('%.2f', pcNoFoodLabels(j));
            valStr = regexprep(valStr, '0+$', '');
            valStr = regexprep(valStr, '\.$', '');
            text(ax, x(j), 112, [valStr ' ' pcUnit], ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
                'FontSize', 14, 'FontWeight', 'bold', 'Color', [0.15 0.15 0.15], ...
                'Rotation', 30);
        end
    end

    lgd = legend(b, sNames, 'Orientation', 'horizontal', 'Location', 'southoutside', 'FontSize', 14);
    lgd.Position = [0.15, 0.03, 0.7, 0.045];

    st = sgtitle(sprintf('%s Sectoral Share: %s (2019, BAU)', cfg.Label, cfg.Title));
    st.FontSize = 22;
    st.FontWeight = 'bold';

    addFixedGroupLabels();

    % --- Subplot/axes title: set LAST, explicitly, so earlier axes
    %     FontSize assignments cannot shrink it back down ---
    ht = title(ax, ['Sector Share (%) - ' cfg.Title]);
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
%  Required Helper Functions
%% =====================================================================
function applyCustomAxes(ax, catOrder, x, unit, groupSizes)
    ylabel(ax, unit, 'FontSize', 16, 'FontWeight', 'bold');

    set(ax, 'XTick', x, 'XTickLabel', cellstr(catOrder), ...
        'XTickLabelRotation', 40, 'FontSize', 13, 'FontWeight', 'bold', ...
        'TickLabelInterpreter', 'none');
    ax.YAxis.FontSize = 13;
    ax.XAxis.FontSize = 13;

    grid(ax, 'off');
    box(ax, 'on');
    hold(ax, 'on');

    % Group separator lines placed in the middle of each gap
    currIdx = 0;
    for i = 1:numel(groupSizes)-1
        currIdx = currIdx + groupSizes(i);
        gapCenter = (x(currIdx) + x(currIdx+1)) / 2;
        xline(ax, gapCenter, '--k', 'LineWidth', 1.6);
    end
end

function addLabels(ax, x, Mat, fmt)
    acc = zeros(size(Mat, 1), 1);
    for s = 1:size(Mat, 2)
        for j = 1:size(Mat, 1)
            if Mat(j,s) > 5 % show a label only if the share exceeds 5%, to avoid clutter
                text(ax, x(j), acc(j) + Mat(j,s)/2, sprintf(fmt, Mat(j,s)), ...
                    'HorizontalAlignment', 'center', 'FontSize', 17, 'FontWeight', 'bold', 'Color', 'w');
            end
        end
        acc = acc + Mat(:,s);
    end
end

function addFixedGroupLabels()
    labels = {'Metropolises', ['Established &', newline, 'Satellites'], ['Growth', newline, 'Cities'], ['Sectoral &', newline, 'Small']};
    % Positioned close beneath the rotated city-code tick labels, centered under the single axes
    xStart = 0.09; xSpan = 0.85;
    for i = 1:4
        offset = 0;
        if i == 2, offset = -0.015; end
        if i == 3, offset = -0.03; end
        if i == 4, offset = -0.045; end
        pos = [xStart + (i-1)*(xSpan/4) + offset, 0.10, xSpan/4, 0.07];
        annotation('textbox', pos, 'String', labels{i}, 'EdgeColor', 'none', ...
            'HorizontalAlignment', 'center', 'FontSize', 13, 'FontWeight', 'bold');
    end
end

%% =====================================================================
%  Data helpers
%% =====================================================================
function [AbsMat, TotalRow, names] = extractDataForResource(AllCities, type, cities, scenario, col)
    for i = 1:numel(cities)
        C = AllCities.(cities{i});
        RDB = getScenarioRDB(C, scenario);
        switch type
            case 'Emissions'
                tbl = RDB.TotalEmissionSum1;
                sectorIdx = 1:7; totalIdx = 8;
                AbsMat(i, :) = tbl{sectorIdx, col}';
                TotalRow(i, 1) = tbl{totalIdx, col};
            case 'Water_Total'
                tbl = RDB.WaterSum1;
                sectorIdx = 1:5;
                AbsMat(i, :) = tbl{sectorIdx, col}';
                TotalRow(i, 1) = sum(AbsMat(i, :));
            case 'Area_NoFood'
                tbl = RDB.AreaSum1;
                sectorIdx = [1, 4];
                AbsMat(i, :) = tbl{sectorIdx, col}';
                TotalRow(i, 1) = sum(AbsMat(i, :));
            case 'Area'
                tbl = RDB.AreaSum1;
                sectorIdx = 1:4;
                AbsMat(i, :) = tbl{sectorIdx, col}';
                TotalRow(i, 1) = sum(AbsMat(i, :));
        end
        names = tbl.Properties.RowNames(sectorIdx);
    end
end

function RDB = getScenarioRDB(C, scen)
    if strcmp(scen, 'BAU'), RDB = C.BAU_RDB;
    elseif strcmp(scen, 'Moderate'), RDB = C.Moderate_RDB;
    else, RDB = C.Advanced_RDB; end
end

function popM = getPopMillionsByCol(C, colIdx, scen)
    RDB = getScenarioRDB(C, scen);
    popVal = RDB.population{3, colIdx};
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
