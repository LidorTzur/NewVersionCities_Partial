function SR = runSensitivityAnalysis(DataBase, ScenariosAndValues, Years, varargin)
    % runSensitivityAnalysis: Performs a +- X% sensitivity analysis on selected scenarios.
    %
    % Inputs:
    %   DataBase - The main city data structure.
    %   ScenariosAndValues - The table containing scenario percentages.
    %   Years - Calculation period length.
    %
    % Optional Parameters (Name-Value):
    %   'RelevantScenarios' - Array of row indices to analyze (Default: [1,2,4,5,6,7,8,12,13,14,15,16,17,19,20]).
    %   'Deviation'         - The % change to test (Default: 0.1 for 10%).
    %   'BaseColumn'        - The column index in ScenariosAndValues to use (Default: 9).
    %   'EnergyIdx'         - Indices for [Renewable, Gas] for balancing (Default: [6, 7]).

    %% 1. Input Parsing
    p = inputParser;
    addRequired(p, 'DataBase');
    addRequired(p, 'ScenariosAndValues');
    addRequired(p, 'Years');
    
    % Define defaults
    % addParameter(p, 'RelevantScenarios', [1, 2, 4, 5, 6, 7, 8, 12, 13, 14, 15, 16, 17, 19, 20]);
    addParameter(p, 'RelevantScenarios', [1, 2, 4]);
    addParameter(p, 'Deviation', 0.1); 
    addParameter(p, 'BaseColumn', 9);  
    addParameter(p, 'EnergyIdx', [6, 7]); 
    addParameter(p, 'ExistingSR', struct());
    
    parse(p, DataBase, ScenariosAndValues, Years, varargin{:});
    res = p.Results;

    % Local variables for readability
    RelScenIndices = res.RelevantScenarios;
    RowNames = ScenariosAndValues.Properties.RowNames;
    RelNames = RowNames(RelScenIndices);
    Dev = res.Deviation;
    Col = res.BaseColumn;
    
    %% 2. Initialize Results Structure

    % בדיקה: האם הועבר לנו מבנה SR קיים כדי שנוסיף עליו?
    % נוסיף פרמטר אופציונלי בשם 'ExistingSR'
    parse(p, DataBase, ScenariosAndValues, Years, varargin{:});
    res = p.Results;
    SR = res.ExistingSR; % מתחילים מהקיים במקום מריק

    %SR = struct();
    rowLabels = {'As-Is', ['+', num2str(Dev*100), '%'], ['-', num2str(Dev*100), '%']};
    
    % אם SR ריק (פעם ראשונה שמריצים), רק אז נאתחל את הטבלאות
    if ~isfield(SR, 'EmissionByScenario')
        SR.EmissionByScenario = array2table(zeros(3, 0), 'RowNames', rowLabels);
        SR.AreaByScenario     = array2table(zeros(3, 0), 'RowNames', rowLabels);
        SR.WaterByScenario    = array2table(zeros(3, 0), 'RowNames', rowLabels);
        SR.DeltaTables        = cell(2, height(ScenariosAndValues));
    end

    % Original values for energy balancing logic
    E1_orig = ScenariosAndValues{res.EnergyIdx(1), Col};
    E2_orig = ScenariosAndValues{res.EnergyIdx(2), Col};



    %% 3. Main Calculation Loop
    for i = 1:length(RelScenIndices)
        Idx = RelScenIndices(i);
        scenName = RowNames{Idx}; % השם של התרחיש הנוכחי
        OrigVal = ScenariosAndValues{Idx, Col};
        
        % Variations: [Base (0 change), Positive change, Negative change]
        Offsets = [0, Dev, -Dev];
        TmpResults = zeros(3, 3); % [Emission, Area, Water]
        TmpTables = cell(1,3);    % To store full emission tables for delta calculation

        for v = 1:3
            CurrentScenarios = ScenariosAndValues;
            current_offset = Offsets(v);
            
            % Apply the change to the current scenario
            CurrentScenarios{Idx, Col} = OrigVal + current_offset;
            
            % Generic Energy Balancing Logic
            % If we increase Renewables, we must decrease Gas (and vice versa)
            if Idx == res.EnergyIdx(1)
                CurrentScenarios{res.EnergyIdx(2), Col} = E2_orig - current_offset;
            elseif Idx == res.EnergyIdx(2)
                CurrentScenarios{res.EnergyIdx(1), Col} = E1_orig - current_offset;
            end
            
            % Run Model Logic
            [FT] = AllButOneChangesByScenarios(DataBase, 0, Years, CurrentScenarios{:, Col}, 'MileStones', false);
            [pop] = populationCal(FT);
            %Fix the Population Growth Vector --- Need to check its working
            %[FT] = CalcGrowthFromNumbers(table2array(pop(3, :)));
            [Emissions, Consump, Res, WaterFood, ~] = FullScenario(DataBase, FT, Years, pop, 2, 0);
            
            % Aggregate Results
            TotalEmTable = CalcUpDownStream(Emissions);
            TmpTables{v} = TotalEmTable;
            
            % Summing total values for the summary tables (assuming index 11 is the relevant sum)
            TmpResults(v, 1) = sum(TotalEmTable{1:12, Years});
            
            [AreaSum, ~, WaterSum] = CalcTotalResources(Res, Consump, WaterFood);
            TmpResults(v, 2) = sum(AreaSum{1:4, Years});
            TmpResults(v, 3) = sum(WaterSum{1:5, Years});
        end
        
        % % Fill Summary Tables
        SR.EmissionByScenario.(scenName) = TmpResults(:, 1);
        SR.AreaByScenario.(scenName)     = TmpResults(:, 2);
        SR.WaterByScenario.(scenName)    = TmpResults(:, 3);
        
        SR.DeltaTables{1, Idx} = TmpTables{2} - TmpTables{1};
        SR.DeltaTables{2, Idx} = TmpTables{1} - TmpTables{3};
    end
    
    % Store metadata
    SR.RelevantScenarioNames = RelNames;
    SR.DeviationUsed = Dev;
    SR.BaseColumnUsed = Col;
end