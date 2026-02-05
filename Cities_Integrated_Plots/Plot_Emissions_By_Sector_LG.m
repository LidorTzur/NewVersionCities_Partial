%% =====================================================================
%  Plot_Emissions_By_Detailed_Sector_SharedY.m
%  Goal: Compare DETAILED sectoral emissions with Shared Y-axis 
%        using the exact same sizes and logic as the SUM script.
%% =====================================================================
addpath('helpers');

% --- Modular Configuration ---
targetYears = [2019, 2035, 2050]; 
scenarios = {'BAU', 'Moderate', 'Advanced'};

% --- Font Settings (Matching your chosen code) ---
fs_axis_numbers = 12;  % Font size for axis numbers (Years and Y-values)
fs_axis_labels  = 14;  % Font size for the Y-label (e.g., MtCO2eq)
fs_title_main   = 22;  
fs_title_city   = 14;  
fs_data         = 10;  
fs_legend       = 12;  

% Get city structure info
cityNames = fieldnames(AllCities);
cities    = struct2cell(AllCities);
nCities   = numel(cities);

%% --- Identify Unique Detailed Sectors ---
sectorOrder = string([]);
for c = 1:nCities
    % Use the detailed scenario table (TotalEmission1/2/3)
    tbl = getScenarioTable(cities{c}, 'BAU');   
    
    % Get all row names except the last one (grand Total)
    names = string(tbl.Properties.RowNames(1:end-1)); 
    for nm = names.'
        if ~ismember(nm, sectorOrder), sectorOrder(end+1) = nm; end
    end
end
nSectors = numel(sectorOrder);
colors   = getSectorColors(nSectors);

%% --- Output Directory ---
outputDir = 'Results_Plots\Plot_Emissions_By_Sector_Detailed_LG';
if ~exist(outputDir,'dir'), mkdir(outputDir); end

%% --- Main Loop: Scenarios ---
for s = 1:numel(scenarios)
    scen = scenarios{s};
    plotTypes = {'Total', 'PerCapita'};
    
    for pt = 1:numel(plotTypes)
        type = plotTypes{pt};
        isPC = strcmp(type, 'PerCapita');
        
        % Dynamic figure width
        figWidth = max(220 * nCities * numel(targetYears), 1500); 
        fig = figure('Name',[type ' Detailed - ' scen], 'Color','w', 'Units','pixels', 'Position', [50 50 figWidth 900]);
        
        % Using the same TileSpacing and Padding logic
        t = tiledlayout(fig, 1, nCities, 'TileSpacing', 'compact', 'Padding', 'loose'); 
        
        % Set labels and title
        if isPC, unitStr = 'tCO2e per capita'; else, unitStr = 'MtCO2eq'; end
        
        sgtitle(fig, sprintf('Detailed %s Emissions (%s): %s', type, scen, strjoin(string(targetYears), ' vs ')), ...
                'FontSize', fs_title_main, 'FontWeight', 'bold');
        
        ax_list = [];
        global_max = 0;
        
        %% --- Plotting Each City ---
        for c = 1:nCities
            cityName = cityNames{c};
            cityData = cities{c};
            
            % Get the DETAILED table
            tbl = getScenarioTable(cityData, scen);
            yearLabels = tbl.Properties.VariableNames;
            
            % Build the data matrix (Detailed Sectors x Years)
            y = zeros(numel(sectorOrder), numel(targetYears));
            
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
            
            % Check max for Shared Y-axis scaling
            current_total_max = max(sum(y, 1));
            if current_total_max > global_max, global_max = current_total_max; end
            
            ax = nexttile(t);
            ax_list = [ax_list, ax]; 
            
            cats = categorical(string(targetYears));
            cats = reordercats(cats, string(targetYears)); 
            
            b = bar(ax, cats, y', 'stacked', 'BarWidth', 0.8);
            for k = 1:numel(b)
                b(k).FaceColor = colors(k,:);
            end
            
            % Add labels on top of bars
            totals = sum(y, 1);
            text(ax, 1:numel(targetYears), totals, string(num2str(totals', '%.2f')), ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
                'FontSize', fs_data, 'FontWeight', 'bold');
            
            grid(ax, 'on');
            title(ax, cityName, 'FontSize', fs_title_city, 'FontWeight', 'bold');
            
            % --- Axis Settings (Exact same as your chosen code) ---
            set(ax, 'FontSize', fs_axis_numbers, 'FontWeight', 'bold');
            xtickangle(ax, 30);
            xlabel(ax, ''); 
            
            % --- Shared Y-Axis Logic ---
            if c == 1
                ylabel(ax, unitStr, 'FontSize', fs_axis_labels, 'FontWeight', 'bold');
                ax.YAxis.Visible = 'on';
            else
                % Hide numbers for non-primary plots
                set(ax, 'YTickLabel', []); 
                ax.YAxis.Label.String = ''; 
            end
        end
        
        % Sync Height across all detailed plots
        if global_max > 0
            linkaxes(ax_list, 'y');
            ylim(ax_list(1), [0 max(global_max * 1.25, 0.1)]);
        end
        
        % Bottom Legend (using NumColumns for many detailed sectors)
        lgd = legend(ax_list(end), cellstr(sectorOrder), 'NumColumns', ceil(nSectors/3));
        lgd.Layout.Tile = 'south';
        lgd.FontSize = fs_legend;
        
        % Save Output
        fileName = sprintf('%s_Detailed_Sectors_SharedY_%s.png', type, scen);
        saveas(fig, fullfile(outputDir, fileName));
    end
end
disp('✔ Detailed Shared-Y plots finished! Check Results_Plots\Plot_Emissions_By_Sector_Detailed_LG');