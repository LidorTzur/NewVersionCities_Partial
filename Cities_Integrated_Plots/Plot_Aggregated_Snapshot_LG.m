%% =====================================================================
%  Plot_Aggregated_Snapshot_Final_V2.m
%  Aggregates 10 cities and plots Carbon, Land, and Water (Local vs Global)
%  Fixed: Overlapping titles and total values
%% =====================================================================

% 1. Setup and Directory
catOrder = getCityCategorical(AllCities); 
cityList = cellstr(catOrder);
baseCol  = 1; % Year 2019
outputDir = 'C:\Users\צור\Documents\MATLAB\NewVersionCities_Partial\Results_Plots\Aggregated_Snapshot';
if ~exist(outputDir,'dir'), mkdir(outputDir); end

% 2. Aggregate Data
totalEmissions = [0, 0]; 
totalLand      = [0, 0]; 
totalWater     = [0, 0]; 

for i = 1:numel(cityList)
    cityName = cityList{i};
    if isfield(AllCities, cityName)
        res = AllCities.(cityName).TotalResults;
        totalEmissions = totalEmissions + [res{1, baseCol}, res{4, baseCol}];
        totalLand      = totalLand + [res{10, baseCol}, res{13, baseCol}];
        totalWater     = totalWater + [res{19, baseCol}, res{22, baseCol}];
    end
end

% 3. Create Integrated Figure
fig = figure('Color','w','Position', [100 100 1400 750]);
t = tiledlayout(1, 3, 'TileSpacing', 'loose', 'Padding', 'compact');

% Main Layout Title
title(t, 'Total Environmental Footprint: 10 Cities Aggregate (2019 BAU)', ...
    'FontSize', 22, 'FontWeight', 'bold');

colors = getSectorColors(2); 
metrics = {totalEmissions, totalLand, totalWater};
titles  = {'Carbon Footprint', 'Land Footprint', 'Water Footprint'};
units   = {'MtCO2eq', 'km^2', 'MCM'};

for i = 1:3
    ax = nexttile(t);
    data = metrics{i};
    totalVal = sum(data);
    
    % Stacked Bar
    b = bar(ax, 1, data, 'stacked', 'BarWidth', 0.5);
    b(1).FaceColor = colors(1,:); 
    b(2).FaceColor = colors(2,:);
    
    % Fix Scaling: Set Y-limit to 40% higher than total to avoid overlap with title
    ylim(ax, [0, totalVal * 1.4]);
    
    ylabel(ax, units{i}, 'FontSize', 14, 'FontWeight', 'bold');
    title(ax, titles{i}, 'FontSize', 18);
    set(ax, 'XTick', [], 'FontSize', 12); 
    grid on;
    
    % --- Add Absolute Values Text ---
    % Local Value (centered in segment)
    text(ax, 1, data(1)/2, sprintf('%.1f', data(1)), ...
        'Horiz','center', 'Color','w', 'FontWeight','bold', 'FontSize', 13);
    
    % Global Value (centered in segment)
    text(ax, 1, data(1) + data(2)/2, sprintf('%.1f', data(2)), ...
        'Horiz','center', 'Color','w', 'FontWeight','bold', 'FontSize', 13);
    
    % Total Summary (placed just above the bar)
    text(ax, 1, totalVal + (totalVal * 0.05), ...
        sprintf('Total:\n%.1f %s', totalVal, units{i}), ...
        'Horiz','center', 'VerticalAlignment', 'bottom', ...
        'Color','k', 'FontWeight','bold', 'FontSize', 14);
end

% Shared Legend at the bottom
lgd = legend(b, {'Local Footprint', 'Global Footprint'}, ...
    'Orientation', 'horizontal', 'FontSize', 13);
lgd.Layout.Tile = 'south';

% 4. Save Figure
fileName = fullfile(outputDir, 'Aggregated_Urban_Snapshot_2019_Fixed.png');
saveas(fig, fileName);
fprintf('✔ Aggregated figure saved to: %s\n', fileName);