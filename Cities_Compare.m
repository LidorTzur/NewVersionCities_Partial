
%% ================================
%% השוואת ערים לפי TotalResults ופליטות מפורקות
%% ================================

% שליפה מתוך ה־struct
cityCode  = fieldnames(AllCities);          % {'BeerSheva','Rashlaz','BeitShemesh','Tlv' ...}
cities    = cellfun(@(f) AllCities.(f), cityCode, 'UniformOutput', false);
cityNames = cityCode;

baseCol   = 1;    % אינדקס שנת בסיס (למשל 1 עבור 2019)
targetCol = Years;   % אינדקס שנת יעד (למשל 2050)

scenarios = {'BAU','Moderate','Advanced'};
nCities   = numel(cities);

%% --------- 1) שליפה לפי אינדקסי שורות ב-TotalResults ---------
rows.Emission_Local  = [1 2 3];
rows.Emission_Global = [4 5 6];
rows.Emission_Total  = [7 8 9];
rows.Area_Local      = [10 11 12];
rows.Area_Global     = [13 14 15];
rows.Area_Total      = [16 17 18];
rows.Water_Local     = [19 20 21];
rows.Water_Global    = [22 23 24];
rows.Water_Total     = [25 26 27];

metrics = fieldnames(rows);
dataTotals = nan(nCities, numel(scenarios), numel(metrics), 2);

for c = 1:nCities
    TR = cities{c}.TotalResults;
    for m = 1:numel(metrics)
        idxRows = rows.(metrics{m});
        for s = 1:3
            r = idxRows(s);
            dataTotals(c,s,m,1) = TR{r, baseCol};    % Base
            dataTotals(c,s,m,2) = TR{r, targetCol};  % Target
        end
    end
end

% %% --------- ציור Totals – Base ו-Target ---------
% for m = 1:numel(metrics)
%     met = metrics{m};
% 
%     % Base
%     figure('Name',[met,' Base'],'Color','w');
%     Y = squeeze(dataTotals(:,:,m,1));
%     bar(Y); grid on;
%     title([met,' – Base']);
%     set(gca,'XTick',1:nCities,'XTickLabel',cityNames);
%     legend(scenarios,'Location','bestoutside');
% 
%     % Target
%     figure('Name',[met,' Target'],'Color','w');
%     Y = squeeze(dataTotals(:,:,m,2));
%     bar(Y); grid on;
%     title([met,' – Target']);
%     set(gca,'XTick',1:nCities,'XTickLabel',cityNames);
%     legend(scenarios,'Location','bestoutside');
% end


%% --------- 2) פירוק פליטות לפי סקטורים (TotalEmission1/2/3) ---------

% פלטת צבעים קבועה לכל 11 הקטגוריות (כמו colors1Em בדוגמה שלך)
colorsEmFixed = [
    0.72, 0.27, 1.00;
    0.49, 0.18, 0.56;
    0.93, 0.69, 0.13;
    0.51, 0.37, 0.01;
    0.29, 0.89, 0.69;
    0.47, 0.67, 0.19;
    0.85, 0.33, 0.10;
    0.64, 0.08, 0.18;
    0.30, 0.75, 0.93;
    0.00, 0.45, 0.74;
    0.00, 1.00, 0.74;
];

if nCities < 1
    error('לא נמצאו ערים ב-AllCities.');
end

for s = 1:numel(scenarios)
    scen = scenarios{s};

    % פיגר רחב בהתאם למספר הערים (≈420px לכל גרף)
    figure('Name',['Emissions by Sectors – ',scen], ...
           'Color','w','Units','pixels', ...
           'Position',[100 100, max(420*nCities, 1200), 520]);

    % כל הגרפים בשורה אחת
    t = tiledlayout(1, nCities, 'TileSpacing','compact', 'Padding','compact');
    try
        title(t, ['Emissions by Sectors (',scen,')  Base vs Target']);
    catch
        sgtitle(['Emissions by Sectors (',scen,')  Base vs Target']);
    end

    % --- סדר גלובלי של שמות הקטגוריות (לפי הופעה בכל הערים בתרחיש) ---
    sectorOrder = strings(0,1);
    for c = 1:nCities
        switch scen
            case 'BAU',      tbl = cities{c}.BAU_RDB.TotalEmission1;
            case 'Moderate', tbl = cities{c}.Moderate_RDB.TotalEmission2;
            case 'Advanced', tbl = cities{c}.Advanced_RDB.TotalEmission3;
        end
        names = string(tbl.Properties.RowNames(1:11));
        for nm = names.'
            if ~any(sectorOrder == nm)
                sectorOrder(end+1,1) = nm; %#ok<AGROW>
            end
        end
    end
    nSectors = numel(sectorOrder);

    % לוודא שיש מספיק צבעים — אם לא, נוסיף אוטומטית
    if size(colorsEmFixed,1) < nSectors
        extra = lines(nSectors - size(colorsEmFixed,1));
        colorsEmFixed = [colorsEmFixed; extra];
    end

    % --- חישוב ylim אחיד לפי גובה הערימה (Base/Target) הגבוה ביותר ---
    yCells    = cell(1,nCities);
    yMaxStack = 0;
    for c = 1:nCities
        switch scen
            case 'BAU',      tbl = cities{c}.BAU_RDB.TotalEmission1;
            case 'Moderate', tbl = cities{c}.Moderate_RDB.TotalEmission2;
            case 'Advanced', tbl = cities{c}.Advanced_RDB.TotalEmission3;
        end

        % השלמת קטגוריות חסרות + יישור לפי סדר גלובלי
        have = ismember(sectorOrder, string(tbl.Properties.RowNames));
        if ~all(have)
            missingNames = sectorOrder(~have);
            Z = array2table(zeros(numel(missingNames), width(tbl)), ...
                 'RowNames', cellstr(missingNames), ...
                 'VariableNames', tbl.Properties.VariableNames);
            tbl = [tbl; Z]; %#ok<AGROW>
        end
        tbl = tbl(cellstr(sectorOrder), :);  % סדר קבוע בכל הערים

        % מטריצה nSectors×2 (Base, Target)
        y = [tbl{1:nSectors, baseCol}, tbl{1:nSectors, targetCol}];
        yCells{c} = y;

        % גובה סטאק לכל קטגוריית X (Base/Target)
        yMaxStack = max(yMaxStack, max(sum(y, 1)));
    end
    ylimVals = [0, ceil(yMaxStack * 1.10)];  % 10% מרווח עליון

    % --- ציור לכל עיר (זה לצד זה) ---
    axFirst = [];
    bLegend = [];
    for c = 1:nCities
        y  = yCells{c};
        ax = nexttile(t);
        if isempty(axFirst), axFirst = ax; end

        cats = categorical({'Base','Target'});
        b = bar(ax, cats, y', 'stacked', 'BarWidth', 0.9);

        % צבע קבוע לפי אינדקס הקטגוריה בסדר הגלובלי
        for k = 1:nSectors
            set(b(k), 'FaceColor', colorsEmFixed(k, :));
        end

        ylim(ax, ylimVals);
        grid(ax,'on'); ax.Box='off'; ax.LineWidth=1; ax.FontSize=10;
        title(ax, cityNames{c}, 'FontSize', 13, 'FontWeight', 'bold');
        ylabel(ax, 'MtCO2Eq');

        if isempty(bLegend), bLegend = b; end
    end

    % --- מקרא יחיד, לפי סדר הקטגוריות הגלובלי ---
    lgd = legend(axFirst, bLegend, cellstr(sectorOrder), ...
        'NumColumns', min(4, nSectors), ...
        'Location','southoutside', 'FontSize', 10);
    try, lgd.Layout.Tile = 'south'; end
end


%------------------------------ interactive----------------------------
%% --------- 2a) Emissions by Sectors (Interactive, Absolute) ---------
% יחידות: MtCO2Eq. Base מול שנה נבחרת (ברירת מחדל 2050).
if nCities < 1, error('לא נמצאו ערים ב-AllCities.'); end
% צבעים קבועים (אותם כמו ב-per capita כדי לשמור על עקביות)
colorsEmFixed = [
    0.72, 0.27, 1.00;
    0.49, 0.18, 0.56;
    0.93, 0.69, 0.13;
    0.51, 0.37, 0.01;
    0.29, 0.89, 0.69;
    0.47, 0.67, 0.19;
    0.85, 0.33, 0.10;
    0.64, 0.08, 0.18;
    0.30, 0.75, 0.93;
    0.00, 0.45, 0.74;
    0.00, 1.00, 0.74;
];

% שמות שנים
yearLabels = cities{1}.TotalResults.Properties.VariableNames;
nYears     = numel(yearLabels);
defaultYear = find(strcmp(yearLabels,'2050'));
if isempty(defaultYear), defaultYear = nYears; end

% חלון + פאנלים
figW = max(450*nCities, 1200);
figH = 600;
hFigAbs = figure('Name','Emissions – Interactive', ...
              'Color','w','Units','pixels','Position',[150 150 figW figH]);

ctrlW = 220;
mainAbs = uipanel('Parent',hFigAbs,'Units','pixels','Position',[ctrlW 1 figW-ctrlW figH],'BorderType','none');
ctrlAbs = uipanel('Parent',hFigAbs,'Units','pixels','Position',[1 1 ctrlW figH],'BorderType','etchedin','Title','Controls');

% בקרי תרחיש + שנה
uicontrol(ctrlAbs,'Style','text','String','Scenario:','Units','pixels','Position',[10 figH-60 90 20],'HorizontalAlignment','left');
popScenAbs = uicontrol(ctrlAbs,'Style','popupmenu','String',scenarios,'Units','pixels','Position',[100 figH-62 110 24],'Value',1);

uicontrol(ctrlAbs,'Style','text','String','Year:','Units','pixels','Position',[10 figH-100 90 20],'HorizontalAlignment','left');
popYearAbs = uicontrol(ctrlAbs,'Style','slider','Min',1,'Max',nYears,'Value',defaultYear, ...
    'SliderStep',[1/max(nYears-1,1) 5/max(nYears-1,1)],'Units','pixels','Position',[10 figH-125 200 20]);
lblYearAbs = uicontrol(ctrlAbs,'Style','text','String',sprintf('Selected: %s',yearLabels{defaultYear}), ...
    'Units','pixels','Position',[10 figH-150 200 20],'HorizontalAlignment','left');

% פריסת גרפים
tlAbs = tiledlayout(mainAbs,1,nCities,'TileSpacing','compact','Padding','compact');
try
    title(tlAbs,'Emissions by Sectors – Base vs Selected Year (Absolute)');
catch
    sgtitle('Emissions by Sectors – Base vs Selected Year (Absolute)');
end

% סדר קטגוריות גלובלי (כמו ב-per capita)
sectorOrderAbs = strings(0,1);
tbl0 = getScenarioTable(cities{1}, scenarios{1});
names = string(tbl0.Properties.RowNames(1:11));
for nm = names.'
    if ~any(sectorOrderAbs == nm)
        sectorOrderAbs(end+1,1) = nm; %#ok<AGROW>
    end
end
nSectorsAbs = numel(sectorOrderAbs);

% אתחול צירים וברים
axListAbs  = gobjects(1,nCities);
barListAbs = cell(1,nCities);
for c = 1:nCities
    axListAbs(c) = nexttile(tlAbs);
    cats = categorical({'Base','Selected'});
    zz = zeros(2,nSectorsAbs);
    b = bar(axListAbs(c), cats, zz, 'stacked', 'BarWidth', 0.9);
    for k = 1:nSectorsAbs
        set(b(k),'FaceColor',colorsEmFixed(k,:));
    end
    grid(axListAbs(c),'on'); axListAbs(c).Box='off'; axListAbs(c).LineWidth=1; axListAbs(c).FontSize=10;
    title(axListAbs(c), cityNames{c}, 'FontSize', 13, 'FontWeight', 'bold');
    ylabel(axListAbs(c), 'MtCO2Eq');
    barListAbs{c} = b;
end

% מקרא יחיד
legend(axListAbs(1), barListAbs{1}, cellstr(sectorOrderAbs), ...
    'NumColumns', min(4,nSectorsAbs), 'Location','southoutside','FontSize',10);

% === קריאה ראשונית + קאלבקים ===
updateAllAbs(cities, scenarios, baseCol, yearLabels, popScenAbs, popYearAbs, lblYearAbs, barListAbs, axListAbs, sectorOrderAbs, nSectorsAbs);
popScenAbs.Callback = @(~,~) updateAllAbs(cities, scenarios, baseCol, yearLabels, popScenAbs, popYearAbs, lblYearAbs, barListAbs, axListAbs, sectorOrderAbs, nSectorsAbs);
popYearAbs.Callback = @(src,~) sliderCallbackAbs(src, cities, scenarios, baseCol, yearLabels, popScenAbs, popYearAbs, lblYearAbs, barListAbs, axListAbs, sectorOrderAbs, nSectorsAbs);

%% -------- פונקציות מקומיות --------
function sliderCallbackAbs(src, cities, scenarios, baseCol, yearLabels, popScenAbs, popYearAbs, lblYearAbs, barListAbs, axListAbs, sectorOrderAbs, nSectorsAbs)
    set(lblYearAbs,'String',sprintf('Selected: %s',yearLabels{round(src.Value)}));
    updateAllAbs(cities, scenarios, baseCol, yearLabels, popScenAbs, popYearAbs, lblYearAbs, barListAbs, axListAbs, sectorOrderAbs, nSectorsAbs);
end

function updateAllAbs(cities, scenarios, baseCol, yearLabels, popScenAbs, popYearAbs, lblYearAbs, barListAbs, axListAbs, sectorOrderAbs, nSectorsAbs)
    scen   = scenarios{get(popScenAbs,'Value')};
    selCol = round(get(popYearAbs,'Value'));
    set(lblYearAbs,'String',sprintf('Selected: %s',yearLabels{selCol}));

    % מקסימום משותף (גובה סטאק)
    ymaxStack = 0;
    Ycells  = cell(1,numel(cities));

    for cc = 1:numel(cities)
        tbl = getScenarioTable(cities{cc}, scen);

        % יישור לפי sectorOrderAbs
        have = ismember(sectorOrderAbs, string(tbl.Properties.RowNames));
        if ~all(have)
            missing = sectorOrderAbs(~have);
            Z = array2table(zeros(numel(missing), width(tbl)), ...
                'RowNames', cellstr(missing), ...
                'VariableNames', tbl.Properties.VariableNames);
            tbl = [tbl; Z]; %#ok<AGROW>
        end
        tbl = tbl(cellstr(sectorOrderAbs), :);

        % MtCO2e: nSectors×2 (Base, Selected)
        yAbs = [tbl{1:nSectorsAbs, baseCol}, tbl{1:nSectorsAbs, selCol}];
        Ycells{cc} = yAbs;
        ymaxStack = max(ymaxStack, max(sum(yAbs,1)));
    end

    ylimVals = [0, ceil(ymaxStack*1.10)];

    % ציור לכל עיר
    for cc = 1:numel(cities)
        yAbs = Ycells{cc};
        b    = barListAbs{cc};
        for k = 1:nSectorsAbs
            b(k).YData = yAbs(k, :).';
        end
        ylim(axListAbs(cc), ylimVals);

        % הסרת תוויות קודמות
        delete(findall(axListAbs(cc),'Type','text','Tag','BarLabel'));

        % הוספת תוויות חדשות
        for k = 1:nSectorsAbs
            yVals = b(k).YData;
            for x = 1:numel(yVals)
                if yVals(x) > 0
                    cumulative = sum(cellfun(@(bb) bb.YData(x), num2cell(b(1:k-1))));
                    centerY    = cumulative + yVals(x)/2;
                    text(axListAbs(cc), x, centerY, ...
                        sprintf('%.2f', yVals(x)), ...
                        'HorizontalAlignment','center', ...
                        'VerticalAlignment','middle', ...
                        'Color','w','FontSize',12,'FontWeight','bold', ...
                        'Tag','BarLabel','BackgroundColor','k','Margin',1);
                end
            end
        end
    end
end



%%-------------------------------Per Capita---------------------------------
%% --------- 2b) Emissions per Capita by Sectors (Interactive) ---------
% יחידות: tCO2e לנפש. Base מול שנה נבחרת. התאמת אוכלוסייה לפי RDB של התרחיש.
if nCities < 1, error('לא נמצאו ערים ב-AllCities.'); end
% פלטת צבעים קבועה ל-11 קטגוריות (ניתן להחליף כרצונך)
colorsEmFixed = [
    0.72, 0.27, 1.00;
    0.49, 0.18, 0.56;
    0.93, 0.69, 0.13;
    0.51, 0.37, 0.01;
    0.29, 0.89, 0.69;
    0.47, 0.67, 0.19;
    0.85, 0.33, 0.10;
    0.64, 0.08, 0.18;
    0.30, 0.75, 0.93;
    0.00, 0.45, 0.74;
    0.00, 1.00, 0.74;
];

% שמות שנים מהתוצאות (עמודות)
yearLabels = cities{1}.TotalResults.Properties.VariableNames;  % {'2019','2020',...}
nYears     = numel(yearLabels);

% חלון + פאנלים
figW = max(450*nCities, 1200);
figH = 600;
hFig = figure('Name','Per Capita Emissions – Interactive', ...
              'Color','w','Units','pixels','Position',[100 100 figW figH]);

ctrlW = 220;
main = uipanel('Parent',hFig,'Units','pixels','Position',[ctrlW 1 figW-ctrlW figH],'BorderType','none');
ctrl = uipanel('Parent',hFig,'Units','pixels','Position',[1 1 ctrlW figH],'BorderType','etchedin','Title','Controls');

% בקרי תרחיש + שנה
uicontrol(ctrl,'Style','text','String','Scenario:','Units','pixels','Position',[10 figH-60 90 20],'HorizontalAlignment','left');
popScen = uicontrol(ctrl,'Style','popupmenu','String',scenarios,'Units','pixels','Position',[100 figH-62 110 24],'Value',1);

uicontrol(ctrl,'Style','text','String','Year:','Units','pixels','Position',[10 figH-100 90 20],'HorizontalAlignment','left');
popYear = uicontrol(ctrl,'Style','slider','Min',1,'Max',nYears,'Value',targetCol, ...
    'SliderStep',[1/max(nYears-1,1) 5/max(nYears-1,1)],'Units','pixels','Position',[10 figH-125 200 20]);
lblYear = uicontrol(ctrl,'Style','text','String',sprintf('Selected: %s',yearLabels{targetCol}), ...
    'Units','pixels','Position',[10 figH-150 200 20],'HorizontalAlignment','left');

% פריסת גרפים – שורה אחת לכל הערים
tl = tiledlayout(main,1,nCities,'TileSpacing','compact','Padding','compact');
try
    title(tl,'Per Capita Emissions by Sectors – Base vs Selected Year');
catch
    sgtitle('Per Capita Emissions by Sectors – Base vs Selected Year');
end

% סדר קטגוריות גלובלי עקבי
sectorOrder = strings(0,1);
for c = 1:nCities
    tbl0 = getScenarioTable(cities{c}, scenarios{1}); % רק לשמות
    names = string(tbl0.Properties.RowNames(1:11));
    for nm = names.'
        if ~any(sectorOrder == nm)
            sectorOrder(end+1,1) = nm; %#ok<AGROW>
        end
    end
end
nSectors = numel(sectorOrder);
if size(colorsEmFixed,1) < nSectors
    colorsEmFixed = [colorsEmFixed; lines(nSectors-size(colorsEmFixed,1))]; %#ok<AGROW>
end

% אתחול צירים וברים
axList  = gobjects(1,nCities);
barList = cell(1,nCities);
for c = 1:nCities
    axList(c) = nexttile(tl);
    cats = categorical({'Base','Selected'});
    zz = zeros(2,nSectors);
    b = bar(axList(c), cats, zz, 'stacked', 'BarWidth', 0.9);
    for k = 1:nSectors
        set(b(k),'FaceColor',colorsEmFixed(k,:));
    end
    grid(axList(c),'on'); axList(c).Box='off'; axList(c).LineWidth=1; axList(c).FontSize=10;
    title(axList(c), cityNames{c}, 'FontSize', 13, 'FontWeight', 'bold');
    ylabel(axList(c), 'tCO2e per capita');
    barList{c} = b;
end

% מקרא יחיד
legend(axList(1), barList{1}, cellstr(sectorOrder), ...
    'NumColumns', min(4,nSectors), 'Location','southoutside','FontSize',10);

% === קריאה ראשונית + קאלבקים עם כל המשתנים ===
updateAll(cities, cityNames, scenarios, baseCol, targetCol, yearLabels, popScen, popYear, lblYear, barList, axList, sectorOrder, nSectors);
popScen.Callback = @(~,~) updateAll(cities, cityNames, scenarios, baseCol, targetCol, yearLabels, popScen, popYear, lblYear, barList, axList, sectorOrder, nSectors);
popYear.Callback = @(src,~) sliderCallback(src, cities, cityNames, scenarios, baseCol, targetCol, yearLabels, popScen, popYear, lblYear, barList, axList, sectorOrder, nSectors);

%% -------- פונקציות מקומיות (עובדות גם בסקריפט) --------
function sliderCallback(src, cities, cityNames, scenarios, baseCol, targetCol, yearLabels, popScen, popYear, lblYear, barList, axList, sectorOrder, nSectors)
    set(lblYear,'String',sprintf('Selected: %s',yearLabels{round(src.Value)}));
    updateAll(cities, cityNames, scenarios, baseCol, targetCol, yearLabels, popScen, popYear, lblYear, barList, axList, sectorOrder, nSectors);
end

function updateAll(cities, cityNames, scenarios, baseCol, targetCol, yearLabels, popScen, popYear, lblYear, barList, axList, sectorOrder, nSectors)
    scen   = scenarios{get(popScen,'Value')};
    selCol = round(get(popYear,'Value'));  % עמודת שנה נבחרת
    set(lblYear,'String',sprintf('Selected: %s',yearLabels{selCol}));

    % מקסימום משותף (גובה סטאק) על בסיס tCO2e לנפש
    ymaxStack = 0;
    YpcCells  = cell(1,numel(cities));

    for cc = 1:numel(cities)
        % טבלת סקטורים לפי תרחיש
        tbl = getScenarioTable(cities{cc}, scen);

        % השלמה ויישור לפי sectorOrder
        have = ismember(sectorOrder, string(tbl.Properties.RowNames));
        if ~all(have)
            missing = sectorOrder(~have);
            Z = array2table(zeros(numel(missing), width(tbl)), ...
                'RowNames', cellstr(missing), ...
                'VariableNames', tbl.Properties.VariableNames);
            tbl = [tbl; Z]; %#ok<AGROW>
        end
        tbl = tbl(cellstr(sectorOrder), :);

        % MtCO2e: nSectors×2 (Base, Selected)
        yMt = [tbl{1:nSectors, baseCol}, tbl{1:nSectors, selCol}];

        % אוכלוסייה (מיליונים) לפי RDB של התרחיש
        popBaseM = getPopMillionsByCol(cities{cc}, baseCol, scen, yearLabels);
        popSelM  = getPopMillionsByCol(cities{cc}, selCol,  scen, yearLabels);

        % t לנפש = Mt / מיליון נפש
        yPerCap = [ yMt(:,1)./max(popBaseM,eps),  yMt(:,2)./max(popSelM,eps) ];

        YpcCells{cc} = yPerCap;
        ymaxStack = max(ymaxStack, max(sum(yPerCap,1)));
    end

    ylimVals = [0, ceil(ymaxStack * 1.10)];

    % ציור לכל עיר
    for cc = 1:numel(cities)
        ypc = YpcCells{cc};   % nSectors×2
        b   = barList{cc};
        for k = 1:nSectors
            b(k).YData = ypc(k, :).';
        end
        ylim(axList(cc), ylimVals);

        % הסרת תוויות ישנות (אם יש)
        delete(findall(axList(cc),'Type','text','Tag','BarLabel'));
        
        % הוספת תוויות חדשות
        for k = 1:nSectors
            yVals = b(k).YData;  % ערכים של הסקטור הזה (Base ו-Selected)
            for x = 1:numel(yVals)
                if yVals(x) > 0
                    vals = [b(1:k).YData];   % זה מחזיר וקטור עם הערכים עד bar k
                    cumulative = sum(cellfun(@(bb) bb.YData(x), num2cell(b(1:k-1)))); % סכום השכבות הקודמות
                    centerY    = cumulative + yVals(x)/2;
                    text(axList(cc), x, centerY, ...
                        sprintf('%.2f', yVals(x)), ...
                        'HorizontalAlignment','center', ...
                        'VerticalAlignment','middle', ...
                        'Color','w', ...          % טקסט לבן
                        'FontSize',12, ...        % גודל גדול יותר
                        'FontWeight','bold', ...  % כתב מודגש
                        'Tag','BarLabel', ...
                        'BackgroundColor','k', ... % רקע שחור מאחורי הטקסט (שיבלט)
                        'Margin',1);              % קצת ריווח פנימי

                end
            end
        end

    end
end

%% -------- פונקציות עזר --------
function tbl = getScenarioTable(C, scen)
    switch scen
        case 'BAU',      tbl = C.BAU_RDB.TotalEmission1;
        case 'Moderate', tbl = C.Moderate_RDB.TotalEmission2;
        case 'Advanced', tbl = C.Advanced_RDB.TotalEmission3;
        otherwise, error('Unknown scenario: %s', scen);
    end
end

function RDB = getScenarioRDB(C, scen)
    switch scen
        case 'BAU',      RDB = C.BAU_RDB;
        case 'Moderate', RDB = C.Moderate_RDB;
        case 'Advanced', RDB = C.Advanced_RDB;
        otherwise, error('Unknown scenario: %s', scen);
    end
end

function popM = getPopMillionsByCol(C, colIdx, scen, yearLabels)
    RDB = getScenarioRDB(C, scen);
    P   = RDB.population;

    yearsRow = P{2,:};
    popsRow  = P{3,:};

    if iscell(yearsRow), yearsRow = cellfun(@str2double, yearsRow); end
    if iscell(popsRow),  popsRow  = cellfun(@str2double,  popsRow); end

    if colIdx <= numel(popsRow) && ~isnan(popsRow(colIdx)) && ~isempty(popsRow(colIdx))
        popM = popsRow(colIdx);
        return;
    end
    yr = str2double(yearLabels{colIdx});
    ix = find(yearsRow == yr, 1, 'first');
    if ~isempty(ix)
        popM = popsRow(ix);
    else
        error('Year %s (col %d) not found in population table.', yearLabels{colIdx}, colIdx);
    end
end















%% --------- 4) גרפי פיזור: פליטה כוללת לאורך השנים ---------
years = cities{1}.TotalResults.Properties.VariableNames;  % {'2019','2020',...,'2050'}

rows.Emission_Total = [7 8 9];  % BAU / Moderate / Advanced
colors = lines(nCities);        % צבע שונה לכל עיר

for s = 1:numel(scenarios)
    scen = scenarios{s};
    r = rows.Emission_Total(s);

    figure('Name',['Emission Total – ',scen],'Color','w');
    hold on;
    for c = 1:nCities
        TR = cities{c}.TotalResults;
        yVals = TR{r, :};     % כל השנים
        xVals = 1:numel(yVals);
        scatter(xVals, yVals, 30, 'MarkerEdgeColor',colors(c,:), ...
                'DisplayName', cityNames{c});
        plot(xVals, yVals, '-','Color',colors(c,:), 'LineWidth',1.5);
    end
    hold off;

    set(gca,'XTick',1:numel(years),'XTickLabel',years,'XTickLabelRotation',45);
    xlabel('Year'); ylabel('Emission Total (MtCO2Eq)');
    title(['Total Emissions over Time – ',scen]);
    legend('Location','bestoutside');
    grid on; box off;
end


%% --------- 3) יצירת טבלאות סיכום ---------
summaryRows = {};
for c = 1:nCities
    for s = 1:numel(scenarios)
        for m = 1:numel(metrics)
            summaryRows{end+1,1} = cityNames{c};
            summaryRows{end,2}   = scenarios{s};
            summaryRows{end,3}   = metrics{m};
            summaryRows{end,4}   = dataTotals(c,s,m,1); % Base
            summaryRows{end,5}   = dataTotals(c,s,m,2); % Target
        end
    end
end

SummaryTable = cell2table(summaryRows, ...
    'VariableNames', {'City','Scenario','Metric','BaseValue','TargetValue'});
writetable(SummaryTable,'Results_Plots\\ResultsSummary.xlsx');


%% --------- 3b) טבלה בפורמט Wide ---------
wideRows = {};
wideVals = [];
for s = 1:numel(scenarios)
    for m = 1:numel(metrics)
        wideRows{end+1,1} = scenarios{s};
        wideRows{end,2}   = metrics{m};
        rowVals = [];
        for c = 1:nCities
            rowVals = [rowVals, dataTotals(c,s,m,1), dataTotals(c,s,m,2)];
        end
        wideVals = [wideVals; rowVals];
    end
end

safeCityNames = regexprep(cityNames,'[^a-zA-Z0-9]','_'); 
colNames = {};
for c = 1:nCities
    colNames{end+1} = [safeCityNames{c}, '_Base'];
    colNames{end+1} = [safeCityNames{c}, '_Target'];
end

SummaryWide = cell2table(wideRows, 'VariableNames', {'Scenario','Metric'});
SummaryWide = [SummaryWide array2table(wideVals, 'VariableNames', colNames)];
writetable(SummaryWide,'Results_Plots\\ResultsSummary_Wide.xlsx');


%% --------- 3c) טבלת הפרשים בין ערים ---------
diffVals = [];
diffNames = {};
for i = 1:nCities-1
    for j = i+1:nCities
        for valType = ["Base","Target"]
            colA = [safeCityNames{i}, '_', char(valType)];
            colB = [safeCityNames{j}, '_', char(valType)];
            diffNames{end+1} = [safeCityNames{i}, '_minus_', safeCityNames{j}, '_', char(valType)];
            diffVals = [diffVals, SummaryWide.(colA) - SummaryWide.(colB)];
        end
    end
end

SummaryDiffs = [SummaryWide(:,1:2), array2table(diffVals,'VariableNames',diffNames)];
writetable(SummaryDiffs,'Results_Plots\\ResultsSummary_Diffs.xlsx');
