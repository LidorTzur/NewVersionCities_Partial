%% =====================================================================
% Generate_Grouped_Result_Plots_HighVis.m
% High-visibility version for Word: Bold fonts, larger labels, and rotated text.
%% =====================================================================

% 1. Load the Summary Table
T = readtable('Results_Plots/SummaryTable_Long_2035.xlsx');

% Define configurations
targetMetrics = {'Emission_Total', 'Area_Total', 'Water_Total'};
yLabels = {'Total GHG Emissions [MtCO2e]', 'Total Area Footprint [km2]', 'Total Water Consumption [Mm3]'};
chartTitles = {'Overall Urban Greenhouse Gas Emissions', 'Overall Urban Land Footprint', 'Overall Urban Water Footprint'};
scenarios = {'BAU', 'Moderate', 'Advanced'};
years = {'2019', '2035', '2050'};

if ~exist('Results_Plots/Aggregated_Figures', 'dir'), mkdir('Results_Plots/Aggregated_Figures'); end

for m = 1:numel(targetMetrics)
    metricName = targetMetrics{m};
    plotData = zeros(numel(years), numel(scenarios));
    
    for s = 1:numel(scenarios)
        scenName = scenarios{s};
        rowsIdx = strcmp(T.Metric, metricName) & strcmp(T.Scenario, scenName);
        dataSlice = T(rowsIdx, :);
        
        plotData(1, s) = sum(dataSlice.Year_2019);
        plotData(2, s) = sum(dataSlice.Year_2035);
        plotData(3, s) = sum(dataSlice.Year_2050);
    end
    
    % Large Figure Size for better resolution
    figure('Name', chartTitles{m}, 'Color', 'w', 'Position', [100 100 1000 800]);
    b = bar(plotData, 'grouped', 'EdgeColor', 'black', 'LineWidth', 1.5);
    
    % High-Contrast Professional Colors
    b(1).FaceColor = [0.2 0.2 0.2]; % BAU
    b(2).FaceColor = [0.5 0.5 0.5]; % Moderate
    b(3).FaceColor = [0.1 0.6 0.2]; % Advanced
    
    % AXIS PROPERTIES (High Visibility)
    set(gca, 'FontSize', 18, 'FontWeight', 'bold', 'FontName', 'Arial'); 
    set(gca, 'XTickLabel', {'2019 (Baseline)', '2035 (Mid-term)', '2050 (Target)'});
    ylabel(yLabels{m}, 'FontSize', 20, 'FontWeight', 'bold');
    title(chartTitles{m}, 'FontSize', 22, 'FontWeight', 'bold');
    
    legend(scenarios, 'Location', 'northeastoutside', 'FontSize', 16, 'FontWeight', 'bold');
    grid on; set(gca, 'GridAlpha', 0.4);
    
    % DATA LABELS (Rotated and Formatted)
    for i = 1:numel(b)
        xData = b(i).XEndPoints;
        yData = b(i).YData;
        
        for j = 1:numel(yData)
            % Format with thousands separator and round to 1 decimal for clarity in small size
            formattedVal = char(java.text.DecimalFormat('#,##0.0').format(yData(j)));
            
            text(xData(j), yData(j), formattedVal, ...
                'HorizontalAlignment', 'left', ...
                'VerticalAlignment', 'bottom', ...
                'FontSize', 14, ... % Large labels
                'FontWeight', 'bold', ...
                'Rotation', 45); 
        end
    end
    
    % Expand Y-axis limit for labels
    ylim([0 max(plotData(:)) * 1.4]);
    
    filename = ['Results_Plots/Aggregated_Figures/Total_', metricName, '_HighVis.png'];
    saveas(gcf, filename);
    close(gcf);
end
disp('✔ High-visibility grouped charts generated successfully.');