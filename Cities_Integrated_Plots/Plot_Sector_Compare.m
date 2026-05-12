%% =====================================================================
% Plot_Sector_Compare_AllCities.m
% השוואת ערים לפי סקטור – אבסולוטי + לנפש
% לכל סקטור נפתח חלון גרפים נפרד
%% =====================================================================

addpath('helpers');

%% --- Configuration & Ordered Data ---
% 1. Get city names in the logical categorical order
catOrder = getCityCategorical(AllCities); 
cityNames = cellstr(catOrder); % Convert to cell array of strings
nCities = numel(cityNames);

% 2. Rebuild the 'cities' cell array to match the NEW order
% This ensures cities{1} is 'Tlv', cities{2} is 'RishonLeZion', etc.
cities = cell(nCities, 1);
for i = 1:nCities
    cityName = cityNames{i};
    cities{i} = AllCities.(cityName);
end

scenarios = {'BAU','Moderate','Advanced'};

baseCol   = 1;
targetCol = Years;

yearLabels = cities{1}.TotalResults.Properties.VariableNames;
nYears     = numel(yearLabels);

TargetYear = BaseYear + Years - 1;

defaultYear = find(strcmp(yearLabels, num2str(TargetYear)));
if isempty(defaultYear)
    defaultYear = Years;
end

%% --- צבע ייחודי לכל עיר ---
cityColors = lines(nCities);

%% --- יצירת סדר גלובלי של סקטורים ---
tblBAU = getScenarioTable(cities{1}, 'BAU');
nRaw   = height(tblBAU) - 1;
sectorOrder = string(tblBAU.Properties.RowNames(1:nRaw));
nSectors = numel(sectorOrder);

%% --- לולאה על סקטורים ---
for sIdx = 1:nSectors

    sectorName = sectorOrder{sIdx};

    fig = figure('Name', ['Sector: ' sectorName], ...
                 'Color','w','Units','pixels','Position',[150 120 1250 600]);

    ctrlW = 220;

    mainPanel = uipanel('Parent',fig,'Units','pixels',...
                        'Position',[ctrlW 1 1250-ctrlW 600],...
                        'BorderType','none');

    ctrlPanel = uipanel('Parent',fig,'Units','pixels',...
                        'Position',[1 1 ctrlW 600],...
                        'BorderType','etchedin',...
                        'Title','Controls','FontSize',11);

    %% --- בקרים ---
    uicontrol(ctrlPanel,'Style','text','String','Scenario:',...
        'Units','pixels','Position',[10 560 90 20],'HorizontalAlignment','left');

    popScen = uicontrol(ctrlPanel,'Style','popupmenu',...
        'String',scenarios,'Units','pixels','Position',[110 560 100 25],'Value',1);

    uicontrol(ctrlPanel,'Style','text','String','Year:',...
        'Units','pixels','Position',[10 520 90 20],'HorizontalAlignment','left');

    popYear = uicontrol(ctrlPanel,'Style','slider','Min',1,'Max',nYears,...
        'Value',defaultYear,'SliderStep',[1/(nYears-1) 5/(nYears-1)],...
        'Units','pixels','Position',[10 500 200 20]);

    lblYear = uicontrol(ctrlPanel,'Style','text',...
        'String',sprintf('Selected: %s', yearLabels{defaultYear}),...
        'Units','pixels','Position',[10 480 200 20],...
        'HorizontalAlignment','left');

    %% --- פריסת הגרפים ---
    tl = tiledlayout(mainPanel, 1, 2, 'TileSpacing','compact', 'Padding','compact');

    try
        sgtitle(fig, ['Sector: ' sectorName ' – Base vs Selected Year']);
    catch
        title(tl, ['Sector: ' sectorName ' – Base vs Selected Year']);
    end

    %% --- גרף אבסולוטי ---
    axAbs = nexttile(tl);
    cats = categorical(cityNames);
    zz = zeros(nCities,2);

    bAbs = bar(axAbs, cats, zz, 'grouped', 'BarWidth',0.7);
    bAbs(1).FaceColor = 'flat';
    bAbs(2).FaceColor = 'flat';
    bAbs(1).CData = cityColors;
    bAbs(2).CData = cityColors;

    ylabel(axAbs,'MtCO2eq');
    grid(axAbs,'on'); axAbs.Box='off';
    set(axAbs,'XTickLabelRotation',45);

    %% --- גרף לנפש ---
    axPC = nexttile(tl);
    bPC = bar(axPC, cats, zz, 'grouped', 'BarWidth',0.7);
    bPC(1).FaceColor = 'flat';
    bPC(2).FaceColor = 'flat';
    bPC(1).CData = cityColors;
    bPC(2).CData = cityColors;

    ylabel(axPC,'tCO2e per capita');
    grid(axPC,'on'); axPC.Box='off';
    set(axPC,'XTickLabelRotation',45);

    %% --- קאלבקים ---
    popScen.Callback = @(~,~) updateSectorPlot(...
        cities, scenarios, sectorName, baseCol, yearLabels, ...
        popScen, popYear, bAbs, bPC, axAbs, axPC, nCities, cityColors);

    popYear.Callback = @(src,~) sliderUpdate(...
        src, lblYear, yearLabels, cities, scenarios, sectorName, baseCol, ...
        popScen, popYear, bAbs, bPC, axAbs, axPC, nCities, cityColors);

    %% --- הפעלה ראשונית ---
    updateSectorPlot(...
        cities, scenarios, sectorName, baseCol, yearLabels, ...
        popScen, popYear, bAbs, bPC, axAbs, axPC, nCities, cityColors);

end

disp('✔ סיימתי להפיק את סקריפט Sector Compare לכל הערים.');

%% =====================================================================
% פונקציות מקומיות
%% =====================================================================

function sliderUpdate(src, lblYear, yearLabels, ...
    cities, scenarios, sectorName, baseCol, ...
    popScen, popYear, bAbs, bPC, axAbs, axPC, nCities, cityColors)

    lblYear.String = sprintf('Selected: %s', yearLabels{round(src.Value)});

    updateSectorPlot(...
        cities, scenarios, sectorName, baseCol, yearLabels, ...
        popScen, popYear, bAbs, bPC, axAbs, axPC, nCities, cityColors);
end

function updateSectorPlot(...
    cities, scenarios, sectorName, baseCol, yearLabels, ...
    popScen, popYear, bAbs, bPC, axAbs, axPC, nCities, cityColors)

    scen   = scenarios{popScen.Value};
    selCol = round(popYear.Value);

    Y_abs = zeros(nCities,2);
    Y_pc  = zeros(nCities,2);

    maxAbs = 0;
    maxPC  = 0;

    for cc = 1:nCities

        tbl = getScenarioTable(cities{cc}, scen);

        if ismember(sectorName, tbl.Properties.RowNames)
            yBase = tbl{sectorName, baseCol};
            ySel  = tbl{sectorName, selCol};
        else
            yBase = 0; ySel = 0;
        end

        Y_abs(cc,:) = [yBase, ySel];

        popBase = getPopMillionsByCol(cities{cc}, baseCol, scen, yearLabels);
        popSel  = getPopMillionsByCol(cities{cc}, selCol,  scen, yearLabels);

        Y_pc(cc,1) = yBase / max(popBase,eps);
        Y_pc(cc,2) = ySel  / max(popSel,eps);

        maxAbs = max(maxAbs, max(Y_abs(cc,:)));
        maxPC  = max(maxPC,  max(Y_pc(cc,:)));
    end

    % ----- עדכון ברים -----
    bAbs(1).YData = Y_abs(:,1);
    bAbs(2).YData = Y_abs(:,2);
    ylim(axAbs,[0 ceil(maxAbs*1.1)]);
    bAbs(1).CData = cityColors;
    bAbs(2).CData = cityColors;

    bPC(1).YData = Y_pc(:,1);
    bPC(2).YData = Y_pc(:,2);
    ylim(axPC,[0 ceil(maxPC*1.1)]);
    bPC(1).CData = cityColors;
    bPC(2).CData = cityColors;

end


%% -------- פונקציות עזר --------
function tbl = getScenarioTable(C, scen)
    switch scen
        case 'BAU',      tbl = C.BAU_RDB.TotalEmission1;
        case 'Moderate', tbl = C.Moderate_RDB.TotalEmission2;
        case 'Advanced', tbl = C.Advanced_RDB.TotalEmission3;
    end
end

function RDB = getScenarioRDB(C, scen)
    switch scen
        case 'BAU',      RDB = C.BAU_RDB;
        case 'Moderate', RDB = C.Moderate_RDB;
        case 'Advanced', RDB = C.Advanced_RDB;
    end
end

function popM = getPopMillionsByCol(C, colIdx, scen, yearLabels)

    RDB = getScenarioRDB(C, scen);
    P   = RDB.population;

    yearsRow = P{2,:};
    popsRow  = P{3,:};

    if iscell(yearsRow), yearsRow = cellfun(@str2double, yearsRow); end
    if iscell(popsRow),  popsRow  = cellfun(@str2double,  popsRow); end

    if colIdx <= numel(popsRow)
        popM = popsRow(colIdx);
        return;
    end

    yr = str2double(yearLabels{colIdx});
    ix = find(yearsRow == yr, 1);

    popM = popsRow(ix);
end
