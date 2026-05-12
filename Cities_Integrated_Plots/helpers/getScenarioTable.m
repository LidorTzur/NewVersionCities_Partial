function tbl = getScenarioTable(C, scen)
    switch scen
        case 'BAU',      tbl = C.BAU_RDB.TotalEmission1;
        case 'Moderate', tbl = C.Moderate_RDB.TotalEmission2;
        case 'Advanced', tbl = C.Advanced_RDB.TotalEmission3;
        otherwise, error('Unknown scenario');
    end
end
