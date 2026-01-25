%% =====================================================================
%  Plot_BaseSnapshot_Sectors_Combined.m
%  Window: Total Emissions (Loc vs Glob) + Sector Percentage Breakdown
%  Consistent Colors using getSectorColors
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
fs_legend = 13;

%% ---------------------------------------------------------
%  Data Extraction & Consistent Colors
%% ---------------------------------------------------------
sectorOrder = string([]);
for i = 1:numel(customCityOrder)
    cityName = customCityOrder{i};
    if isfield(AllCities, cityName)
        tblSectors = getScenarioTable(AllCities.(cityName), scenario);
        sc = string(tblSectors.Properties.RowNames(1:end-1)); 
        for nm = sc.'
            if ~ismember(nm, sectorOrder), sectorOrder(end+1) = nm; end
        end
    end
end
nSectors = numel(sectorOrder);

% --- שימוש באותה פונקציה מהקוד השני לקבלת צבעים אחידים ---
sectorColors = getSectorColors(nSectors);

nCities = numel(customCityOrder);
AbsMat_Sectors = zeros(nCities, nSectors);
Total_LocGlob  = zeros(nCities, 2); 

for i = 1:nCities
    cityName = customCityOrder{i};
    if isfield(AllCities, cityName)
        C = AllCities.(cityName);
        tblSectors = getScenarioTable(C, scenario);
        yAbs = extractSectorMatrix(tblSectors, sectorOrder, baseCol, baseCol);
        AbsMat_Sectors(i,:) = yAbs(:,1);
        
        % חילוץ גלובלי/לוקאלי
        totalTbl = C.TotalResults;
        Total_LocGlob(i, 1) = totalTbl{1, baseCol}; % Local
        Total_LocGlob(i, 2) = totalTbl{4, baseCol}; % Global
    end
end

% חישוב מטריצת אחוזים
PctMat_Sectors = (AbsMat_Sectors ./ max(sum(AbsMat_Sectors, 2), eps)) * 100;

outputDir = 'C:\Users\צור\Documents\MATLAB\NewVersionCities_Partial\Results_Plots\Base_Snapshot_Sectors';
if ~exist(outputDir,'dir'), mkdir(outputDir); end

%% =====================================================================
%  יצירת חלון משולב
%% =====================================================================
figComb = figure('Name','Total and Sector Breakdown','Color','w','Position',[100 100 1600 850]);
tl = tiledlayout(figComb, 1, 2, 'TileSpacing','loose','Padding','compact');

% --- גרף שמאל: סה"כ פליטות (Local vs Global) ---
axTotal = nexttile(tl);
bTotal = bar(axTotal, catOrder, Total_LocGlob, 'stacked', 'BarWidth', 0.8);

% קביעת צבעים לגרף השמאלי (משתמשים בצבעים הראשון והשני מהרשימה הגנרית)
bTotal(1).FaceColor = sectorColors(1,:); % צבע לוקאלי
bTotal(1).DisplayName = 'Local Emissions';
bTotal(2).FaceColor = sectorColors(2,:); % צבע גלובאלי
bTotal(2).DisplayName = 'Global Emissions';

% Labels
accT = zeros(nCities, 1);
for s = 1:2
    xPos = bTotal(s).XEndPoints; val = Total_LocGlob(:,s);
    for j = 1:numel(xPos)
        if val(j) > (max(sum(Total_LocGlob,2)) * 0.05)
            text(axTotal, xPos(j), accT(j) + val(j)/2, num2str(val(j), '%.1f'), ...
                'Horiz','center', 'Vertical','middle', 'FontSize', fs_data, 'FontWeight','bold', 'Color', 'w');
        end
    end
    accT = accT + val;
end
ylabel(axTotal, 'MtCO2eq', 'FontSize', fs_label);
title(axTotal, 'Total Emissions: Local vs Global', 'FontSize', fs_title);
set(axTotal, 'FontSize', fs_axis, 'XTickLabelRotation', 45); grid on;
legend(axTotal, 'Location', 'northeast', 'FontSize', fs_legend, 'Box', 'on');

% --- גרף ימין: אחוזים לפי סקטורים ---
axPct = nexttile(tl);
bPct = bar(axPct, catOrder, PctMat_Sectors, 'stacked', 'BarWidth', 0.8);

% יישום אותם צבעים לכל סקטור בדיוק כמו בקוד השני
for s = 1:nSectors
    bPct(s).FaceColor = sectorColors(s,:);
end

% Labels
accPct = zeros(nCities, 1);
for s = 1:nSectors
    xPos = bPct(s).XEndPoints; val = PctMat_Sectors(:,s);
    for j = 1:numel(xPos)
        if val(j) > 6 
            text(axPct, xPos(j), accPct(j) + val(j)/2, [num2str(round(val(j))),'%'], ...
                'Horiz','center', 'Vertical','middle', 'FontSize', fs_data, 'FontWeight','bold', 'Color', 'w');
        end
    end
    accPct = accPct + val;
end
ylabel(axPct, 'Percentage (%)', 'FontSize', fs_label);
title(axPct, 'Sector Share Breakdown (%)', 'FontSize', fs_title);
set(axPct, 'FontSize', fs_axis, 'XTickLabelRotation', 45); ylim([0 100]); grid on;

% מקרא סקטורים (קובייה)
lgd = legend(axPct, cellstr(sectorOrder), 'FontSize', fs_legend, 'Box', 'on');
lgd.Layout.Tile = 'south'; 
lgd.NumColumns = ceil(nSectors/2); 

title(tl, 'Base Snapshot: Magnitude & Composition (2019 BAU)', 'FontSize', fs_title+2);
saveas(figComb, fullfile(outputDir, 'BaseSnapshot_Total_and_Share_Combined.png'));
disp('✔ Figure saved with consistent sector colors.');