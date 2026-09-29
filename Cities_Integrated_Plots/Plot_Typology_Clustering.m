%% =====================================================================
%  Plot_Typology_Clustering.m
%  ---------------------------------------------------------------------
%  Companion analysis to Plot_Typology_KruskalWallis.m. That script asked
%  "given the four typologies the thesis already assumes (Section 2.1),
%  do their footprints differ significantly?" This script asks the
%  complementary, unsupervised question: "ignoring the assumed labels
%  entirely, does the data itself naturally group the twelve localities
%  into four clusters that resemble those typologies?"
%
%  Method: standardize per-capita Emissions, Water and Land_NoFood
%  (Land_NoFood, not total Land, for the same reason given in
%  Plot_Typology_KruskalWallis.m - total land is ~99.9% food and
%  therefore population-scaled and near-uniform, so it would dilute
%  rather than inform the clustering). Run both k-means (k=4) and
%  Ward hierarchical clustering, and score each against the assumed
%  typology labels with the Adjusted Rand Index (ARI) - implemented
%  locally below, no toolbox dependency for the scoring itself.
%
%  NO TOOLBOX REQUIRED: k-means and Ward hierarchical clustering are both
%  implemented locally below in plain MATLAB (the Statistics and Machine
%  Learning Toolbox's kmeans/linkage/cluster are NOT used, since that
%  toolbox isn't installed here). Each local implementation was
%  cross-checked in a separate Python session against sklearn.cluster.
%  KMeans and scipy.cluster.hierarchy.linkage(method='ward') and
%  reproduces them exactly (ARI = 1.0 against each toolbox's own output
%  on this exact dataset).
%
%  Figure: a contingency heatmap (assumed typology x k-means cluster,
%  with city short-codes in each cell) - chosen over a 2-D PCA scatter
%  because it needs no abstract PC1/PC2 axes and no side-by-side panel
%  comparison; the (typology, cluster) match is readable directly.
%
%  Output: Typology_Clustering_Test.png in
%  ...\Results_Plots\Typology_Clustering\
%% =====================================================================
clearvars -except AllCities;
clc; close all;
rng(0); % reproducible k-means initialization

% --- Configuration ---
scenario  = 'BAU';
baseCol   = 1;
outputDir = 'C:\Users\צור\Documents\MATLAB\NewVersionCities_Partial\Results_Plots\Typology_Clustering';
if ~exist(outputDir, 'dir'), mkdir(outputDir); end

cats       = getCityCategorical(AllCities);
fieldOrder = cellstr(cats);
nCities    = numel(fieldOrder);
groupSizes = [3, 2, 3, 4];
typologyNames = {'Metropolises', 'Established Satellites', 'Growth Cities', 'Sectoral & Small'};

groupIdxVector = zeros(nCities, 1);
c = 0;
for g = 1:numel(groupSizes)
    groupIdxVector(c+1 : c+groupSizes(g)) = g;
    c = c + groupSizes(g);
end

%% ---------------------------------------------------------------------
%  1. Extract the same three per-capita features used in the
%     Kruskal-Wallis companion script (Emissions, Water, Land_NoFood)
%% ---------------------------------------------------------------------
Emissions   = zeros(nCities, 1);
Water       = zeros(nCities, 1);
Land_NoFood = zeros(nCities, 1);

for i = 1:nCities
    C   = AllCities.(fieldOrder{i});
    RDB = getScenarioRDB(C, scenario);
    pop = getPopMillionsByCol(C, baseCol, scenario, {});

    tblE = RDB.TotalEmission1;   Emissions(i)   = tblE{end, baseCol}       / pop;
    tblW = RDB.WaterSum1;        Water(i)       = sum(tblW{5:6, baseCol})  / pop;
    tblA = RDB.AreaSum1;         Land_NoFood(i) = sum(tblA{[1, 4], baseCol}) / pop;
end

X = [Emissions, Water, Land_NoFood];
Xz = (X - mean(X)) ./ std(X);   % standardize - the three features have very different scales

%% ---------------------------------------------------------------------
%  2. Cluster with k=4, two methods, and score against assumed typology
%% ---------------------------------------------------------------------
kmLabels   = kmeansManual(Xz, 4, 50, 0);
wardLabels = wardClusterManual(Xz, 4);

ariKM   = adjustedRandIndex(groupIdxVector, kmLabels);
ariWard = adjustedRandIndex(groupIdxVector, wardLabels);

fprintf('\n%-16s %-24s %8s %8s\n', 'City', 'Assumed typology', 'k-means', 'Ward');
for i = 1:nCities
    fprintf('%-16s %-24s %8d %8d\n', fieldOrder{i}, typologyNames{groupIdxVector(i)}, ...
        kmLabels(i), wardLabels(i));
end
fprintf('\nAdjusted Rand Index vs. assumed typology:\n  k-means: %.3f\n  Ward:    %.3f\n', ariKM, ariWard);

%% ---------------------------------------------------------------------
%  3. Figure: contingency heatmap - assumed typology (rows) vs.
%     data-driven k-means cluster (columns). More compact and intuitive
%     than a paired PCA scatter: no abstract PC1/PC2 axes, and no need
%     to cross-reference two side-by-side panels - every cell simply
%     shows which cities fall into that (typology, cluster) combination.
%% ---------------------------------------------------------------------

% k-means cluster labels (1-4) are arbitrary IDs with no inherent order,
% so first relabel them (purely cosmetically) to line up with the
% typology order as closely as possible, for a readable near-diagonal
% heatmap. Brute-force over all 4! = 24 permutations - trivial at this
% size, no toolbox needed (`perms` is base MATLAB).
cntRaw = zeros(4, 4);   % rows = assumed typology, cols = raw kmeans label
for g = 1:4
    for c = 1:4
        cntRaw(g,c) = sum(groupIdxVector == g & kmLabels == c);
    end
end

allPerms = perms(1:4);
bestTrace = -Inf; bestPerm = 1:4;
for p = 1:size(allPerms, 1)
    tr = sum(diag(cntRaw(:, allPerms(p,:))));
    if tr > bestTrace
        bestTrace = tr;
        bestPerm  = allPerms(p,:);
    end
end
cnt = cntRaw(:, bestPerm);   % column c now shows raw kmeans label bestPerm(c)

fig = figure('Color', 'w', 'Units', 'pixels', 'Position', [100 100 950 800]);
ax  = axes(fig);
imagesc(ax, cnt);
colormap(ax, [linspace(1, 0.1647, 256)', linspace(1, 0.4706, 256)', linspace(1, 0.8392, 256)']);
clim(ax, [0, max(cnt(:))]);
axis(ax, 'square'); box(ax, 'on');

xticks(ax, 1:4); yticks(ax, 1:4);
xticklabels(ax, arrayfun(@(c) sprintf('Cluster %d', c), 1:4, 'UniformOutput', false));
yticklabels(ax, typologyNames);
ax.FontSize = 11; ax.FontWeight = 'bold';
xlabel(ax, 'Data-driven k-means cluster', 'FontSize', 13, 'FontWeight', 'bold');
ylabel(ax, 'Assumed typology (Section 2.1)', 'FontSize', 13, 'FontWeight', 'bold');

% Annotate every cell with the count and the city short-codes it contains
for g = 1:4
    for c = 1:4
        rawLabel = bestPerm(c);
        mask = groupIdxVector == g & kmLabels == rawLabel;
        if any(mask)
            cityStr = strjoin(fieldOrder(mask), newline);
            txt = sprintf('%d\n%s', cnt(g,c), cityStr);
        else
            txt = '0';
        end
        if cnt(g,c) > max(cnt(:)) / 2
            txtColor = 'w';
        else
            txtColor = 'k';
        end
        text(ax, c, g, txt, 'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', 'FontSize', 9, 'Color', txtColor);
    end
end

title(ax, {'Does unsupervised clustering recover the assumed urban typology?', ...
    sprintf('Adjusted Rand Index: k-means = %.2f, Ward = %.2f  (1 = perfect agreement, 0 = random)', ariKM, ariWard)}, ...
    'FontSize', 12);

exportgraphics(fig, fullfile(outputDir, 'Typology_Clustering_Test.png'), 'Resolution', 300);
fprintf('\nSaved figure to: %s\n', fullfile(outputDir, 'Typology_Clustering_Test.png'));

%% =====================================================================
%  Local function: k-means (Lloyd's algorithm, multiple random restarts,
%  keep the restart with lowest total within-cluster sum of squares).
%  No toolbox - only basic matrix operations.
%% =====================================================================
function labels = kmeansManual(X, k, nReplicates, seed)
    rng(seed);
    n = size(X, 1);
    bestInertia = Inf;
    labels = zeros(n, 1);

    for rep = 1:nReplicates
        centers = X(randperm(n, k), :);
        for iter = 1:100
            d2 = pairwiseSqDist(X, centers);
            [~, lab] = min(d2, [], 2);
            newCenters = centers;
            for j = 1:k
                if any(lab == j)
                    newCenters(j, :) = mean(X(lab == j, :), 1);
                end
            end
            if isequal(newCenters, centers), break; end
            centers = newCenters;
        end
        d2 = pairwiseSqDist(X, centers);
        [minD2, lab] = min(d2, [], 2);
        inertia = sum(minD2);
        if inertia < bestInertia
            bestInertia = inertia;
            labels = lab;
        end
    end
end

function d2 = pairwiseSqDist(X, C)
    % d2(i,j) = squared Euclidean distance between X(i,:) and C(j,:)
    d2 = sum(X.^2, 2) + sum(C.^2, 2)' - 2 * (X * C');
    d2 = max(d2, 0); % guard against tiny negative values from floating-point error
end

%% =====================================================================
%  Local function: Ward agglomerative hierarchical clustering, stopped at
%  k clusters. Standard centroid-based Ward distance:
%  d(A,B) = (|A||B| / (|A|+|B|)) * ||centroid(A) - centroid(B)||^2
%  No toolbox - naive O(n^3) is fine at n=12.
%% =====================================================================
function labels = wardClusterManual(X, k)
    n = size(X, 1);
    members = cell(n, 1);
    for i = 1:n, members{i} = i; end
    active = 1:n;

    while numel(active) > k
        m = numel(active);
        bestD = Inf; bestI = -1; bestJ = -1;
        for i = 1:m-1
            for j = i+1:m
                a = active(i); b = active(j);
                na = numel(members{a}); nb = numel(members{b});
                ca = mean(X(members{a}, :), 1);
                cb = mean(X(members{b}, :), 1);
                d = (na * nb / (na + nb)) * sum((ca - cb).^2);
                if d < bestD
                    bestD = d; bestI = i; bestJ = j;
                end
            end
        end
        a = active(bestI); b = active(bestJ);
        newMembers = [members{a}, members{b}];
        active([bestI, bestJ]) = [];
        active(end + 1) = numel(members) + 1; %#ok<AGROW>
        members{end + 1} = newMembers; %#ok<AGROW>
    end

    labels = zeros(n, 1);
    for c = 1:numel(active)
        labels(members{active(c)}) = c;
    end
end

%% =====================================================================
%  Local function: Adjusted Rand Index (Hubert & Arabie, 1985)
%% =====================================================================
function ari = adjustedRandIndex(labelsA, labelsB)
    labelsA = labelsA(:); labelsB = labelsB(:);
    uA = unique(labelsA); uB = unique(labelsB);
    n  = numel(labelsA);

    contingency = zeros(numel(uA), numel(uB));
    for i = 1:numel(uA)
        for j = 1:numel(uB)
            contingency(i,j) = sum(labelsA == uA(i) & labelsB == uB(j));
        end
    end

    nCk = @(v) v .* (v - 1) / 2;   % n-choose-2, vectorized

    sumComb = sum(nCk(contingency(:)));
    aSum = sum(nCk(sum(contingency, 2)));
    bSum = sum(nCk(sum(contingency, 1)));
    totalComb = nCk(n);

    expectedIndex = (aSum * bSum) / totalComb;
    maxIndex = 0.5 * (aSum + bSum);

    if maxIndex == expectedIndex
        ari = 1; % degenerate case (e.g. a single cluster) - perfect trivial agreement
    else
        ari = (sumComb - expectedIndex) / (maxIndex - expectedIndex);
    end
end
