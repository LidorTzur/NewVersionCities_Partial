%% =====================================================================
%  Plot_Emissions_By_Sector_AllCities.m
%  מייצר גרפים של פליטות לפי סקטור – לכל הערים יחד (Base vs Target)
%  לא אינטראקטיבי
%% =====================================================================

addpath('helpers');

cityNames = fieldnames(AllCities);
cities    = struct2cell(AllCities);
nCities   = numel(cities);

scenarios = {'BAU','Moderate','Advanced'};
baseCol   = 1;     % עמודת שנת בסיס
targetCol = Years;    % עמודת שנת יעד (2050)

%% --- שליפת סדר גלובלי של סקטורים ---
sectorOrder = string([]);

for c = 1:nCities
    tbl = getScenarioTable(cities{c}, 'BAU');   % מספיק BAU לצורך שמות
    nRaw = height(tbl) - 1;                     % השורה האחרונה היא סה"כ
    names = string(tbl.Properties.RowNames(1:nRaw));

    for nm = names.'
        if ~ismember(nm, sectorOrder)
            sectorOrder(end+1) = nm;
        end
    end
end

nSectors = numel(sectorOrder);
colors   = getSectorColors(nSectors);

%% --- לולאה על תרחישים ---
for s = 1:numel(scenarios)
    scen = scenarios{s};

    % חלון גדול
    fig = figure('Name',['Emissions by Sectors – ' scen], ...
                 'Color','w', 'Units','pixels', ...
                 'Position',[100 100 max(400*nCities, 1200) 600]);

    t = tiledlayout(fig, 1, nCities, ...
        'TileSpacing','compact', ...
        'Padding','compact');

    try
        title(t, ['Emissions by Sectors (', scen, ') – Base vs Target']);
    catch
        sgtitle(['Emissions by Sectors (', scen, ') – Base vs Target']);
    end

    %% ציור לכל עיר
    for c = 1:nCities

        % --- שליפת טבלת סקטורים לעיר ותרחיש ---
        tbl = getScenarioTable(cities{c}, scen);

        % --- הפקת מטריצת סקטורים Base/Target ---
        y = extractSectorMatrix(tbl, sectorOrder, baseCol, targetCol);   % nSectors×2

        % --- גרף ---
        ax = nexttile(t);

        cats = categorical({'Base','Target'});
        b = bar(ax, cats, y', 'stacked', 'BarWidth', 0.9);

        % צבעים אחידים לכל סקטור
        for k = 1:nSectors
            b(k).FaceColor = colors(k,:);
        end

        % עיצוב
        grid(ax,'on');
        ax.Box = 'off';
        ax.FontSize = 10;
        title(ax, cityNames{c}, 'FontSize', 13, 'FontWeight','bold');
        ylabel(ax,'MtCO2Eq');

        % Y-limits אחידים בין Base ל-Target של העיר הזו בלבד
        ymax = max(sum(y,1));
        ylim(ax, [0 ceil(ymax*1.10)]);
    end

    % --- מקרא יחיד (Legend) ---
    lgd = legend(nexttile(1), cellstr(sectorOrder), ...
        'NumColumns', min(4,nSectors), ...
        'Location','southoutside', ...
        'FontSize',10);
    try
        lgd.Layout.Tile = 'south';
    end

end

disp('✔ סיימתי להפיק את הגרפים של "Emissions by Sectors – All Cities".');
