%% =====================================================================
% Generate_Combined_HighVis_LargeLabels.m
% Side-by-side: Total vs. Per Capita. Large labels, no decimals.
%% =====================================================================

% 1. Load data
T = readtable('Results_Plots/SummaryTable_Long_2035.xlsx');
cityNames = fieldnames(AllCities);
scenarios = {'BAU', 'Moderate', 'Advanced'};
years = [2019, 2035, 2050];
yearCols = {'Year_2019', 'Year_2035', 'Year_2050'};

targetMetrics = {'Emission_Total', 'Area_Total', 'Water_Total'};
yLabelsTotal = {'Total MtCO2e', 'Total km2', 'Total Mm3'};
yLabelsCapita = {'tCO2e / cap', 'm2 / cap', 'm3 / cap'};
mainTitles = {'Urban GHG Emissions', 'Urban Land Footprint', 'Urban Water Footprint'};

if ~exist('Results_Plots/Aggregated_Figures/Combined', 'dir'), mkdir('Results_Plots/Aggregated_Figures/Combined'); end

for m = 1:numel(targetMetrics)
    metricName = targetMetrics{m};
    totalPlotData = zeros(3, 3); 
    capitaPlotData = zeros(3, 3);
    
    % --- Calculation Logic ---
    for s = 1:numel(scenarios)
        for yIdx = 1:numel(years)
            currentYear = years(yIdx);
            currentYearCol = yearCols{yIdx};
            
            % Total
            rowsIdx = strcmp(T.Metric, metricName) & strcmp(T.Scenario, scenarios{s});
            totalPlotData(yIdx, s) = sum(T.(currentYearCol)(rowsIdx));
            
            % Per Capita
            cityPerCapValues = [];
            for c = 1:numel(cityNames)
                cityName = cityNames{c};
                cIdx = strcmp(T.City, cityName) & strcmp(T.Metric, metricName) & strcmp(T.Scenario, scenarios{s});
                cityVal = T.(currentYearCol)(cIdx);
                
                C = AllCities.(cityName);
                yLabels_pop = C.BAU_RDB.TotalEmissionSum1.Properties.VariableNames;
                colIdx = find(contains(yLabels_pop, num2str(currentYear)), 1);
                popM = getPopMillionsByCol(C, colIdx, 'BAU', yLabels_pop);
                
                if ~isempty(cityVal) && popM > 0
                    cityPerCapValues(end+1) = cityVal / popM;
                end
            end
            capitaPlotData(yIdx, s) = mean(cityPerCapValues);
        end
    end
    
    % --- PLOTTING ---
    figure('Name', mainTitles{m}, 'Color', 'w', 'Position', [50 100 1500 750]);
    
    % --- LEFT: TOTAL ---
    subplot(1, 2, 1);
    b1 = bar(totalPlotData, 'grouped', 'EdgeColor', 'black', 'LineWidth', 1.2);
    b1(1).FaceColor = [0.2 0.2 0.2]; b1(2).FaceColor = [0.5 0.5 0.5]; b1(3).FaceColor = [0.1 0.6 0.2];
    
    set(gca, 'FontSize', 15, 'FontWeight', 'bold', 'FontName', 'Arial');
    set(gca, 'XTickLabel', {'2019', '2035', '2050'});
    ylabel(yLabelsTotal{m}, 'FontSize', 16);
    title(['Total ', mainTitles{m}], 'FontSize', 18);
    grid on;
    
    for i = 1:numel(b1)
        xD = b1(i).XEndPoints; yD = b1(i).YData;
        for j = 1:numel(yD)
            txt = char(java.text.DecimalFormat('#,##0').format(yD(j)));
            % Increased FontSize to 14 and added offset to Y position
            text(xD(j), yD(j) * 1.02, txt, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
                 'FontSize', 14, 'FontWeight', 'bold', 'Rotation', 50);
        end
    end
    ylim([0 max(totalPlotData(:)) * 1.5]); % More top margin for larger labels

    % --- RIGHT: PER CAPITA ---
    subplot(1, 2, 2);
    b2 = bar(capitaPlotData, 'grouped', 'EdgeColor', 'black', 'LineWidth', 1.2);
    b2(1).FaceColor = [0.2 0.2 0.2]; b2(2).FaceColor = [0.5 0.5 0.5]; b2(3).FaceColor = [0.1 0.6 0.2];
    
    set(gca, 'FontSize', 15, 'FontWeight', 'bold', 'FontName', 'Arial');
    set(gca, 'XTickLabel', {'2019', '2035', '2050'});
    ylabel(yLabelsCapita{m}, 'FontSize', 16);
    title(['Per Capita ', mainTitles{m}], 'FontSize', 18);
    grid on;
    
    for i = 1:numel(b2)
        xD = b2(i).XEndPoints; yD = b2(i).YData;
        for j = 1:numel(yD)
            txt = char(java.text.DecimalFormat('#,##0').format(yD(j)));
            % Increased FontSize to 14 and added offset to Y position
            text(xD(j), yD(j) * 1.02, txt, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
                 'FontSize', 14, 'FontWeight', 'bold', 'Rotation', 50);
        end
    end
    ylim([0 max(capitaPlotData(:)) * 1.5]); % More top margin for larger labels
    
    legend(scenarios, 'Location', 'northeastoutside', 'FontSize', 13);
    
    % Save
    saveas(gcf, fullfile('Results_Plots/Aggregated_Figures/Combined', ['Combined_', metricName, '_LargeLabels.png']));
    close(gcf);
end

disp('✔ Combined charts with enlarged labels generated successfully.');