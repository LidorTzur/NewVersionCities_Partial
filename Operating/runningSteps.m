%% running steps

%% scenario type input from the user
orderIndex = choiceList('Select a scenario','Choose one of the scenarios and follow the instructions.',{'All the steps together', 'Sensitivity Analysis +- 10%'});

switch orderIndex
    
    case 1  %% All the steps together
    RDB = ResultsDataBase;
        % First Table ([FullScenariosTable]): change in precentage for each parameter by the years
        % Second Table ([population]): population size per year, seperationg israel and the palestinians.
        % Returns: total Co2 by category, amounts of water/fuels/construction materials, all other resources by category, water for food.
        % ([EmissionsByYearsTest1, ConsumptionAmounts1, Resources1, WaterFromFood1])

        % BAU
        [RDB.BAU_RDB.FullScenariosTable1] = AllButOneChangesByScenarios(DataBase, 0, Years, ScenariosAndValues{:,4}, 'MileStones', false); %% AllButOneChangesByScenarios(Data, ScenarioNumber, Years, S, varargin)
        [RDB.BAU_RDB.population] = populationCal(RDB.BAU_RDB.FullScenariosTable1);
        [RDB.BAU_RDB.EmissionsByYearsTest1, RDB.BAU_RDB.ConsumptionAmounts1, RDB.BAU_RDB.Resources1, RDB.BAU_RDB.WaterFromFood1] = FullScenario(DataBase, RDB.BAU_RDB.FullScenariosTable1,Years,RDB.BAU_RDB.population,orderIndex,0);
        
        % Calculate the Resurces Tables
        [RDB.BAU_RDB.AreaSum1, RDB.BAU_RDB.CostsSum1, RDB.BAU_RDB.WaterSum1] = CalcTotalResources(RDB.BAU_RDB.Resources1, RDB.BAU_RDB.ConsumptionAmounts1, RDB.BAU_RDB.WaterFromFood1);
     
        % Moderate
        [RDB.Moderate_RDB.FullScenariosTable2] = AllButOneChangesByScenarios(DataBase, 0, Years, ScenariosAndValues{:,7}, 'MileStones', false);
        [RDB.Moderate_RDB.population] = populationCal(RDB.Moderate_RDB.FullScenariosTable2);
        [RDB.Moderate_RDB.EmissionsByYearsTest2, RDB.Moderate_RDB.ConsumptionAmounts2, RDB.Moderate_RDB.Resources2, RDB.Moderate_RDB.WaterFromFood2, Data1] = FullScenario(DataBase, RDB.Moderate_RDB.FullScenariosTable2,Years,RDB.Moderate_RDB.population,orderIndex, 0, RDB.BAU_RDB.WaterFromFood1);
        
        % Calculate the Resurces Tables
        [RDB.Moderate_RDB.AreaSum2, RDB.Moderate_RDB.CostsSum2, RDB.Moderate_RDB.WaterSum2] = CalcTotalResources(RDB.Moderate_RDB.Resources2, RDB.Moderate_RDB.ConsumptionAmounts2, RDB.Moderate_RDB.WaterFromFood2);

        % Advanced
        [RDB.Advanced_RDB.FullScenariosTable3] = AllButOneChangesByScenarios(DataBase, 0, Years, ScenariosAndValues{:,8}, 'MileStones', false);
        [RDB.Advanced_RDB.population] = populationCal(RDB.Advanced_RDB.FullScenariosTable3);
        [RDB.Advanced_RDB.EmissionsByYearsTest3, RDB.Advanced_RDB.ConsumptionAmounts3, RDB.Advanced_RDB.Resources3, RDB.Advanced_RDB.WaterFromFood3, Data1] = FullScenario(DataBase, RDB.Advanced_RDB.FullScenariosTable3,Years,RDB.Advanced_RDB.population,orderIndex, 0, RDB.BAU_RDB.WaterFromFood1);
        
        % Calculate the Resurces Tables
        [RDB.Advanced_RDB.AreaSum3, RDB.Advanced_RDB.CostsSum3, RDB.Advanced_RDB.WaterSum3] = CalcTotalResources(RDB.Advanced_RDB.Resources3, RDB.Advanced_RDB.ConsumptionAmounts3, RDB.Advanced_RDB.WaterFromFood3);
        
        ChangeDataBase = Data1;
        ResultsDataBase = RDB;
        AllTheStepsTogether_RESULTS; % Give Tables results
        %results; % Give Graphs Results
        
        % Export the results tables to excel to this project
        %export_results_to_excel;
        disp("All The Steps Together")



    
    case 2 %% Sensitivity Analysis - +- 10%

        fprintf('Starting Sensitivity Analysis for current city...\n');
        
        % Define calculation period
        Years = TargetYear_global - BaseYear + 1;

        % CALL THE GENERIC FUNCTION
        % You can change 'Deviation' or 'RelevantScenarios' right here!
        tempSR = runSensitivityAnalysis(DataBase, ScenariosAndValues, Years, ...
            'RelevantScenarios', [2,6,7,8,13,14,24], ...
            'Deviation', 0.10, ...  % Change to 0.15 for 15%
            'BaseColumn', 7, ...    % Choose which column to test
            'EnergyIdx', [6, 7]);   % Define Renewable/Gas indices
        
        % Save the result into the City's RDB
        SensitivityResults = tempSR;
        
        disp('Sensitivity Analysis Module: Completed successfully.');

        % SR = SensitivityResults;
        % % preperations: define the new scenario precentages and the year.
        % Years = TargetYear_global - BaseYear + 1; 
        % RelevantScenarios = [1, 2, 4, 5, 6, 7, 8, 12, 13, 14, 15, 16, 17, 19, 20];  % only choosing interesting scenarios
        % rowNames = ScenariosAndValues.Properties.RowNames;
        % RelevantScenarioNames = rowNames(RelevantScenarios);
        % 
        % % Define the Final Tables to Output
        % SensitivityAnalysisCell = cell(2, height(ScenariosAndValues));
        % TotalEmissionByScenarioChanged = array2table(zeros(3, length(RelevantScenarios)), 'VariableNames', RelevantScenarioNames, 'RowNames', {'as is', '+0.1', '-0.1'});
        % TotalAreaByScenarioChanged = array2table(zeros(3, length(RelevantScenarios)), 'VariableNames', RelevantScenarioNames, 'RowNames', {'as is', '+0.1', '-0.1'});
        % TotalWaterByScenarioChanged = array2table(zeros(3, length(RelevantScenarios)), 'VariableNames', RelevantScenarioNames, 'RowNames', {'as is', '+0.1', '-0.1'});
        % 
        % % Define the New values of the renewable and gas Scenario
        % renewable_original = ScenariosAndValues{6,9};
        % gas_original = ScenariosAndValues{7,9};
        % % SensitivityAnalysisCell has 12 columns, each of them represent a different scenario.
        % % the upper row is Original_Precentage - 10%_Bigger,  the lower row is Original_Precentage - 10%_Smaller
        % 
        % % Run on all the Interesting Scenario
        % for i = 1:length(RelevantScenarios)
        % 
        %     ScenarioIndex = RelevantScenarios(i); 
        %     OriginalPrecentage = ScenariosAndValues{ScenarioIndex, 9}; % saving the original value
        % 
        %     % running FULL SCENARIO 3 times: as is, +10%, -10%.
        % 
        %     % Calculation on the Original values
        %     [FullScenariosTable1] = AllButOneChangesByScenarios(DataBase, 0, Years, ScenariosAndValues{:,9}, 'MileStones', false);
        %     [population] = populationCal(FullScenariosTable1);
        %     [EmissionsByYearsTest1, ConsumptionAmounts1, Resources1, WaterFromFood1, Data1] = FullScenario(DataBase, FullScenariosTable1,Years,population,orderIndex,0);       
        % 
        %     TotalEmission1 = CalcUpDownStream(EmissionsByYearsTest1);
        %     Emission1_Sum = sum(TotalEmission1{1:12, Years}); 
        % 
        %     % Calculate the Resurces Tables
        %     [AreaSum1, CostsSum1, WaterSum1] = CalcTotalResources(Resources1, ConsumptionAmounts1, WaterFromFood1);
        %     Area1_Sum = sum(AreaSum1{1:4, Years});
        %     Water1_Sum = sum(WaterSum1{1:5, Years}); 
        % 
        %     % new calculation for +10%
        %     ScenariosAndValues{ScenarioIndex, 9} = OriginalPrecentage + 0.1;
        % 
        %     if ScenarioIndex==6
        %        ScenariosAndValues{7,9} = gas_original - 0.1; % if renewable is 10% higher, we substract it from gas
        %     end
        % 
        %     if ScenarioIndex==7
        %        ScenariosAndValues{6,9} = renewable_original - 0.1; % if gas is 10% higher, we substract it from renewable
        %     end
        % 
        %     [FullScenariosTable2] = AllButOneChangesByScenarios(DataBase, 0, Years, ScenariosAndValues{:,9}, 'MileStones', false);
        %     [population] = populationCal(FullScenariosTable2);
        %     [EmissionsByYearsTest2, ConsumptionAmounts2, Resources2, WaterFromFood2, Data1] = FullScenario(DataBase, FullScenariosTable2,Years,population,orderIndex,0);
        % 
        %     TotalEmission2 = CalcUpDownStream(EmissionsByYearsTest2);
        %     Emission2_Sum = sum(TotalEmission2{1:11, Years}); 
        %     [AreaSum2, CostsSum2, WaterSum2] = CalcTotalResources(Resources2, ConsumptionAmounts2, WaterFromFood2);
        %     Area2_Sum = sum(AreaSum2{1:4, Years});  
        %     Water2_Sum = sum(WaterSum2{1:5, Years});  
        % 
        %     ScenariosAndValues{6,9} = renewable_original; %restart
        %     ScenariosAndValues{7,9} = gas_original;
        % 
        % 
        %     % new calculation for -10%
        % 
        %     ScenariosAndValues{ScenarioIndex, 9} = OriginalPrecentage - 0.1 ; % new calculation for -10%
        % 
        %     if ScenarioIndex==6
        %        ScenariosAndValues{7,9} = gas_original + 0.1; % if renewable is 10% lower, we add it to gas
        %     end
        % 
        %     if ScenarioIndex==7
        %        ScenariosAndValues{6,9} = renewable_original + 0.1; % if gas is 10% lower, we add it to renewable
        %     end
        % 
        %     [FullScenariosTable3] = AllButOneChangesByScenarios(DataBase, 0, Years, ScenariosAndValues{:,9}, 'MileStones', false);
        %     [population] = populationCal(FullScenariosTable3);
        %     [EmissionsByYearsTest3, ConsumptionAmounts3, Resources3, WaterFromFood3,Data1] = FullScenario(DataBase, FullScenariosTable3,Years,population,orderIndex,0);
        % 
        %     TotalEmission3 = CalcUpDownStream(EmissionsByYearsTest3);
        %     Emission3_Sum = sum(TotalEmission3{1:11, Years}); 
        % 
        %     [AreaSum3, CostsSum3, WaterSum3] = CalcTotalResources(Resources3, ConsumptionAmounts3, WaterFromFood3);
        %     Area3_Sum = sum(AreaSum3{1:4, Years});
        %     Water3_Sum = sum(WaterSum3{1:5, Years});
        % 
        %     ScenariosAndValues{6,9} = renewable_original; %restart
        %     ScenariosAndValues{7,9} = gas_original;
        % 
        % 
        %     % Compare the Results for the sensetivity Analisys
        %     ChangeDataBase = Data1;
        % 
        %     BiggerMinusOriginal = TotalEmission2 - TotalEmission1;
        %     OriginalMinusSmaller = TotalEmission1 - TotalEmission3;
        % 
        %     % delta tables:
        %     ScenariosAndValues{ScenarioIndex, 9} = OriginalPrecentage ; % RESET
        %     SensitivityAnalysisCell{1, ScenarioIndex} = BiggerMinusOriginal;
        %     SensitivityAnalysisCell{2, ScenarioIndex} = OriginalMinusSmaller;
        % 
        %     % summarized emission table:
        %     TotalEmissionByScenarioChanged{1, i} = Emission1_Sum;
        %     TotalEmissionByScenarioChanged{2, i} = Emission2_Sum;
        %     TotalEmissionByScenarioChanged{3, i} = Emission3_Sum;
        % 
        %     % summarized area table:
        %     TotalAreaByScenarioChanged{1, i} = Area1_Sum;
        %     TotalAreaByScenarioChanged{2, i} = Area2_Sum;
        %     TotalAreaByScenarioChanged{3, i} = Area3_Sum;
        % 
        %     % summarized water table:
        %     TotalWaterByScenarioChanged{1, i} = Water1_Sum;
        %     TotalWaterByScenarioChanged{2, i} = Water2_Sum;
        %     TotalWaterByScenarioChanged{3, i} = Water3_Sum;
        % end
        % 
        % SensitivityAnalysisTable = cell2table(SensitivityAnalysisCell);
        % SensitivityAnalysisTable.Properties.VariableNames = rowNames;
        % SensitivityAnalysisTable.Properties.RowNames = {'BiggerMinusOriginal', 'OriginalMinusSmaller'};
        % SensitivityAnalysisCell = table2cell(SensitivityAnalysisTable);
        % 
        % %% Saving all the sensetivity results in the DataBase
        % SR.EmissionByScenario = TotalEmissionByScenarioChanged;
        % SR.AreaByScenario     = TotalAreaByScenarioChanged;
        % SR.WaterByScenario    = TotalWaterByScenarioChanged;
        % SR.DeltaTables        = SensitivityAnalysisCell;
        % SR.DeltaTableFull     = SensitivityAnalysisTable;
        % 
        % %% Clear and move all the variables
        % SR.Years = Years;
        % SR.RelevantScenarioNames = RelevantScenarioNames;
        % SR.RelevantScenarios = RelevantScenarios;
        % 
        % clear renewable_original gas_original TotalWaterByScenarioChanged TotalAreaByScenarioChanged TotalEmissionByScenarioChanged SensitivityAnalysisCell
        % clear RelevantScenarioNames rowNames RelevantScenarios Years ScenarioIndex OriginalPrecentage
        % clear TotalEmissionByScenarioChanged TotalAreaByScenarioChanged TotalWaterByScenarioChanged SensitivityAnalysisCell SensitivityAnalysisTable
        % clear FullScenariosTable1 population EmissionsByYearsTest1 ConsumptionAmounts1 Resources1 WaterFromFood1 TotalEmission1 Emission1_Sum
        % clear AreaSum1 CostsSum1 WaterSum1 Area1_Sum Water1_Sum AreaSum2 CostsSum2 WaterSum2 Area2_Sum Water2_Sum
        % clear FullScenariosTable2 population EmissionsByYearsTest2 ConsumptionAmounts2 Resources2 WaterFromFood2 TotalEmission2 Emission2_Sum
        % clear FullScenariosTable3 population EmissionsByYearsTest3 ConsumptionAmounts3 Resources3 WaterFromFood3 TotalEmission3 Emission3_Sum
        % clear AreaSum3 CostsSum3 WaterSum3 Area3_Sum Water3_Sum i BiggerMinusOriginal OriginalMinusSmaller
        % 
        % SensitivityResults = SR;
        % disp('SensitivityAnalysis');
        % 

end

% Define the general inputs into the matching DataBase
GeneralInputsDataBase.orderIndex = orderIndex;
GeneralInputsDataBase.BaseYear = BaseYear;
GeneralInputsDataBase.ScenariosAndValues = ScenariosAndValues;
GeneralInputsDataBase.TargetYear_global = TargetYear_global;
GeneralInputsDataBase.Conversion_Liter_To_Kg = DataBase.Conversion_Liter_To_Kg;
GeneralInputsDataBase.Days_In_Year = DataBase.Days_In_Year;
GeneralInputsDataBase.ScenarioRowNames = DataBase.ScenarioRowNames;

%% Clear workspace and DataBase variables
% clear palestinians_base_pop_global PopulationStartYear_global Data
% clear orderIndex ScenarioNumber ScenariosAndValues TargetYear_global Years BaseYear
% DataBase = rmfield(DataBase, {'Days_In_Year', 'Conversion_Liter_To_Kg', 'ScenarioRowNames'});
clear SR RDB AllTogetherCell TotalResults BAU_Moderate BAU_Advanced Moderate_Advanced
clear Data1

beep;





