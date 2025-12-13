%% =====================================================================
%  Plot_BaseSnapshot_Sectors_AllCities.m
%  תמונת בסיס: פירוק פליטות לפי סקטורים – כל הערים יחד (2019, BAU)
%  גרף אבסולוטי + גרף פר קפיטה, צבעים לפי סקטור
%% =====================================================================

addpath('helpers');

cityNames = fieldnames(AllCities);
cities    = struct2cell(AllCities);
nCities   = numel(cities);

scenario = 'BAU';
baseCol  = 1;   % 2019

%% ---------------------------------------------------------
%  חילוץ סקטורים גלובליים
%% ---------------------------------------------------------

sectorOrder = string([]);

for c = 1:nCities
    tbl = getScenarioTable(cities{c}, scenario);
    nRaw = height(tbl) - 1; % אחרונה = Total
    sc = string(tbl.Properties.RowNames(1:nRaw));

    for nm = sc.'
        if ~ismember(nm, sectorOrder)
            sectorOrder(end+1) = nm;
        end
    end
end

nSectors = numel(sectorOrder);
sectorColors = lines(nSectors);

%% ---------------------------------------------------------
%  יצירת מטריצות נתונים
%% ---------------------------------------------------------

AbsMat = zeros(nCities, nSectors);
PCMat  = zeros(nCities, nSectors);

for c = 1:nCities
    C = cities{c};
    tbl = getScenarioTable(C, scenario);

    % מטריצה של פליטות מוחלטות לפי סקטור
    yAbs = extractSectorMatrix(tbl, sectorOrder, baseCol, baseCol);
    yAbs = yAbs(:,1);
    AbsMat(c,:) = yAbs;

    % אוכלוסייה
    pop = getPopMillionsByCol(C, baseCol, scenario, tbl.Properties.VariableNames);

    PCMat(c,:) = yAbs ./ max(pop, eps);
end

%% ---------------------------------------------------------
%  יצירת חלון גרפים
%% ---------------------------------------------------------

fig = figure('Name','Base Snapshot – Sector Breakdown (All Cities, 2019 BAU)', ...
             'Color','w','Units','pixels', ...
             'Position',[120 80 1400 650]);

tl = tiledlayout(fig, 1, 2, 'TileSpacing','compact','Padding','compact');

try
    title(tl,'Base Snapshot – Sector Breakdown (2019 BAU)');
catch
    sgtitle('Base Snapshot – Sector Breakdown (2019 BAU)');
end

%% =====================================================================
%  גרף שמאל: פליטות אבסולוטיות לכל הערים יחד
%% =====================================================================

ax1 = nexttile(tl);

cats = categorical(cityNames);
b1 = bar(ax1, cats, AbsMat, 'stacked', 'BarWidth', 0.8);

% צבעים קבועים לכל סקטור
for s = 1:nSectors
    b1(s).FaceColor = sectorColors(s,:);
end

ylabel(ax1,'MtCO2eq');
title(ax1,'Absolute Emissions by Sector – 2019 (BAU)');
grid(ax1,'on');
ax1.Box = 'off';
ax1.FontSize = 10;
set(ax1,'XTickLabelRotation',45);

%% =====================================================================
%  גרף ימין: פליטות פר קפיטה לכל הערים יחד
%% =====================================================================

ax2 = nexttile(tl);

b2 = bar(ax2, cats, PCMat, 'stacked', 'BarWidth', 0.8);

for s = 1:nSectors
    b2(s).FaceColor = sectorColors(s,:);
end

ylabel(ax2,'tCO2e per capita');
title(ax2,'Per Capita Emissions by Sector – 2019 (BAU)');
grid(ax2,'on');
ax2.Box = 'off';
ax2.FontSize = 10;
set(ax2,'XTickLabelRotation',45);

%% =====================================================================
%  מקרא (יחיד לכל הסקטורים)
%% =====================================================================

lgd = legend(ax2, cellstr(sectorOrder), ...
    'NumColumns', min(4,nSectors), 'Location','southoutside','FontSize',10);


%% =====================================================================
%  שמירה לתיקייה
%% =====================================================================

outputDir = 'C:\Users\צור\Documents\MATLAB\NewVersionCities_Partial\Results_Plots\Base_Snapshot_Sectors';
if ~exist(outputDir,'dir'), mkdir(outputDir); end

saveas(fig, fullfile(outputDir,'BaseSnapshot_Sectors_Sum_AllCities_GL_2019_BAU.png'));
saveas(fig, fullfile(outputDir,'BaseSnapshot_Sectors_Sum_AllCities_GL_2019_BAU.fig'));

disp('✔ נשמר בהצלחה: Base Snapshot Sum – Sector Breakdown for All Cities');
