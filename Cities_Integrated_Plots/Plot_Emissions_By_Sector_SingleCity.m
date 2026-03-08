%% =====================================================================
%  Plot_Emissions_By_Sector_SingleCity.m
%  גרף אינטראקטיבי – פליטות אבסולוטיות לפי סקטור בעיר בודדת
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

TargetYear = BaseYear + Years - 1;

yearLabels = cities{1}.TotalResults.Properties.VariableNames;
nYears     = numel(yearLabels);

defaultYear = find(strcmp(yearLabels, num2str(TargetYear)));
if isempty(defaultYear)
    defaultYear = nYears;
end

%% --- סדר גלובלי של סקטורים ---
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
fig = figure('Name','Interactive Emissions – Single City', ...
             'Color','w','Units','pixels', ...
             'Position',[200 150 1000 600]);

ctrlW = 220;

mainPanel = uipanel('Parent',fig,'Units','pixels',...
                    'Position',[ctrlW 1 1000-ctrlW 600],...
                    'BorderType','none');

ctrlPanel = uipanel('Parent',fig,'Units','pixels',...
                    'Position',[1 1 ctrlW 600],...
                    'BorderType','etchedin','Title','Controls','FontSize',11);


%% --- בקרי GUI ---
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
    'Value',defaultYear,'SliderStep',[1/(nYears-1) 5/(nYears-1)],...
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
    set(b(k), 'FaceColor', colors(k,:));
end

grid(ax,'on');
ax.Box = 'off';
ylabel(ax,'MtCO2Eq');

legend(ax, cellstr(sectorOrder), ...
    'NumColumns', min(4,nSectors),'Location','southoutside');


%% --- הפעלה ראשונית ---
updatePlot(popCity, popScen, popYear, lblYear, ...
           cities, cityNames, scenarios, sectorOrder, ...
           baseCol, yearLabels, ax, b);


%% --- קאלבקים ---
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
%                     פונקציות פנימיות
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

    y = extractSectorMatrix(tbl, sectorOrder, baseCol, selCol);

    updateStackedBar(ax, b, y, '%.2f');

    title(ax, cityNames{cIdx}, 'FontSize', 13, 'FontWeight','bold');
end
