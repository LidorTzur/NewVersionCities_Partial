%% =====================================================================
% Plot_Emissions_PerCapita_SingleCity.m
% גרף אינטראקטיבי: פליטות לנפש לפי סקטור – עיר בודדת
%% =====================================================================

addpath('helpers');

% 1. Get city names in the correct logical order
% (The function now handles the default order internally)
catOrder = getCityCategorical(AllCities); 
cityNames = cellstr(catOrder); 
nCities = numel(cityNames);

% 2. Rebuild the 'cities' cell array to match the NEW order
% This ensures that popCity.Value (1, 2, 3...) maps to the correct data
cities = cell(nCities, 1);
for i = 1:nCities
    cityName = cityNames{i};
    cities{i} = AllCities.(cityName);
end

scenarios = {'BAU','Moderate','Advanced'};
baseCol   = 1;

TargetYear = BaseYear + Years - 1;

yearLabels = cities{1}.TotalResults.Properties.VariableNames;
nYears     = numel(yearLabels);

defaultYear = find(strcmp(yearLabels, num2str(TargetYear)));
if isempty(defaultYear)
    defaultYear = Years;
end

%% --- יצירת סדר גלובלי של סקטורים ---
sectorOrder = string([]);

for c = 1:nCities
    tbl = getScenarioTable(cities{c}, 'BAU');
    nRaw = height(tbl) - 1;
    scnames = string(tbl.Properties.RowNames(1:nRaw));

    for nm = scnames.'
        if ~ismember(nm, sectorOrder)
            sectorOrder(end+1) = nm;
        end
    end
end

nSectors = numel(sectorOrder);
colors   = getSectorColors(nSectors);

%% --- GUI ---
fig = figure('Name','Interactive Per Capita – Single City', ...
             'Color','w','Units','pixels', ...
             'Position',[200 150 1000 600]);

ctrlW = 220;

mainPanel = uipanel('Parent',fig,'Units','pixels',...
                    'Position',[ctrlW 1 1000-ctrlW 600],...
                    'BorderType','none');

ctrlPanel = uipanel('Parent',fig,'Units','pixels',...
                    'Position',[1 1 ctrlW 600],...
                    'BorderType','etchedin','Title','Controls','FontSize',11);

%% --- בקרי בחירה ---

uicontrol(ctrlPanel,'Style','text','String','City:',...
    'Units','pixels','Position',[10 560 80 20],'HorizontalAlignment','left');
popCity = uicontrol(ctrlPanel,'Style','popupmenu',...
    'String',cityNames,'Units','pixels','Position',[100 560 110 25],'Value',1);

uicontrol(ctrlPanel,'Style','text','String','Scenario:',...
    'Units','pixels','Position',[10 520 80 20],'HorizontalAlignment','left');
popScen = uicontrol(ctrlPanel,'Style','popupmenu',...
    'String',scenarios,'Units','pixels','Position',[100 520 110 25],'Value',1);

uicontrol(ctrlPanel,'Style','text','String','Year:',...
    'Units','pixels','Position',[10 480 80 20],'HorizontalAlignment','left');

popYear = uicontrol(ctrlPanel,'Style','slider','Min',1,'Max',nYears,...
    'Value',defaultYear,...
    'SliderStep',[1/(nYears-1) 5/(nYears-1)],...
    'Units','pixels','Position',[10 460 200 20]);

lblYear = uicontrol(ctrlPanel,'Style','text',...
    'String',sprintf('Selected: %s', yearLabels{defaultYear}),...
    'Units','pixels','Position',[10 440 200 20],...
    'HorizontalAlignment','left');


%% --- גרף Stack ---
tl = tiledlayout(mainPanel, 1, 1, 'TileSpacing','compact','Padding','compact');

ax = nexttile(tl);

cats = categorical({'Base','Selected'});
zz   = zeros(2,nSectors);

b = bar(ax, cats, zz, 'stacked', 'BarWidth',0.9);

for k = 1:nSectors
    set(b(k),'FaceColor',colors(k,:));
end

grid(ax,'on');
ax.Box = 'off';
ylabel(ax,'tCO2e per capita');

legend(ax, cellstr(sectorOrder), ...
    'NumColumns', min(4,nSectors), 'Location','southoutside');

%% --- הפעלה ראשונית ---
updatePlot(popCity, popScen, popYear, lblYear, ...
           cities, cityNames, scenarios, sectorOrder, ...
           baseCol, yearLabels, ax, b);

%% --- Callbacks ---
popCity.Callback = @(~,~) updatePlot(popCity, popScen, popYear, lblYear, ...
           cities, cityNames, scenarios, sectorOrder, ...
           baseCol, yearLabels, ax, b);

popScen.Callback = @(~,~) updatePlot(popCity, popScen, popYear, lblYear, ...
           cities, cityNames, scenarios, sectorOrder, ...
           baseCol, yearLabels, ax, b);

popYear.Callback = @(src,~) sliderUpdate(src, lblYear, yearLabels, ...
           popCity, popScen, popYear, ...
           cities, cityNames, scenarios, sectorOrder, ...
           baseCol, yearLabels, ax, b);

%% =====================================================================
%%                       פונקציות פנימיות — מתוקנות
%% =====================================================================

function sliderUpdate(src, lblYear, yearLabels, ...
           popCity, popScen, popYear, ...
           cities, cityNames, scenarios, sectorOrder, ...
           baseCol, yearLabels2, ax, b)

    lblYear.String = sprintf('Selected: %s', yearLabels{round(src.Value)});

    updatePlot(popCity, popScen, popYear, lblYear, ...
           cities, cityNames, scenarios, sectorOrder, ...
           baseCol, yearLabels2, ax, b);
end


function updatePlot(popCity, popScen, popYear, lblYear, ...
                    cities, cityNames, scenarios, sectorOrder, ...
                    baseCol, yearLabels, ax, b)

    cIdx  = popCity.Value;
    scen  = scenarios{popScen.Value};
    selCol = round(popYear.Value);

    lblYear.String = sprintf('Selected: %s', yearLabels{selCol});

    C = cities{cIdx};
    tbl = getScenarioTable(C, scen);

    % --- שליפה לפי סקטורים ---
    yAbs = extractSectorMatrix(tbl, sectorOrder, baseCol, selCol);

    popBase = getPopMillionsByCol(C, baseCol, scen, yearLabels);
    popSel  = getPopMillionsByCol(C, selCol,  scen, yearLabels);

    yPC = [ yAbs(:,1)./max(popBase,eps), ...
            yAbs(:,2)./max(popSel, eps) ];

    updateStackedBar(ax, b, yPC, '%.2f');

    title(ax, cityNames{cIdx}, 'FontSize', 13, 'FontWeight','bold');
end
