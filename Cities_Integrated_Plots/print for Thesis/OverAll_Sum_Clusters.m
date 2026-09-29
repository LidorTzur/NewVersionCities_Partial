% =========================================================================
% OverAll_Sum_Clusters.m
% Figure: "The Demographic Decoupling Frontier"
% -------------------------------------------------------------------------
% Two side-by-side panels (Advanced | Moderate) show, for each of the 12
% localities, projected population growth 2019-2040 (x) against the
% projected change in TOTAL municipal emissions 2019-2040 (y), colored by
% urban typology. A regression line is fit per panel and its zero-crossing
% marks the "decoupling threshold" -- the population growth rate beyond
% which absolute emissions rise instead of fall. The background is shaded
% green (emissions fall) / red (emissions rise) so the reader sees the
% decoupling boundary at a glance, and the threshold itself is marked with
% a labelled vertical line.
% =========================================================================

%% ---- Group / typology definitions -------------------------------------
groupNames = {'Metropolises', 'Established Satellites', 'Growth Cities', 'Sectoral & Small'};
cityGroups = { ...
    {'Tlv', 'RishonLeZion', 'BeerSheva'}, ...
    {'Raanana', 'Modiin'}, ...
    {'Hadera', 'Afula', 'KiryatGat'}, ...
    {'BeitShemesh', 'MazkeretBatya', 'Rahat', 'Sakhnin'} ...
};
colors = lines(length(groupNames));

% Scenarios to plot side-by-side: {label, RDB field, TotalEmissionSum field}
scenarios = { ...
    'Advanced', 'Advanced_RDB', 'TotalEmissionSum3'; ...
    'Moderate', 'Moderate_RDB', 'TotalEmissionSum2' ...
};

%% ---- Pull population + emission deltas for every city / scenario ------
% cityLabels{k}   = city name (k = 1..12, same order across scenarios)
% groupIdx(k)     = which typology group city k belongs to
% deltaP(k)       = population growth 2019-2040 (%), scenario-independent
% deltaE(s,k)     = total-emissions change 2019-2040 (%) for scenario s

cityLabels = {};
groupIdx   = [];
deltaP     = [];
deltaE     = nan(size(scenarios,1), 0);

for g = 1:length(cityGroups)
    citiesInGroup = cityGroups{g};
    for c = 1:length(citiesInGroup)
        cityName = citiesInGroup{c};
        cityData = AllCities.(cityName);

        % Population (row 3 = population; cols 1 = 2019, 22 = 2040)
        pop_array = getRowValues(cityData.BAU_RDB.population, 3);
        pop_2019  = pop_array(1);
        pop_2040  = pop_array(2);
        dP = (pop_2040 - pop_2019) / pop_2019 * 100;

        cityLabels{end+1}         = cityName; %#ok<SAGROW>
        groupIdx(end+1)           = g;        %#ok<SAGROW>
        deltaP(end+1)             = dP;       %#ok<SAGROW>

        colIdx = length(cityLabels);   % this city's column index in deltaE
        for s = 1:size(scenarios,1)
            fieldRDB = scenarios{s,2};
            fieldSum = scenarios{s,3};
            em_array = getRowValues(cityData.(fieldRDB).(fieldSum), 8);
            em_2019  = em_array(1);
            em_2040  = em_array(2);
            deltaE(s, colIdx) = (em_2040 - em_2019) / em_2019 * 100; %#ok<SAGROW>
        end
    end
end

%% ---- Shared axis limits so both panels are directly comparable --------
xPad = 12;
yPad = 20;
xLimShared = [min(deltaP) - xPad, max(deltaP) + xPad];
yLimShared = [min(deltaE(:)) - yPad, max(deltaE(:)) + yPad];

%% ---- Build the figure ---------------------------------------------------
fig = figure('Color', 'w', 'Position', [80, 80, 1500, 700]);
t = tiledlayout(fig, 1, size(scenarios,1), 'TileSpacing', 'compact', 'Padding', 'compact');

for s = 1:size(scenarios,1)
    ax = nexttile(t);
    hold(ax, 'on');

    y_s = deltaE(s, :);

    % --- Regression fit for this scenario ---
    coeffs    = polyfit(deltaP, y_s, 1);
    slope     = coeffs(1);
    intercept = coeffs(2);
    yFit      = intercept + slope * xLimShared;
    yhat      = polyval(coeffs, deltaP);
    ss_res    = sum((y_s - yhat).^2);
    ss_tot    = sum((y_s - mean(y_s)).^2);
    r2        = 1 - ss_res/ss_tot;
    threshold = -intercept / slope;   % zero-crossing: max growth compatible with absolute reduction

    % --- Shaded decrease / increase regions (green below 0, red above 0) ---
    patch(ax, [xLimShared(1) xLimShared(2) xLimShared(2) xLimShared(1)], ...
              [0 0 yLimShared(2) yLimShared(2)], ...
              [1 0.90 0.90], 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'HandleVisibility', 'off');
    patch(ax, [xLimShared(1) xLimShared(2) xLimShared(2) xLimShared(1)], ...
              [yLimShared(1) yLimShared(1) 0 0], ...
              [0.88 0.96 0.88], 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'HandleVisibility', 'off');

    % --- Zero-change reference line ---
    yline(ax, 0, ':k', 'LineWidth', 1.3, 'HandleVisibility', 'off');

    % --- Decoupling threshold (vertical line + label) ---
    xline(ax, threshold, '-', sprintf('Decoupling threshold: %.1f%%', threshold), ...
        'Color', [0.25 0.25 0.25], 'LineWidth', 1.6, 'LabelOrientation', 'horizontal', ...
        'LabelVerticalAlignment', 'bottom', 'LabelHorizontalAlignment', 'right', ...
        'FontSize', 9.5, 'FontWeight', 'bold', 'HandleVisibility', 'off');

    % --- Scatter points by typology, with simple alternating label offsets ---
    for g = 1:length(cityGroups)
        idx = find(groupIdx == g);
        scatter(ax, deltaP(idx), y_s(idx), 130, colors(g,:), 'filled', ...
            'MarkerEdgeColor', 'k', 'LineWidth', 0.8, 'DisplayName', groupNames{g});
    end
    placeLabelsNoOverlap(ax, deltaP, y_s, cityLabels, 11, xLimShared, yLimShared);

    % --- Regression line ---
    plot(ax, xLimShared, yFit, '-', 'Color', [0.10 0.10 0.60], 'LineWidth', 2.5, ...
        'DisplayName', sprintf('Fit: \\DeltaE = %.1f + %.3f\\times\\DeltaP  (R^2=%.3f)', intercept, slope, r2));

    % --- Formatting ---
    xlim(ax, xLimShared);
    ylim(ax, yLimShared);
    grid(ax, 'on');
    set(ax, 'FontSize', 11, 'LineWidth', 1.1);
    xlabel(ax, 'Projected Population Growth 2019-2040 (%)', 'FontSize', 12.5, 'FontWeight', 'bold');
    if s == 1
        yl = ylabel(ax, 'Total Municipal Emissions Change 2019-2040 (%)', 'FontSize', 12.5, 'FontWeight', 'bold');
        yl.Position(1) = yl.Position(1) - 0.018*diff(xLimShared);   % nudge label further left, away from axis
    end
    title(ax, sprintf('%s Pathway', scenarios{s,1}), 'FontSize', 14, 'FontWeight', 'bold');
    lgd = legend(ax, 'Location', 'southoutside', 'FontSize', 12.5, 'NumColumns', 2);
    lgd.FontWeight = 'bold';
    lgd.EdgeColor = [0 0 0];
    lgd.LineWidth = 1.2;
    lgd.Box = 'on';
    hold(ax, 'off');
end

sgtitle(t, 'The Demographic Decoupling Frontier: Population Growth vs. Absolute Emissions Change (2019-2040)', ...
    'FontSize', 15, 'FontWeight', 'bold');

%% ---- Save the figure -----------------------------------------------------
% Saved to Results_Plots\<this script's name>\<script name>.png (high-res,
% Word-friendly) so every re-run overwrites the same file in the same place.
scriptName = mfilename;
if isempty(scriptName)
    scriptName = 'OverAll_Sum_Clusters';
end
outDir = fullfile('C:\Users\צור\Documents\MATLAB\NewVersionCities_Partial\Results_Plots', scriptName);
if ~exist(outDir, 'dir')
    mkdir(outDir);
end
exportgraphics(fig, fullfile(outDir, [scriptName '.png']), 'Resolution', 300);

% =========================================================================
function placeLabelsNoOverlap(ax, xData, yData, labels, fontSize, xRange, yRange)
% Places a text label next to every (xData(k), yData(k)) point, then
% iteratively nudges labels apart -- using their ACTUAL rendered text
% extents, not the font size -- until no two labels overlap and no label
% covers a marker. Font size is never shrunk; only positions move. If a
% label ends up meaningfully displaced from its point, a thin grey
% leader line connects them so the reader can still tell which label
% belongs to which city.

    n = numel(xData);
    xData = xData(:)'; yData = yData(:)';

    % Small initial vertical offset, alternating above/below the marker,
    % so labels don't start stacked exactly on top of the points.
    y0 = yData;
    for k = 1:n
        if mod(k,2) == 0
            y0(k) = yData(k) + 0.018*diff(yRange);
        else
            y0(k) = yData(k) - 0.018*diff(yRange);
        end
    end

    % Create the text objects (centered) so we can measure their true
    % on-screen extent.
    h = gobjects(1,n);
    for k = 1:n
        h(k) = text(ax, xData(k), y0(k), labels{k}, ...
            'FontSize', fontSize, 'FontWeight', 'bold', 'Color', [0.12 0.12 0.12], ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
            'Clipping', 'off');
    end
    drawnow;

    % Small fixed radius (in data units) reserved around every marker so
    % labels don't sit on top of the dots themselves.
    markerRadiusX = 0.012*diff(xRange);
    markerRadiusY = 0.012*diff(yRange);

    maxIter = 300;
    for iter = 1:maxIter
        moved = false;
        ext = cell(1,n);
        pos = zeros(n,2);
        for k = 1:n
            ext{k} = get(h(k), 'Extent');   % [x y w h] in data units
            p = get(h(k), 'Position');      % [x y z]
            pos(k,:) = p(1:2);
        end

        % Pairwise label-vs-label repulsion
        for i = 1:n
            for j = i+1:n
                bi = ext{i}; bj = ext{j};
                overlapX = min(bi(1)+bi(3), bj(1)+bj(3)) - max(bi(1), bj(1));
                overlapY = min(bi(2)+bi(4), bj(2)+bj(4)) - max(bi(2), bj(2));
                if overlapX > 0 && overlapY > 0
                    moved = true;
                    ci = [bi(1)+bi(3)/2, bi(2)+bi(4)/2];
                    cj = [bj(1)+bj(3)/2, bj(2)+bj(4)/2];
                    d  = ci - cj;
                    if norm(d) < eps, d = [1 1]*eps; end
                    pushX = overlapX/2 * sign(d(1) + (d(1)==0)*1);
                    pushY = overlapY/2 * sign(d(2) + (d(2)==0)*1);
                    pos(i,1) = pos(i,1) + 0.55*pushX;
                    pos(i,2) = pos(i,2) + 0.55*pushY;
                    pos(j,1) = pos(j,1) - 0.55*pushX;
                    pos(j,2) = pos(j,2) - 0.55*pushY;
                end
            end
        end

        % Label-vs-marker repulsion (push labels off every data point,
        % not just their own)
        for i = 1:n
            bi = ext{i};
            ci = [bi(1)+bi(3)/2, bi(2)+bi(4)/2];
            for m = 1:n
                dx = ci(1) - xData(m);
                dy = ci(2) - yData(m);
                halfW = bi(3)/2 + markerRadiusX;
                halfH = bi(4)/2 + markerRadiusY;
                if abs(dx) < halfW && abs(dy) < halfH
                    moved = true;
                    ox = halfW - abs(dx);
                    oy = halfH - abs(dy);
                    if ox < oy
                        pos(i,1) = pos(i,1) + ox*sign(dx + (dx==0)*1);
                    else
                        pos(i,2) = pos(i,2) + oy*sign(dy + (dy==0)*1);
                    end
                end
            end
        end

        % Clamp inside the axis limits and apply
        for k = 1:n
            pos(k,1) = min(max(pos(k,1), xRange(1)+0.01*diff(xRange)), xRange(2)-0.01*diff(xRange));
            pos(k,2) = min(max(pos(k,2), yRange(1)+0.01*diff(yRange)), yRange(2)-0.01*diff(yRange));
            set(h(k), 'Position', [pos(k,1), pos(k,2)]);
        end

        if ~moved
            break;
        end
    end

    % Leader lines for labels that ended up notably displaced from their point
    for k = 1:n
        finalPos = get(h(k), 'Position');
        dispX = finalPos(1) - xData(k);
        dispY = finalPos(2) - yData(k);
        if hypot(dispX/diff(xRange), dispY/diff(yRange)) > 0.028
            plot(ax, [xData(k) finalPos(1)], [yData(k) finalPos(2)], '-', ...
                'Color', [0.55 0.55 0.55], 'LineWidth', 0.6, 'HandleVisibility', 'off');
        end
    end
    uistack(h, 'top');
end

% =========================================================================
function vals = getRowValues(tbl, row)
% Extracts [2019, 2040] values from a result table: column 1 = 2019,
% column 22 = 2040, and `row` selects the variable of interest
% (row 3 = population, row 8 = total emissions, in these result tables).
    if istable(tbl)
        arr = table2array(tbl);
    else
        arr = tbl;
    end
    vals = double([arr(row,1), arr(row,22)]);
end
