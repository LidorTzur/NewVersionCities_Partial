%% =====================================================================
%  Plot_Emissions_By_Sector_SharedY_CleanX.m
%  Goal: Shared Y-axis, Enlarged axis numbers, No X-label.
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

cityNames = fieldnames(AllCities);
cities    = struct2cell(AllCities);
nCities   = numel(cities);

%% --- Identify Unique Sectors ---
sectorOrder = string([]);
for c = 1:nCities
    % Using getScenarioTableSum for summarized data
    tbl = getScenarioTableSum(cities{c}, 'BAU');   
    % Extract row names excluding the last row (Total)
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
        
        if isPC
            unitStr = 'tCO2e per capita';
        else
            unitStr = 'MtCO2eq';
        end
        
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
                    % Use extractSectorMatrix helper
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
            
            totals = sum(y, 1);
            text(ax, 1:numel(targetYears), totals, string(num2str(totals', '%.2f')), ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
                'FontSize', fs_data, 'FontWeight', 'bold');
            
            grid(ax, 'on');
            title(ax, cityName, 'FontSize', fs_title_city, 'FontWeight', 'bold');
            
            % --- Axis Settings (Enlarged) ---
            % Apply font size to axis numbers
            set(ax, 'FontSize', fs_axis_numbers, 'FontWeight', 'bold');
            
            % Small rotation for years to prevent overlap
            xtickangle(ax, 30);
            
            % Remove X-axis label
            xlabel(ax, ''); 
            
            % --- Shared Y-Axis Logic ---
            if c == 1
                ylabel(ax, unitStr, 'FontSize', fs_axis_labels, 'FontWeight', 'bold');
                ax.YAxis.Visible = 'on';
            else
                % Hide numbers for plots that are not the first one
                set(ax, 'YTickLabel', []); 
                ax.YAxis.Label.String = ''; 
            end
        end
        
        % Sync Height
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
disp('✔ Done! Plots generated with large axis numbers and no X-labels.');