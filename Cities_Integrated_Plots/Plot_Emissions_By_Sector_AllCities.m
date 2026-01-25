%% =====================================================================
%  Plot_Emissions_By_Sector_AllCities.m
%% =====================================================================
addpath('helpers');
cityNames = fieldnames(AllCities);
cities    = struct2cell(AllCities);
nCities   = numel(cities);
scenarios = {'BAU','Moderate','Advanced'};
baseCol   = 1;     
targetCol = Years;    

% --- הגדרות פונטים ---
fs_axis = 12;
fs_title_main = 24; % הגדלנו עוד את הכותרת הראשית
fs_title_city = 13; % הגדלנו כותרת עיר

%% --- שליפת סקטורים וצבעים (נשאר זהה) ---
sectorOrder = string([]);
for c = 1:nCities
    tbl = getScenarioTable(cities{c}, 'BAU');   
    nRaw = height(tbl) - 1;                     
    names = string(tbl.Properties.RowNames(1:nRaw));
    for nm = names.'
        if ~ismember(nm, sectorOrder), sectorOrder(end+1) = nm; end
    end
end
nSectors = numel(sectorOrder);
colors   = getSectorColors(nSectors);

%% Output path
outputDir = 'C:\Users\צור\Documents\MATLAB\NewVersionCities_Partial\Results_Plots\Base_Target_All_Cities';
if ~exist(outputDir,'dir'), mkdir(outputDir); end

%% --- לולאה על תרחישים ---
for s = 1:numel(scenarios)
    scen = scenarios{s};
    
    % --- שינוי 1: הגדלת רוחב החלון ל-550 פיקסלים לכל עיר ---
    figWidth = max(550 * nCities, 1400); 
    fig = figure('Name',['Emissions by Sectors – ' scen], ...
                 'Color','w', 'Units','pixels', ...
                 'Position', [50 50 figWidth 700]); % הגבהנו מעט את החלון
    
    % --- שינוי 2: שימוש ב-compact כדי לנצל מקסימום שטח לגרפים ---
    t = tiledlayout(fig, 1, nCities, ...
        'TileSpacing', 'compact', ...
        'Padding', 'compact'); 

    % כותרת ראשית מוגדלת
    titleStr = ['Emissions by Sectors (', scen, ') – Base vs Target'];
    try
        ttl = title(t, titleStr);
        ttl.FontSize = fs_title_main;
        ttl.FontWeight = 'bold';
    catch
        st = sgtitle(fig, titleStr);
        st.FontSize = fs_title_main;
        st.FontWeight = 'bold';
    end

    %% ציור לכל עיר
    for c = 1:nCities
        tbl = getScenarioTable(cities{c}, scen);
        y = extractSectorMatrix(tbl, sectorOrder, baseCol, targetCol);
        
        ax = nexttile(t);
        cats = categorical({'Base','Target'});
        cats = reordercats(cats, {'Base','Target'}); % לוודא סדר
        
        % BarWidth = 0.8-0.9 בד"כ נראה יותר טוב מ-1 (שנראה כמו גוש אחד)
        b = bar(ax, cats, y', 'stacked', 'BarWidth', 0.85);
        
        for k = 1:nSectors
            b(k).FaceColor = colors(k,:);
        end
        
        % עיצוב
        grid(ax,'on');
        ax.Box = 'off';
        ax.FontSize = fs_axis;
        title(ax, cityNames{c}, 'FontSize', fs_title_city, 'FontWeight','bold');
        
        % רק בגרף הראשון נשים כותרת ציר Y
        if c == 1
            ylabel(ax, 'MtCO2Eq', 'FontSize', fs_axis + 2, 'FontWeight', 'bold');
        end
        
        ymax = max(sum(y,1));
        ylim(ax, [0 ceil(ymax*1.15)]);
    end

    % --- שינוי 3: מקרא בתחתית מבלי להסתיר את הצירים ---
    lgd = legend(ax, cellstr(sectorOrder), ...
        'NumColumns', ceil(nSectors/2), ...
        'Location', 'southoutside', ...
        'FontSize', 11, 'FontWeight', 'bold');
    lgd.Layout.Tile = 'south';

    fileName = ['Base_Target_All_Cities_', scen, '.png'];
    saveas(fig, fullfile(outputDir, fileName));

end