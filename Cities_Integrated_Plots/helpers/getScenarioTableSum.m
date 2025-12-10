function tbl = getScenarioTableSum(C, scen)
    switch scen
        case 'BAU',      tbl = C.BAU_RDB.TotalEmissionSum1;
        case 'Moderate', tbl = C.Moderate_RDB.TotalEmissionSum2;
        case 'Advanced', tbl = C.Advanced_RDB.TotalEmissionSum3;
        otherwise, error('Unknown scenario');
    end
end
