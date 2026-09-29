function RDB = getScenarioRDB(C, scen)
    switch scen
        case 'BAU',          RDB = C.BAU_RDB;
        case 'Moderate',     RDB = C.Moderate_RDB;
        case 'Advanced',     RDB = C.Advanced_RDB;
        otherwise,           error('Unknown scenario');
    end
end