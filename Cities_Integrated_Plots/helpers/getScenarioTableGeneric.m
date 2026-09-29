function tbl = getScenarioTableGeneric(C, scen, baseTableName)
% Extracts the appropriate table dynamically based on scenario number suffix
    switch scen
        case 'BAU',      suffix = '1';
        case 'Moderate', suffix = '2';
        case 'Advanced', suffix = '3';
        otherwise, error('Unknown scenario');
    end
    % Replace the suffix of the base table name dynamically if needed
    tableName = [baseTableName(1:end-1), suffix];
    RDB = getScenarioRDB(C, scen);
    tbl = RDB.(tableName);
end