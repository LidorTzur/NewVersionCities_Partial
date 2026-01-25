%% =====================================================================
%  Plot_BaseSnapshot_Sectors_AllCities_Final.m
%  Window 1: Absolute Emissions (MtCO2eq)
%  Window 2: Per Capita Emissions + 100% Stacked (Percentages)
%  Fixed city order, white labels, enlarged fonts
%% =====================================================================
addpath('helpers');

% --- Get fixed city order ---
catOrder = getCityCategorical(AllCities); 
customCityOrder = cellstr(catOrder);

scenario = 'BAU';
baseCol  = 1; % Year 2019

% --- Global Font Settings ---
fs_axis   = 15; 
fs_label  = 16; 
fs_title  = 20; 
fs_data   = 13; 

%% ---------------------------------------------------------
%  Extract Global Sectors
%% ---------------------------------------------------------
sectorOrder = string([]);
for i = 1:numel(customCityOrder)
    cityName = customCityOrder{i};
    if isfield(AllCities, cityName)
        tbl = getScenarioTableSum(AllCities.(cityName), scenario);
        sc = string(tbl.Properties.RowNames(1:end-1)); 
        for nm = sc.'
            if ~ismember(nm, sectorOrder), sectorOrder(end+1) = nm; end
        end
    end
end
nSectors = numel(sectorOrder);
sectorColors = lines(nSectors);

%% ---------------------------------------------------------
%  Create Data Matrices
%% ---------------------------------------------------------
AbsMat = zeros(numel(customCityOrder), nSectors);
PCMat  = zeros(numel(customCityOrder), nSectors);
for i = 1:numel(customCityOrder)
    cityName = customCityOrder{i};
    if isfield(AllCities, cityName)
        C = AllCities.(cityName);
        tbl = getScenarioTableSum(C, scenario);
        yAbs = extractSectorMatrix(tbl, sectorOrder, baseCol, baseCol);
        AbsMat(i,:) = yAbs(:,1);
        pop = getPopMillionsByCol(C, baseCol, scenario, tbl.Properties.VariableNames);
        PCMat(i,:) = AbsMat(i,:) ./ max(pop, eps);
    end
end
PctMat = (AbsMat ./ max(sum(AbsMat, 2), eps)) * 100;

outputDir = 'C:\Users\צור\Documents\MATLAB\NewVersionCities_Partial\Results_Plots\Base_Snapshot_Sectors';
if ~exist(outputDir,'dir'), mkdir(outputDir); end

%% =====================================================================
%  Window 1: Absolute Emissions (White Labels)
%% =====================================================================
figAbs = figure('Name','Absolute Emissions','Color','w','Position',[100 100 1000 750]);
axAbs = axes(figAbs);
bAbs = bar(axAbs, catOrder, AbsMat, 'stacked', 'BarWidth', 0.8);
for s = 1:nSectors, bAbs(s).FaceColor = sectorColors(s,:); end

acc = zeros(numel(catOrder), 1);
for s = 1:nSectors
    xPos = bAbs(s).XEndPoints;
    val = AbsMat(:,s);
    for j = 1:numel(xPos)
        if val(j) > (max(sum(AbsMat,2)) * 0.04)
            % הוספת 'Color', 'w'
            text(axAbs, xPos(j), acc(j) + val(j)/2, num2str(val(j), '%.1f'), ...
                'Horiz','center', 'Vertical','middle', 'FontSize', fs_data, ...
                'FontWeight','bold', 'Color', 'w');
        end
    end
    acc = acc + val;
end
ylabel(axAbs, 'MtCO2eq', 'FontSize', fs_label);
title(axAbs, 'Total Emissions by Sector (2019)', 'FontSize', fs_title);
set(axAbs, 'FontSize', fs_axis, 'XTickLabelRotation', 45); grid on;
legend(axAbs, cellstr(sectorOrder), 'Location', 'northeastoutside', 'FontSize', fs_axis-2);

%% =====================================================================
%  Window 2: Per Capita + Percentage (White Labels)
%% =====================================================================
figRel = figure('Name','Relative Emissions','Color','w','Position',[150 150 1550 800]);
tl = tiledlayout(figRel, 1, 2, 'TileSpacing','loose','Padding','compact');

% --- Left Plot: Per Capita ---
axPC = nexttile(tl);
bPC = bar(axPC, catOrder, PCMat, 'stacked', 'BarWidth', 0.8);
for s = 1:nSectors, bPC(s).FaceColor = sectorColors(s,:); end
accPC = zeros(numel(catOrder), 1);
for s = 1:nSectors
    xPos = bPC(s).XEndPoints; val = PCMat(:,s);
    for j = 1:numel(xPos)
        if val(j) > (max(sum(PCMat,2)) * 0.04)
            % הוספת 'Color', 'w'
            text(axPC, xPos(j), accPC(j) + val(j)/2, num2str(val(j), '%.1f'), ...
                'Horiz','center', 'Vertical','middle', 'FontSize', fs_data, ...
                'FontWeight','bold', 'Color', 'w');
        end
    end
    accPC = accPC + val;
end
ylabel(axPC, 'tCO2e per capita', 'FontSize', fs_label);
title(axPC, 'Per Capita Emissions', 'FontSize', fs_title);
set(axPC, 'FontSize', fs_axis, 'XTickLabelRotation', 45); grid on;

% --- Right Plot: Sector Share ---
axPct = nexttile(tl);
bPct = bar(axPct, catOrder, PctMat, 'stacked', 'BarWidth', 0.8);
for s = 1:nSectors, bPct(s).FaceColor = sectorColors(s,:); end
accPct = zeros(numel(catOrder), 1);
for s = 1:nSectors
    xPos = bPct(s).XEndPoints; val = PctMat(:,s);
    for j = 1:numel(xPos)
        if val(j) > 6 
            % הוספת 'Color', 'w'
            text(axPct, xPos(j), accPct(j) + val(j)/2, [num2str(round(val(j))),'%'], ...
                'Horiz','center', 'Vertical','middle', 'FontSize', fs_data, ...
                'FontWeight','bold', 'Color', 'w');
        end
    end
    accPct = accPct + val;
end
ylabel(axPct, 'Percentage (%)', 'FontSize', fs_label);
title(axPct, 'Sector Share (%)', 'FontSize', fs_title);
set(axPct, 'FontSize', fs_axis, 'XTickLabelRotation', 45); ylim([0 100]); grid on;

% Shared Legend and Save
lgd = legend(axPct, cellstr(sectorOrder), 'Orientation','horizontal', 'FontSize', fs_axis);
lgd.Layout.Tile = 'south';
title(tl, 'Base Snapshot – Per Capita & Sector Distribution (2019 BAU)', 'FontSize', fs_title+2);

saveas(figAbs, fullfile(outputDir, 'BaseSnapshot_Total_Ordered.png'));
saveas(figRel, fullfile(outputDir, 'BaseSnapshot_PC_and_Percentage_Ordered.png'));
disp('✔ Figures saved with white data labels.');