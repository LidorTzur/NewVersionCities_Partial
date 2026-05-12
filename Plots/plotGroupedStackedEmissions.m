function plotGroupedStackedEmissions(RDBs, year, scenarioNames, cityCode)
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
    title(sprintf('Emission Breakdown by Sector – Year %s (%s)', year, cityCode), 'FontSize', 14);
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

        