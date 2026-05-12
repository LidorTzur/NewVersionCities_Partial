%% =====================================================================
% Generate_Local_Global_HighVis_FixedAxis.m
% Fixed Axis scaling and Label visibility for Word.
%% =====================================================================

% 1. Load the Summary Table
T = readtable('Results_Plots/SummaryTable_Long_2035.xlsx');

metricPairs = { ...
    {'Emission_Local', 'Emission_Global'}, ...
    {'Area_Local', 'Area_Global'}, ...
    {'Water_Local', 'Water_Global'} ...
    };

yLabels = {'GHG Emissions [MtCO2e]', 'Area Footprint [km2]', 'Water Consumption [Mm3]'};
baseTitles = {'Greenhouse Gas Emissions', 'Land Footprint', 'Water Footprint'};
scenarios = {'BAU', 'Moderate', 'Advanced'};
years = {'2019', '2035', '2050'};
shortYears = {'19', '35', '50'};

outputDir = 'Results_Plots/Aggregated_Figures/Local_Global_Analysis';
if ~exist(outputDir, 'dir'), mkdir(outputDir); end

for p = 1:numel(metricPairs)
    localMetric = metricPairs{p}{1};
    globalMetric = metricPairs{p}{2};
    
    figure('Name', baseTitles{p}, 'Color', 'w', 'Position', [50 50 1400 950]);
    
    % --- Step 1: Pre-calculate Absolute Max for Axis Scaling ---
    absMax = 0;
    allData = cell(1,3);
    for s = 1:numel(scenarios)
        tempData = zeros(numel(years), 2);
        for yIdx = 1:numel(years)
            yearCol = ['Year_', years{yIdx}];
            lIdx = strcmp(T.Metric, localMetric) & strcmp(T.Scenario, scenarios{s});
            gIdx = strcmp(T.Metric, globalMetric) & strcmp(T.Scenario, scenarios{s});
            tempData(yIdx, 1) = sum(T.(yearCol)(lIdx));
            tempData(yIdx, 2) = sum(T.(yearCol)(gIdx));
        end
        allData{s} = tempData;
        absMax = max(absMax, max(sum(tempData, 2))); % Total height of stacked bar
    end

    % --- Step 2: Plotting ---
    for s = 1:numel(scenarios)
        subplot(1, 3, s);
        plotData = allData{s};
        
        b = bar(plotData, 'stacked', 'EdgeColor', 'black', 'LineWidth', 2);
        b(1).FaceColor = [0.2 0.4 0.6]; % Local
        b(2).FaceColor = [0.8 0.4 0.2]; % Global
        
        set(gca, 'FontSize', 20, 'FontWeight', 'bold', 'FontName', 'Arial');
        title(['Scenario: ', scenarios{s}], 'FontSize', 22, 'FontWeight', 'bold');
        set(gca, 'XTickLabel', shortYears);
        ylabel(yLabels{p}, 'FontSize', 20);
        grid on;
        
        % Set Uniform Axis for all subplots in this figure
        ylim([0 absMax * 1.3]); % 30% margin for labels
        
        if s == 3
            legend({'Local', 'Global'}, 'Location', 'northeastoutside', 'FontSize', 18);
        end
        
        % --- Internal Labels ---
        for i = 1:numel(b)
            xData = b(i).XEndPoints;
            yData = b(i).YData;
            cumulativePos = (i==2) .* plotData(:,1); 
            
            for j = 1:numel(yData)
                val = yData(j);
                if val > (absMax * 0.03) % Threshold for showing labels
                    formattedVal = char(java.text.DecimalFormat('#,##0').format(val));
                    
                    % Position & Color Logic
                    if val < (absMax * 0.12) % If segment is thin
                        txtColor = 'black';
                        vAlign = 'bottom';
                        yPos = cumulativePos(j) + val;
                    else
                        txtColor = 'white';
                        vAlign = 'middle';
                        yPos = cumulativePos(j) + val/2;
                    end
                    
                    text(xData(j), yPos, formattedVal, ...
                        'HorizontalAlignment', 'center', ...
                        'VerticalAlignment', vAlign, ...
                        'FontSize', 14, 'FontWeight', 'bold', ...
                        'Color', txtColor, 'Rotation', 40); 
                end
            end
        end
    end
    
    sgtitle(baseTitles{p}, 'FontSize', 34, 'FontWeight', 'bold');
    
    % Save
    saveas(gcf, fullfile(outputDir, ['Local_Global_', baseTitles{p}, '_HighVis_Final.png']));
    close(gcf);
end

disp('✔ Local vs Global plots with fixed scaling generated.');