%% =====================================================================
%  Plot_BaseSnapshot_AllCities.m
%  Base Snapshot: Absolute and Per Capita Emissions for 2019 (BAU)
%  Fixed city order and enlarged font settings
%% =====================================================================
addpath('helpers');

% 1. Get the categorical array (this contains the names and the fixed order)
catOrder = getCityCategorical(AllCities); 

% 2. Convert to a cell array of strings for the data collection loop
% This allows you to use cityName as a key for the AllCities struct
customCityOrder = cellstr(catOrder);

nCities  = numel(customCityOrder);
scenario = 'BAU';    % Base scenario
baseCol  = 1;        % Year 2019

% --- Font Settings ---
fs_axis   = 14; 
fs_label  = 16; 
fs_title  = 20; 
fs_data   = 13; 

%% --- Color map for each city ---
cityColors = lines(nCities); 

%% --- Collect data for each city based on defined order ---
AbsValues = zeros(nCities,1);
PCValues  = zeros(nCities,1);

for i = 1:nCities
    cityName = customCityOrder{i};
    if isfield(AllCities, cityName)
        C = AllCities.(cityName);
        tbl = getScenarioTable(C, scenario);
        
        % Total emissions (the last row in the table)
        totalRowName = tbl.Properties.RowNames{end};
        AbsValues(i) = tbl{totalRowName, baseCol};
        
        % Population in millions
        pop = getPopMillionsByCol(C, baseCol, scenario, tbl.Properties.VariableNames);
        PCValues(i) = AbsValues(i) ./ max(pop, eps);
    else
        warning('City %s was not found in the data structure!', cityName);
    end
end

%% --- Create figure window ---
fig = figure('Name','Base Snapshot – 2019 BAU', ...
             'Color','w','Units','pixels', ...
             'Position',[200 150 1300 650]);
tl = tiledlayout(fig, 1, 2, 'TileSpacing','loose','Padding','compact');

% Create categorical axis that maintains the specified order
%catCities = categorical(customCityOrder, customCityOrder, 'Ordinal', true);

%% =====================================================================
%  Left Plot: Absolute Emissions
%% =====================================================================
axAbs = nexttile(tl);
bAbs = bar(axAbs, catOrder, AbsValues, 'BarWidth', 0.7);
bAbs.FaceColor = 'flat'; 
for i = 1:nCities
    bAbs.CData(i,:) = cityColors(i,:);
end

% --- Add value labels ---
xtips1 = bAbs.XEndPoints;
ytips1 = bAbs.YEndPoints;
for i = 1:nCities
    text(axAbs, xtips1(i), ytips1(i), num2str(AbsValues(i), '%.1f'), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
        'FontSize', fs_data, 'FontWeight', 'bold');
end

ylabel(axAbs, 'MtCO2eq', 'FontSize', fs_label);
title(axAbs, 'Total Emissions (2019 BAU)', 'FontSize', fs_title);
grid(axAbs, 'on'); 
axAbs.FontSize = fs_axis;
set(axAbs, 'XTickLabelRotation', 45);

%% =====================================================================
%  Right Plot: Per Capita Emissions
%% =====================================================================
axPC = nexttile(tl);
bPC = bar(axPC, catOrder, PCValues, 'BarWidth', 0.7);
bPC.FaceColor = 'flat';
for i = 1:nCities
    bPC.CData(i,:) = cityColors(i,:);
end

% --- Add value labels ---
xtips2 = bPC.XEndPoints;
ytips2 = bPC.YEndPoints;
for i = 1:nCities
    text(axPC, xtips2(i), ytips2(i), num2str(PCValues(i), '%.2f'), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
        'FontSize', fs_data, 'FontWeight', 'bold');
end

ylabel(axPC, 'tCO2e per capita', 'FontSize', fs_label);
title(axPC, 'Per Capita Emissions (2019 BAU)', 'FontSize', fs_title);
grid(axPC, 'on'); 
axPC.FontSize = fs_axis;
set(axPC, 'XTickLabelRotation', 45);

%% =====================================================================
%  Top title for the entire layout
%% =====================================================================
t = title(tl, 'Base Snapshot – Emissions Summary (2019, BAU)');
t.FontSize = fs_title + 2;
t.FontWeight = 'bold';

%% =====================================================================
%  Save Figures
%% =====================================================================
outputDir = 'C:\Users\צור\Documents\MATLAB\NewVersionCities_Partial\Results_Plots\Plot_BaseSnapshot';
if ~exist(outputDir, 'dir'), mkdir(outputDir); end

saveas(fig, fullfile(outputDir, 'BaseSnapshot_AllCities_Ordered.png'));
saveas(fig, fullfile(outputDir, 'BaseSnapshot_AllCities_Ordered.fig'));

disp('✔ Finished generating the ordered base snapshot plots.');