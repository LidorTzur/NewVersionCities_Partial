function plotGroupedStackedEmissions(RDBs, year, scenarioNames)
    % הגדרת שורות לפי סקטור
    localRows  = [1, 3, 5, 7, 9, 11];
    globalRows = [2, 4, 6, 8, 10];
    sectorLabels = {'Electricity', 'Transport', 'Food', 'Construction', 'Water', 'Industry'};

    numScenarios = length(RDBs);
    dataToPlot = [];
    totalPerScenario = zeros(1, numScenarios);

    xtickMinor = {};  % 'Local', 'Global'
    xtickMajorCenters = [];  % למיקום שמות BAU וכו׳

    for i = 1:numScenarios
        RDB = RDBs{i};

        % זיהוי הטבלה הנכונה
        if isfield(RDB, 'TotalEmission1')
            tableData = RDB.TotalEmission1;
        elseif isfield(RDB, 'TotalEmission2')
            tableData = RDB.TotalEmission2;
        elseif isfield(RDB, 'TotalEmission3')
            tableData = RDB.TotalEmission3;
        else
            error('Unknown emission table in scenario %s', scenarioNames{i});
        end

        colIdx = find(strcmp(tableData.Properties.VariableNames, year));
        numRows = height(tableData);

        % התאמת שורות לפי זמינות
        localRowsValid  = localRows(localRows <= numRows);
        globalRowsValid = globalRows(globalRows <= numRows);
        sectorLabelsValid = sectorLabels(1:length(localRowsValid));

        % Local values
        localValues = tableData{localRowsValid, colIdx};
        dataToPlot = [dataToPlot; localValues'];
        xtickMinor{end+1} = 'Local';

        % Global values
        globalValues = tableData{globalRowsValid, colIdx};
        if length(globalValues) < length(localValues)
            globalValues = [globalValues; 0];  % Pad industry if missing
        end
        dataToPlot = [dataToPlot; globalValues'];
        xtickMinor{end+1} = 'Global';

        % Center of this scenario's bars
        xtickMajorCenters(end+1) = mean([2*i - 1, 2*i]);

        % Total emissions for scenario
        totalPerScenario(i) = sum(localValues) + sum(globalValues);
    end

    %% גרף עמודות מוערמות לפי סקטור
    figure;
    bar(dataToPlot, 'stacked');
    xticks(1:2*numScenarios);
    xticklabels(xtickMinor);
    xtickangle(0);
    ylabel('Emissions (Ton CO₂)');
    title(['Emission Breakdown by Sector – Year ' year], 'FontSize', 14);
    legend(sectorLabelsValid, 'Location', 'northeastoutside');
    grid on;

    % תוויות סנריו מעל או מתחת לקבוצות
    ylimVals = ylim;
    yBottom = ylimVals(1) - 0.1 * (ylimVals(2) - ylimVals(1));
    for i = 1:numScenarios
        text(xtickMajorCenters(i), yBottom, scenarioNames{i}, ...
            'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    end

    % %% גרף נפרד: סה"כ פליטות לכל תרחיש
    % figure;
    % bar(categorical(scenarioNames), totalPerScenario);
    % ylabel('Total Emissions (Ton CO₂)');
    % title(['Total Emissions (Local + Global) – Year ' year]);
    % grid on;
end





        % %% SETUP
        % 
        % targetYears = {'2020', '2030', '2050'};
        % 
        % sector_groups = {
        %     [1, 2],    % Electricity
        %     [3, 4],    % Transport
        %     [5, 6],    % Food
        %     [7, 8],    % Construction
        %     [9, 10],   % Water
        %     [11]       % Industry
        % };
        % sectorLabels = {'Electricity', 'Transport', 'Food', 'Construction', 'Water', 'Industry'};
        % scenarioLabels = {'BAU', 'Moderate', 'Advanced'};
        % 
        % yearIndices = find(ismember(ResultsDataBase.BAU_RDB.TotalEmission1.Properties.VariableNames, targetYears));
        % 
        % numScenarios = 3;
        % numSectors = length(sector_groups);
        % numYears = length(yearIndices);
        % stackedData = zeros(numScenarios, numSectors, numYears);
        % 
        % %% EXTRACT DATA
        % 
        % for y = 1:numYears
        %     colIdx = yearIndices(y);
        % 
        %     % BAU
        %     for s = 1:numSectors
        %         stackedData(1, s, y) = sum(ResultsDataBase.BAU_RDB.TotalEmission1{sector_groups{s}, colIdx});
        %     end
        % 
        %     % Moderate
        %     for s = 1:numSectors
        %         stackedData(2, s, y) = sum(ResultsDataBase.Moderate_RDB.TotalEmission2{sector_groups{s}, colIdx});
        %     end
        % 
        %     % Advanced
        %     for s = 1:numSectors
        %         stackedData(3, s, y) = sum(ResultsDataBase.Advanced_RDB.TotalEmission3{sector_groups{s}, colIdx});
        %     end
        % end
        % 
        % %% PLOT
        % 
        % for y = 1:numYears
        %     figure;
        %     bar(squeeze(stackedData(:, :, y)), 'stacked');
        %     set(gca, 'XTickLabel', scenarioLabels, 'FontSize', 12);
        %     xlabel('Scenario', 'FontWeight', 'bold');
        %     ylabel('Emission (Ton Eco₂)', 'FontWeight', 'bold');
        %     title(['Emission Breakdown by Sector - Year ' targetYears{y}], 'FontSize', 14);
        %     legend(sectorLabels, 'Location', 'northeastoutside');
        %     grid on;
        % end






        %  % Step 1: define target years
        % targetYears = {'2020', '2030', '2050'};
        % 
        % % Step 2: find column indices for those years
        % yearIndices = find(ismember(TotalResults.Properties.VariableNames, targetYears));
        % 
        % % Step 3: define row indices for total emissions
        % % Row 1 = BAU - Local, Row 2 = Moderate - Local, Row 3 = Advanced - Local
        % % Row 4 = BAU - Global, ..., Row 6 = Advanced - Global
        % % Row 7 = BAU - Total, ..., Row 9 = Advanced - Total
        % 
        % rowsToPlot = [1 2 3; 4 5 6; 7 8 9];  % [Local; Global; Total]
        % 
        % % Step 4: extract and reshape the data
        % dataMatrix = zeros(3, 3, 3);  % [Scenario, Type, Year]
        % for i = 1:length(yearIndices)
        %     yearData = TotalResults{rowsToPlot(:), yearIndices(i)};
        %     dataMatrix(:, :, i) = reshape(yearData, [3, 3])';  % [Scenario x Type]
        % end
        % 
        % % Step 5: plot the grouped bar chart
        % scenarioLabels = {'BAU', 'Moderate', 'Advanced'};
        % typeLabels = {'Local', 'Global', 'Total'};
        % 
        % for i = 1:3
        %     figure;
        %     bar(dataMatrix(:, :, i));
        %     set(gca, 'XTickLabel', scenarioLabels);
        %     xlabel('Scenario');
        %     ylabel('Emission (Ton Eco2)');
        %     legend(typeLabels, 'Location', 'northwest');
        %     title(['Emissions Comparison - Year ' targetYears{i}]);
        %     grid on;
        % end

        