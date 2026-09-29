%% =====================================================================
%  Plot_Typology_KruskalWallis.m
%  ---------------------------------------------------------------------
%  Tests, formally, the qualitative claim already made in the thesis
%  (Results 3.2.1-3.2.4) that the four urban typologies differ
%  systematically in PER-CAPITA Emissions/Water/Land at the 2019
%  baseline (e.g. "Sectoral & Small... behaves as a coherent
%  low-intensity group"). All four indicators below are computed as
%  Absolute_value / population (see section 1) - i.e. per-capita, not
%  total - matching the units of Table 3 in the thesis (tCO2e/capita,
%  m^3/capita, m^2/capita), not the absolute MtCO2e/MCM/km^2 columns.
%
%  A 4th indicator, Land_NoFood, is added on top of the three reported
%  in Table 3: land EXCLUDING food. Food is ~99.9% of the total land
%  footprint and is downscaled from a national per-capita average held
%  constant across cities (Methodology/Results 3.2.4), so it mechanically
%  washes out almost all typology signal in the "Land" test below. The
%  non-food residual (construction + electricity land take only, same
%  rows [1,4] of AreaSum1 used for the 'Area_NoFood' case in
%  Plot_BaseSnapshot.m) is exactly where the thesis's own text (3.2.4)
%  says typology differences actually live (construction-heavy Growth
%  Cities vs. electricity-dominated Tel Aviv), so it is the more
%  informative of the two land tests, not a replacement for it - report
%  both.
%
%  Because each typology group has only n = 2-4 cities, the standard
%  chi-square asymptotic approximation behind Kruskal-Wallis (and
%  one-way ANOVA) is unreliable. This script instead computes an EXACT
%  permutation test: it enumerates every one of the
%  12!/(3!*2!*3!*4!) = 277,200 distinct ways to partition the 12
%  cities into groups of size (3,2,3,4), and reports the fraction of
%  partitions whose test statistic is at least as extreme as the one
%  observed for the real typology grouping.
%
%  Reuses this project's own helpers (getCityCategorical, getScenarioRDB,
%  getPopMillionsByCol) and mirrors the baseline data-extraction logic
%  already used in Plot_BaseSnapshot.m (same tables, same rows, same
%  scenario/column), so the numbers reproduce Table 3 in the thesis.
%
%  Output: Typology_KruskalWallis_Test.png in
%  ...\Results_Plots\Typology_KruskalWallis\  (matches this repo's
%  convention: scripts live in Cities_Integrated_Plots, figures land in
%  a same-named subfolder of Results_Plots).
%% =====================================================================
clearvars -except AllCities;
clc; close all;
rng(7); % reproducible jitter in the plot only - the test itself is exact, not simulated

% --- Configuration ---
scenario  = 'BAU';
baseCol   = 1;                      % 2019 baseline column, matches Plot_BaseSnapshot.m
outputDir = 'C:\Users\צור\Documents\MATLAB\NewVersionCities_Partial\Results_Plots\Typology_KruskalWallis';
if ~exist(outputDir, 'dir'), mkdir(outputDir); end

cats      = getCityCategorical(AllCities);   % this repo's shared helper returns one output
fieldOrder = cellstr(cats);                  % city struct field names, in typology order
nCities    = numel(fieldOrder);
groupSizes  = [3, 2, 3, 4];   % Metropolises | Established Satellites | Growth Cities | Sectoral & Small
typologyNames = {'Metropolises', 'Established Satellites', 'Growth Cities', 'Sectoral & Small'};

%% ---------------------------------------------------------------------
%  1. Extract 2019 baseline per-capita Emissions / Water / Land
%     (identical data-extraction logic to Plot_BaseSnapshot.m)
%% ---------------------------------------------------------------------
Emissions    = zeros(nCities, 1);
Water        = zeros(nCities, 1);
Land         = zeros(nCities, 1);
Land_NoFood  = zeros(nCities, 1);   % land excluding food - construction + electricity only

for i = 1:nCities
    C   = AllCities.(fieldOrder{i});
    RDB = getScenarioRDB(C, scenario);
    pop = getPopMillionsByCol(C, baseCol, scenario, {}); % millions

    tblE = RDB.TotalEmission1;   Emissions(i)   = tblE{end, baseCol}       / pop; % tCO2e/capita
    tblW = RDB.WaterSum1;        Water(i)       = sum(tblW{5:6, baseCol})  / pop; % m^3/capita
    tblA = RDB.AreaSum1;         Land(i)        = tblA{end, baseCol}       / pop; % m^2/capita
                                  % same rows [1,4] as the 'Area_NoFood' case
                                  % in Plot_BaseSnapshot.m - construction + electricity land, food excluded
                                  Land_NoFood(i) = sum(tblA{[1, 4], baseCol}) / pop; % m^2/capita
end

% Typology group index vector, in the same fixed order as groupSizes
groupIdxVector = zeros(nCities, 1);
c = 0;
for g = 1:numel(groupSizes)
    groupIdxVector(c+1 : c+groupSizes(g)) = g;
    c = c + groupSizes(g);
end

fprintf('\n%-16s %-24s %10s %10s %10s %14s\n', 'City', 'Typology', 'Emissions', 'Water', 'Land', 'Land_NoFood');
for i = 1:nCities
    fprintf('%-16s %-24s %10.2f %10.2f %10.1f %14.2f\n', fieldOrder{i}, ...
        typologyNames{groupIdxVector(i)}, Emissions(i), Water(i), Land(i), Land_NoFood(i));
end

%% ---------------------------------------------------------------------
%  2. Exact permutation Kruskal-Wallis test, per indicator
%% ---------------------------------------------------------------------
indicatorNames  = {'Emissions', 'Water', 'Land', 'Land_NoFood'};        % valid struct-field names
indicatorLabels = {'Emissions', 'Water', 'Land', 'Land (no food)'};     % display-only labels
indicatorData   = {Emissions, Water, Land, Land_NoFood};
indicatorUnits  = {'tCO_2e/capita', 'm^3/capita', 'm^2/capita', 'm^2/capita'};

results = struct();
for k = 1:numel(indicatorNames)
    vals = indicatorData{k};
    [obsH, obsF] = deal(0);
    obsH = kruskalWallisH(vals, groupIdxVector, groupSizes);
    obsF = oneWayAnovaF(vals, groupIdxVector, groupSizes);
    [pExactH, pExactF, nPerm] = exactPermutationTest(vals, groupSizes, obsH, obsF);

    results.(indicatorNames{k}) = struct('H', obsH, 'pExactH', pExactH, ...
                                          'F', obsF, 'pExactF', pExactF, 'nPerm', nPerm);

    fprintf(['\n=== %s ===\n  Kruskal-Wallis H(3) = %.3f, exact p = %.4f\n' ...
             '  One-way ANOVA  F(3,%d) = %.3f, exact p = %.4f  (n_perm = %d)\n'], ...
        indicatorNames{k}, obsH, pExactH, nCities-4, obsF, pExactF, nPerm);
end

%% ---------------------------------------------------------------------
%  3. Figure: boxplot + per-city points, one panel per indicator
%% ---------------------------------------------------------------------
typologyColors = [ ...
    0.1647 0.4706 0.8392;   % blue    - Metropolises
    0.9216 0.4078 0.2039;   % orange  - Established Satellites
    0.1059 0.6863 0.4784;   % aqua    - Growth Cities
    0.9294 0.6314 0.0000];  % yellow  - Sectoral & Small

fig = figure('Color', 'w', 'Units', 'pixels', 'Position', [100 100 2000 700]);
tl  = tiledlayout(fig, 1, numel(indicatorNames), 'TileSpacing', 'loose', 'Padding', 'compact');

for k = 1:numel(indicatorNames)
    ax = nexttile(tl); hold(ax, 'on');
    vals = indicatorData{k};
    r    = results.(indicatorNames{k});

    g = categorical(typologyNames(groupIdxVector), typologyNames, 'Ordinal', true);
    bc = boxchart(ax, g, vals, 'BoxFaceColor', [0.5 0.5 0.5], 'MarkerStyle', 'none');
    bc.BoxFaceAlpha = 0.25;

    for gi = 1:numel(typologyNames)
        mask = groupIdxVector == gi;
        xj = gi + (rand(sum(mask),1) - 0.5) * 0.25;
        scatter(ax, xj, vals(mask), 60, typologyColors(gi,:), 'filled', ...
            'MarkerEdgeColor', 'w', 'LineWidth', 0.8);
    end

    if r.pExactH < 0.01, sig = 'p < 0.01 **';
    elseif r.pExactH < 0.05, sig = 'p < 0.05 *';
    else, sig = 'n.s.'; end

    % Three short lines instead of one long one - avoids title text
    % overflowing into the neighbouring panel with 4 tiles side by side.
    title(ax, {indicatorLabels{k}, ...
               sprintf('H=%.2f, exact p=%.4f', r.H, r.pExactH), ...
               sig}, ...
        'FontSize', 10, 'FontWeight', 'normal');
    ylabel(ax, indicatorUnits{k}, 'Interpreter', 'tex');
    ax.FontSize = 10;
    box(ax, 'on'); grid(ax, 'off');
end

title(tl, sprintf(['Per-capita footprints by urban typology - exact Kruskal-Wallis test ' ...
    '(n=%d; exact permutation p-values, %d group-label permutations)'], ...
    nCities, results.Emissions.nPerm), 'FontSize', 12);

exportgraphics(fig, fullfile(outputDir, 'Typology_KruskalWallis_Test.png'), 'Resolution', 300);
fprintf('\nSaved figure to: %s\n', fullfile(outputDir, 'Typology_KruskalWallis_Test.png'));

%% =====================================================================
%  Local functions
%% =====================================================================
function H = kruskalWallisH(vals, groupIdxVector, groupSizes)
    n = numel(vals);
    ranks = tiedRank(vals);
    H = 0;
    for g = 1:numel(groupSizes)
        Rg = sum(ranks(groupIdxVector == g));
        H  = H + (Rg^2) / groupSizes(g);
    end
    H = (12 / (n * (n + 1))) * H - 3 * (n + 1);
end

function F = oneWayAnovaF(vals, groupIdxVector, groupSizes)
    n = numel(vals);
    k = numel(groupSizes);
    grandMean = mean(vals);
    ssBetween = 0; ssWithin = 0;
    for g = 1:k
        gv = vals(groupIdxVector == g);
        ssBetween = ssBetween + numel(gv) * (mean(gv) - grandMean)^2;
        ssWithin  = ssWithin  + sum((gv - mean(gv)).^2);
    end
    dfB = k - 1; dfW = n - k;
    msW = ssWithin / dfW;
    if msW == 0, msW = eps; end
    F = (ssBetween / dfB) / msW;
end

function r = tiedRank(vals)
    % Average ("fractional") ranks, ties handled as in standard Kruskal-Wallis
    [sortedVals, order] = sort(vals(:));
    n = numel(vals);
    ranksSorted = zeros(n, 1);
    i = 1;
    while i <= n
        j = i;
        while j < n && sortedVals(j+1) == sortedVals(i)
            j = j + 1;
        end
        avgRank = (i + j) / 2;
        ranksSorted(i:j) = avgRank;
        i = j + 1;
    end
    r = zeros(n, 1);
    r(order) = ranksSorted;
end

function [pExactH, pExactF, nPerm] = exactPermutationTest(vals, groupSizes, obsH, obsF)
    % Enumerates every distinct way to partition the n data points into
    % groups of the given sizes, and returns the fraction at least as
    % extreme as the observed H / F. Exact - no random sampling.
    n = numel(vals);
    idx = 1:n;
    countH = 0; countF = 0; nPerm = 0;

    g1sets = nchoosek(idx, groupSizes(1));
    for a = 1:size(g1sets, 1)
        g1 = g1sets(a, :);
        rem1 = setdiff(idx, g1);
        g2sets = nchoosek(rem1, groupSizes(2));
        for b = 1:size(g2sets, 1)
            g2 = g2sets(b, :);
            rem2 = setdiff(rem1, g2);
            g3sets = nchoosek(rem2, groupSizes(3));
            for c = 1:size(g3sets, 1)
                g3 = g3sets(c, :);
                g4 = setdiff(rem2, g3);

                groupIdxVector = zeros(n, 1);
                groupIdxVector(g1) = 1; groupIdxVector(g2) = 2;
                groupIdxVector(g3) = 3; groupIdxVector(g4) = 4;

                Hp = kruskalWallisH(vals, groupIdxVector, groupSizes);
                Fp = oneWayAnovaF(vals, groupIdxVector, groupSizes);

                if Hp >= obsH - 1e-9, countH = countH + 1; end
                if Fp >= obsF - 1e-9, countF = countF + 1; end
                nPerm = nPerm + 1;
            end
        end
    end
    pExactH = countH / nPerm;
    pExactF = countF / nPerm;
end
