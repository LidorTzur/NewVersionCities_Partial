%% =====================================================================
%  Plot_Emissions_By_Sector_SharedY_CleanX.m
%  Goal: Shared Y-axis, Enlarged axis numbers, No X-label, 
%        and Individual sector values displayed inside stacks.
%% =====================================================================
addpath('helpers');

% --- Configuration ---
targetYears = [2019, 2035, 2050]; 
scenarios = {'BAU', 'Moderate', 'Advanced'};

% --- Font Settings ---
fs_axis_numbers = 12;  % Font size for axis numbers (Years and Y-values)
fs_axis_labels  = 14;  % Font size for the Y-label (e.g., MtCO2eq)
fs_title_main   = 22;  
fs_title_city   = 14;  
fs_data         = 9;  
fs_legend       = 12;  

%% --- Configuration & Ordered Data ---
% 1. Get city names in the logical categorical order
catOrder = getCityCategorical(AllCities); 
cityNames = cellstr(catOrder); 
nCities = numel(cityNames);

% 2. Rebuild the 'cities' cell array to match the NEW order
cities = cell(nCities, 1);
for i = 1:nCities
    cityName = cityNames{i};
    cities{i} = AllCities.(cityName);
end

%% --- Identify Unique Sectors ---
sectorOrder = string([]);
for c = 1:nCities
    tbl = getScenarioTableSum(cities{c}, 'BAU');   
    names = string(tbl.Properties.RowNames(1:end-1));
    for nm = names.'
        if ~ismember(nm, sectorOrder), sectorOrder(end+1) = nm; end
    end
end
nSectors = numel(sectorOrder);
colors   = getSectorColors(nSectors);

%% --- Output Directory ---
outputDir = 'Results_Plots\Plot_Emissions_By_Sector';
if ~exist(outputDir,'dir'), mkdir(outputDir); end

%% --- Main Loop ---
for s = 1:numel(scenarios)
    scen = scenarios{s};
    plotTypes = {'Total', 'PerCapita'};
    
    for pt = 1:numel(plotTypes)
        type = plotTypes{pt};
        isPC = strcmp(type, 'PerCapita'); 
        
        figWidth = max(220 * nCities * numel(targetYears), 1500); 
        fig = figure('Name', [type ' - ' scen], 'Color','w', 'Units','pixels', 'Position', [50 50 figWidth 900]);
        
        t = tiledlayout(fig, 1, nCities, 'TileSpacing', 'compact', 'Padding', 'loose'); 
        
        unitStr = 'MtCO2eq';
        if isPC, unitStr = 'tCO2e per capita'; end
        
        sgtitle(fig, sprintf('%s Emissions (%s): %s', type, scen, strjoin(string(targetYears), ' vs ')), ...
                'FontSize', fs_title_main, 'FontWeight', 'bold');
        
        ax_list = [];
        global_max = 0;
        
        for c = 1:nCities
            cityName = cityNames{c};
            cityData = cities{c};
            tbl = getScenarioTableSum(cityData, scen);
            
            y = zeros(numel(sectorOrder), numel(targetYears));
            yearLabels = tbl.Properties.VariableNames;
            
            for k = 1:numel(targetYears)
                yr = targetYears(k);
                colIdx = find(contains(yearLabels, num2str(yr)), 1);
                if ~isempty(colIdx)
                    res = extractSectorMatrix(tbl, sectorOrder, colIdx, colIdx);
                    y(:, k) = res(:, 2);
                    if isPC
                        pop = getPopMillionsByCol(cityData, colIdx, scen, yearLabels);
                        y(:, k) = y(:, k) ./ max(pop, eps);
                    end
                end
            end
            
            current_total_max = max(sum(y, 1));
            if current_total_max > global_max, global_max = current_total_max; end
            
            ax = nexttile(t);
            ax_list = [ax_list, ax]; 
            
            cats = categorical(string(targetYears));
            cats = reordercats(cats, string(targetYears)); 
            
            b = bar(ax, cats, y', 'stacked', 'BarWidth', 0.8);
            for k = 1:numel(b)
                if k <= size(colors,1), b(k).FaceColor = colors(k,:); end
            end
            
            % --- Add individual sector labels inside the bars ---
            yStacked = cumsum(y, 1);       % Cumulative sum for positioning
            yCenters = yStacked - y/2;     % Center of each stack segment
            
            for k = 1:numel(targetYears)
                for sect = 1:nSectors
                    val = y(sect, k);
                    % Only show label if the sector is large enough (e.g., > 4% of axis)
                    if val > (current_total_max * 0.04)
                        % Choose text color based on bar brightness (optional: white for dark colors)
                        txtColor = 'w';
                        if mean(colors(sect,:)) > 0.6, txtColor = 'k'; end % Black for yellow/light
                        
                        text(ax, k, yCenters(sect, k), num2str(val, '%.1f'), ...
                            'HorizontalAlignment', 'center', ...
                            'VerticalAlignment', 'middle', ...
                            'FontSize', fs_data - 2, ...
                            'Color', txtColor, ...
                            'FontWeight', 'bold');
                    end
                end
            end

            % --- Add total labels on top ---
            totals = sum(y, 1);
            text(ax, 1:numel(targetYears), totals, string(num2str(totals', '%.2f')), ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
                'FontSize', fs_data, 'FontWeight', 'bold', 'Color', 'k');
            
            grid(ax, 'on');
            title(ax, cityName, 'FontSize', fs_title_city, 'FontWeight', 'bold');
            set(ax, 'FontSize', fs_axis_numbers, 'FontWeight', 'bold');
            xtickangle(ax, 30);
            xlabel(ax, ''); 
            
            if c == 1
                ylabel(ax, unitStr, 'FontSize', fs_axis_labels, 'FontWeight', 'bold');
                ax.YAxis.Visible = 'on';
            else
                set(ax, 'YTickLabel', []); 
                ax.YAxis.Label.String = ''; 
            end
        end
        
        if global_max > 0
            linkaxes(ax_list, 'y');
            ylim(ax_list(1), [0 max(global_max * 1.25, 0.1)]);
        end
        
        lgd = legend(ax_list(end), cellstr(sectorOrder), 'NumColumns', ceil(nSectors/2));
        lgd.Layout.Tile = 'south';
        lgd.FontSize = fs_legend;
        
        fileName = sprintf('%s_Sectors_SharedY_%s.png', type, scen);
        saveas(fig, fullfile(outputDir, fileName));
    end
end
disp('✔ Done! Plots generated with internal sector labels and shared Y-axis.');