%% =====================================================================
%  Plot_Figure14_LeverRankInstability.m
%  Figure 14 - Lever rank instability (2030 vs 2040), small-multiples
%  slope chart by locality.
%
%  STANDALONE / READ-ONLY SCRIPT
%  - Does not modify any file in the repository.
%  - Assumes 'AllCities' is already loaded in the base workspace
%    (as in your other Cities_Integrated_Plots scripts). If it is not
%    found, it will attempt to load it from AllCities.mat in the
%    current MATLAB path, exactly like your other plotting scripts
%    expect.
%
%  Purpose: demonstrate that mitigation-lever priority (ranked by
%  absolute normalized elasticity magnitude) is not stable between the
%  mid-term (2030) and long-term (2040) horizon, and that this
%  instability differs by locality -> a single national / single-year
%  ranking is insufficient for policy sequencing.
%% =====================================================================

%% 0. Load data if needed (non-destructive - does not touch disk files)
if ~exist('AllCities', 'var')
    if exist('AllCities.mat', 'file')
        fprintf('Loading AllCities.mat...\n');
        S = load('AllCities.mat');
        AllCities = S.AllCities;
    else
        error(['AllCities not found in workspace and AllCities.mat not found on path. ', ...
               'Load the model output before running this script.']);
    end
end

%% 1. City list, typology groups, and colors (consistent with existing scripts)
allCityNames = {'Tlv', 'RishonLeZion', 'BeerSheva', 'Raanana', 'Modiin', ...
                'Hadera', 'Afula', 'KiryatGat', 'BeitShemesh', ...
                'MazkeretBatya', 'Rahat', 'Sakhnin'};
nCities = numel(allCityNames);

% Typology grouping, matching spearman.m / getCityCategorical.m ordering
cityTypology = { ...
    'Tlv',            'Metropolises'; ...
    'RishonLeZion',   'Metropolises'; ...
    'BeerSheva',      'Metropolises'; ...
    'Raanana',        'Established Satellites'; ...
    'Modiin',         'Established Satellites'; ...
    'Hadera',         'Growth Cities'; ...
    'Afula',          'Growth Cities'; ...
    'KiryatGat',      'Growth Cities'; ...
    'BeitShemesh',    'Sectoral & Small'; ...
    'MazkeretBatya',  'Sectoral & Small'; ...
    'Rahat',          'Sectoral & Small'; ...
    'Sakhnin',        'Sectoral & Small' ...
};

% Target horizons (base year 2019, per model convention)
yearA = 2030; idxA = yearA - 2019 + 1;
yearB = 2040; idxB = yearB - 2019 + 1;

% Output directory (kept inside Results_Plots like your other figures)
outputDir = fullfile('Results_Plots', 'Final_Figures');
if ~exist(outputDir, 'dir'), mkdir(outputDir); end

%% 2. Identify the 10 mitigation levers (same filtering as your other scripts)
firstCity = allCityNames{1};
if ~(isfield(AllCities, firstCity) && isfield(AllCities.(firstCity), 'Sensitivity_RDB_All_Years'))
    error('Sensitivity_RDB_All_Years not found. Please run the sensitivity model first.');
end

scenNames = AllCities.(firstCity).Sensitivity_RDB_All_Years.EmissionByScenario{1}.Properties.VariableNames;
if numel(scenNames) >= 14
    scenNames([6, 13, 14]) = []; % drop the same non-lever / excluded columns as in existing scripts
end
nLevers = numel(scenNames);
fprintf('Figure 14: tracking rank instability for %d mitigation levers across %d localities.\n', nLevers, nCities);
fprintf('Lever columns used: %s\n', strjoin(scenNames, ', '));
if nLevers ~= 10
    fprintf(['NOTE: expected 10 mitigation levers but found %d after the standard [6,13,14] filter ', ...
             '(that filter only applies when the raw scenario table has >=14 columns). Check the ', ...
             'printed list above and adjust the exclusion indices in this script if some non-lever ', ...
             'columns (e.g. a baseline/reference column) still need to be dropped.\n'], nLevers);
end

% Readable lever labels (underscores -> spaces), used for legend/labels
leverLabelsClean = strrep(scenNames, '_', ' ');

%% 3. Compute normalized elasticity magnitude and local rank, per city, per horizon
elasticity_2030 = nan(nCities, nLevers);
elasticity_2040 = nan(nCities, nLevers);

for i = 1:nCities
    cityName = allCityNames{i};
    if ~(isfield(AllCities, cityName) && isfield(AllCities.(cityName), 'Sensitivity_RDB_All_Years'))
        warning('City %s missing Sensitivity_RDB_All_Years. Skipping.', cityName);
        continue;
    end
    SR = AllCities.(cityName).Sensitivity_RDB_All_Years;

    for s = 1:nLevers
        scenarioName = scenNames{s};

        % --- 2030 ---
        if idxA <= numel(SR.EmissionByScenario)
            TA = SR.EmissionByScenario{idxA};
            if istable(TA) && ismember(scenarioName, TA.Properties.VariableNames)
                baseValA = TA{1, scenarioName};
                plusValA = TA{2, scenarioName};
                if baseValA ~= 0
                    percChangeA = ((plusValA - baseValA) / baseValA) * 100;
                    relPctA = getRelInputChangePct(SR, scenarioName);
                    elasticity_2030(i, s) = percChangeA / relPctA;
                end
            end
        end

        % --- 2040 ---
        if idxB <= numel(SR.EmissionByScenario)
            TB = SR.EmissionByScenario{idxB};
            if istable(TB) && ismember(scenarioName, TB.Properties.VariableNames)
                baseValB = TB{1, scenarioName};
                plusValB = TB{2, scenarioName};
                if baseValB ~= 0
                    percChangeB = ((plusValB - baseValB) / baseValB) * 100;
                    relPctB = getRelInputChangePct(SR, scenarioName);
                    elasticity_2040(i, s) = percChangeB / relPctB;
                end
            end
        end
    end
end

% Rank by ABSOLUTE magnitude within each city/horizon: rank 1 = largest |elasticity|
% (ties resolved by 'average' rank, consistent with tiedrank-style logic; using
% descending sort so the strongest lever gets rank 1)
rank_2030 = nan(nCities, nLevers);
rank_2040 = nan(nCities, nLevers);
for i = 1:nCities
    rank_2030(i, :) = local_rank_desc(abs(elasticity_2030(i, :)));
    rank_2040(i, :) = local_rank_desc(abs(elasticity_2040(i, :)));
end

%% 4. Colors: one fixed, distinguishable color+marker per lever (consistent across all panels)
% Publication-quality qualitative palette (colorblind-friendlier, high separation)
leverColors = [
    0.8500, 0.3250, 0.0980;  % orange-red
    0.0000, 0.4470, 0.7410;  % blue
    0.4660, 0.6740, 0.1880;  % green
    0.4940, 0.1840, 0.5560;  % purple
    0.9290, 0.6940, 0.1250;  % gold
    0.3010, 0.7450, 0.9330;  % cyan
    0.6350, 0.0780, 0.1840;  % dark red
    0.0000, 0.0000, 0.0000;  % black
    0.7500, 0.0000, 0.7500;  % magenta
    0.4000, 0.4000, 0.4000;  % gray
];
% If more than 10 levers, extend palette cyclically (should not occur; nLevers should be 10)
if nLevers > size(leverColors, 1)
    extra = lines(nLevers - size(leverColors, 1));
    leverColors = [leverColors; extra];
end

leverMarkers = {'o', 's', 'd', '^', 'v', 'p', 'h', '>', '<', 'x'};
if nLevers > numel(leverMarkers)
    leverMarkers = repmat(leverMarkers, 1, ceil(nLevers / numel(leverMarkers)));
end

%% 5. Small-multiples slope chart: one panel per locality (3x4 grid, typology-ordered)
% -------------------------------------------------------------------
% IMPORTANT: this figure is authored at its INTENDED FINAL PRINT SIZE in
% inches (not a large on-screen pixel canvas that later gets shrunk to fit
% a Word page). If you build a huge canvas and then shrink it into a
% Word column/page, every font/marker shrinks by the same factor and
% becomes illegible. Sizing it correctly from the start, in inches, with
% fonts chosen for THAT physical size, is what keeps it readable.
%
% Default target here: 13 x 8.5 in, i.e. a LANDSCAPE page. In Word:
%   Insert the image, then use a rotated/landscape page (or a landscape
%   section break) sized close to 13x8.5in so the figure is placed near
%   its native size instead of being squeezed into a portrait column.
% If you must keep it in a portrait page instead, either (a) reduce to a
% 2x6 or 4x3 panel grid with fewer, larger panels, or (b) tell me and
% I will re-tune target size/fonts for a ~6.5in-wide portrait insert.
% -------------------------------------------------------------------
figWidthIn  = 14;
figHeightIn = 12.5; % taller again: legend now uses a bigger font/4-row block, so it needs
                     % more of the reserved bottom strip without squeezing the panels

fig = figure('Name', 'Figure 14 - Lever Rank Instability', 'Color', 'w', ...
             'Units', 'inches', 'Position', [0.5, 0.5, figWidthIn, figHeightIn]);
t = tiledlayout(fig, 3, 4, 'TileSpacing', 'compact', 'Padding', 'compact');
t.OuterPosition = [0.00, 0.13, 1.00, 0.86]; % reserve bottom space for the larger (4-row) legend strip

xPos = [1, 2]; % 2030, 2040

for i = 1:nCities
    ax = nexttile(t);
    hold(ax, 'on');

    for s = 1:nLevers
        yVals = [rank_2030(i, s), rank_2040(i, s)];
        if any(isnan(yVals)), continue; end
        plot(ax, xPos, yVals, '-', 'Color', leverColors(s, :), 'LineWidth', 2.6, ...
             'Marker', leverMarkers{s}, 'MarkerSize', 9, ...
             'MarkerFaceColor', leverColors(s, :), 'MarkerEdgeColor', 'k');
    end

    % Font sizes below are tuned for a ~13x8.5in physical print size (see
    % figWidthIn/figHeightIn above) so text stays legible at that size in
    % the final Word document, rather than for on-screen viewing.
    set(ax, 'XTick', xPos, 'XTickLabel', {num2str(yearA), num2str(yearB)}, ...
        'YTick', 1:nLevers, 'YDir', 'reverse', ...
        'FontSize', 13, 'FontWeight', 'bold', 'Box', 'on', ...
        'TickLength', [0.006 0.006], 'LineWidth', 1.1);
    ax.YAxis.FontSize = 11; % rank labels (1..nLevers) are dense; slightly smaller than X
    xlim(ax, [0.7, 2.3]);
    ylim(ax, [0.5, nLevers + 0.5]);
    grid(ax, 'on');
    set(ax, 'GridLineStyle', ':', 'GridAlpha', 0.5, 'GridLineWidth', 1.0);

    cityIdxInTypology = find(strcmp(cityTypology(:, 1), allCityNames{i}), 1);
    typologyLabel = cityTypology{cityIdxInTypology, 2};
    title(ax, sprintf('%s\n(%s)', allCityNames{i}, typologyLabel), ...
        'FontSize', 15, 'FontWeight', 'bold');

    if mod(i, 4) == 1
        ylabel(ax, 'Rank (1 = highest impact)', 'FontSize', 13, 'FontWeight', 'bold');
    end
    hold(ax, 'off');
end

title(t, 'Figure 14: Mitigation-Lever Rank Instability Between 2030 and 2040', ...
    'FontSize', 22, 'FontWeight', 'bold');
subtitle(t, 'Rank of each lever by absolute normalized elasticity magnitude, per locality', ...
    'FontSize', 15);

%% 6. Shared legend (direct-labeling proxy via a dedicated legend axis)
% Full-width, dedicated strip along the bottom of the figure (below the
% tiledlayout, which was confined above via t.OuterPosition) so labels
% have room and nothing overlaps the last row of panels.
lgdAx = axes(fig, 'Position', [0.005, 0.002, 0.99, 0.115], 'Visible', 'off');
hold(lgdAx, 'on');
legendHandles = gobjects(nLevers, 1);
for s = 1:nLevers
    legendHandles(s) = plot(lgdAx, NaN, NaN, '-', 'Color', leverColors(s, :), ...
        'LineWidth', 3.2, 'Marker', leverMarkers{s}, 'MarkerSize', 12, ...
        'MarkerFaceColor', leverColors(s, :), 'MarkerEdgeColor', 'k');
end
% 3 columns (4 rows) keeps each row narrower, which is what lets the font
% go this large without the row width exceeding the page.
nLegendCols = max(1, min(3, ceil(nLevers / 4)));
lgd = legend(lgdAx, legendHandles, leverLabelsClean, 'Orientation', 'horizontal', ...
    'NumColumns', nLegendCols, 'Location', 'south', 'FontSize', 16, 'Box', 'off', ...
    'Interpreter', 'none');
lgd.Position(1) = max(0.005, 0.5 - lgd.Position(3)/2); % re-center horizontally, but never go off-page
lgd.Position(2) = 0.005;                                % pin close to the bottom edge to remove dead space
% NOTE: lgdAx is a manually-positioned axes (not a tile of 't'), so it is
% NOT a child of the tiledlayout and has no .Layout.Tile property to set.
% Its placement is controlled directly via the axes 'Position' above plus
% the manual re-centering of lgd.Position.

%% 7. Optional diagnostic: system-wide rank instability metric (Spearman rho per city)
% Quantifies, per locality, how stable the 2030 ranking is relative to 2040
% (rho -> 1 = stable ranking, rho -> -1/0 = strong reordering), printed to console
% for reporting alongside the figure (does not alter the figure itself).
fprintf('\n--- Lever rank stability (Spearman rho, 2030 vs 2040 rank) by locality ---\n');
for i = 1:nCities
    validIdx = ~isnan(rank_2030(i, :)) & ~isnan(rank_2040(i, :));
    if nnz(validIdx) >= 2
        rho = spearman_rho_no_toolbox(rank_2030(i, validIdx), rank_2040(i, validIdx));
        fprintf('%-15s rho = %.3f\n', allCityNames{i}, rho);
    end
end
fprintf('---------------------------------------------------------------------\n\n');

%% 8. Save figure: high-resolution PNG + vector PDF
pngPath = fullfile(outputDir, 'Figure14_LeverRankInstability.png');
pdfPath = fullfile(outputDir, 'Figure14_LeverRankInstability.pdf');

drawnow; % ensure the figure/legend/tiledlayout are fully rendered before export
fig = ancestor(gcf, 'figure'); % re-resolve a live handle to the current figure defensively

% The figure was created directly at its intended physical size in inches
% (figWidthIn x figHeightIn), so the PDF page and the PNG's implied print
% size both match that size exactly - no separate pixel-to-inch
% reinterpretation step, which is what previously caused the export to
% balloon to an unintentionally huge physical size.
set(fig, 'Renderer', 'painters', 'PaperPositionMode', 'auto', 'PaperUnits', 'inches');
set(fig, 'PaperSize', [figWidthIn, figHeightIn], 'PaperPosition', [0 0 figWidthIn figHeightIn]);

% 300 dpi at 13x8.5in -> a ~3900x2550px PNG. That resolution, inserted at
% (roughly) its native 13x8.5in size in Word, is what keeps text sharp;
% inserting it much SMALLER than that (e.g. squeezed into a portrait
% column) will still shrink the fonts along with everything else.
print(fig, pngPath, '-dpng', '-r300');     % matches the '-dpng -r300' convention used in spearman.m
print(fig, pdfPath, '-dpdf', '-painters'); % vector PDF (painters renderer, no rasterization)

fprintf('Figure 14 saved:\n  PNG: %s\n  PDF: %s\n', pngPath, pdfPath);

%% ===================== Local helper functions =====================
function rho = spearman_rho_no_toolbox(rx, ry)
    % Spearman rank correlation computed without the Statistics and
    % Machine Learning Toolbox (no dependency on corr()). Since rx and ry
    % here are already ranks (1..n, with tie-averaging already applied by
    % local_rank_desc), this reduces to the Pearson correlation of the
    % rank vectors - same approach as compute_spearman.m in
    % Manual Plots/spearman.m elsewhere in this codebase.
    rx = rx(:); ry = ry(:);
    rx_mean = mean(rx); ry_mean = mean(ry);
    numerator = sum((rx - rx_mean) .* (ry - ry_mean));
    denominator = sqrt(sum((rx - rx_mean).^2) * sum((ry - ry_mean).^2));
    if denominator == 0
        rho = 0;
    else
        rho = numerator / denominator;
    end
end

function r = local_rank_desc(v)
    % Ranks values in v in DESCENDING order (largest -> rank 1).
    % Ties are given the average rank (consistent with compute_spearman.m
    % / get_ranks.m convention used elsewhere in this codebase, just
    % applied to a descending order instead of ascending).
    n = numel(v);
    r = nan(1, n);
    validIdx = ~isnan(v);
    if ~any(validIdx)
        return;
    end
    vv = v(validIdx);
    [sorted_v, sortIdx] = sort(vv, 'descend');
    ranks = zeros(size(vv));
    i = 1;
    while i <= numel(sorted_v)
        j = i;
        while j < numel(sorted_v) && sorted_v(j+1) == sorted_v(i)
            j = j + 1;
        end
        avgRank = (i + j) / 2;
        ranks(sortIdx(i:j)) = avgRank;
        i = j + 1;
    end
    origIdx = find(validIdx);
    r(origIdx) = ranks;
end