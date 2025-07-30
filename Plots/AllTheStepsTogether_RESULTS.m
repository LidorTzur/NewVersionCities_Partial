
RDB = ResultsDataBase;

%% Define the Final Tables to Output
AllTogetherCell = cell(3, 1);
YearsStringsForColNames = cell(1,Years);

for i=1:Years
    s1 = num2str(i+BaseYear-1); % changed
    YearsStringsForColNames{i} = s1;
end

%% TotalResults = array2table(zeros(9, Years), 'VariableNames', {YearsStringsForColNames}, 'RowNames', {'BAU - TotalEmission (Ton Eco2)', 'Moderate - TotalEmission (Ton Eco2)', 'Advanced - TotalEmission (Ton Eco2)', 'BAU - TotalArea (Km^2)', 'Moderate - TotalArea (Km^2)', 'Advanced - TotalArea (Km^2)', 'BAU - TotalWater (m^3)', 'Moderate - TotalWater (m^3)', 'Advanced - TotalWater (m^3)'});
TotalResults = array2table(zeros(27, Years));
TotalResults.Properties.RowNames = {'BAU - Emission_Local (Ton MEco2)','Moderate - Emission_Local (Ton MEco2)', 'Advanced - Emission_Local (Ton MEco2)'...
    ,'BAU - Emission_Global (Ton MEco2)','Moderate - Emission_Global (Ton MEco2)', 'Advanced - Emission_Global (Ton MEco2)'...
    ,'BAU - Emission_Total (Ton MEco2)','Moderate - Emission_Total (Ton MEco2)', 'Advanced - Emission_Total (Ton MEco2)'...
    ,'BAU - Area_Local (Km^2)', 'Moderate - Area_Local (Km^2)', 'Advanced - Area_Local (Km^2)' ...
    ,'BAU - Area_Global (Km^2)', 'Moderate - Area_Global (Km^2)', 'Advanced - Area_Global (Km^2)'... 
    ,'BAU - Area_Total (Km^2)', 'Moderate - Area_Total (Km^2)', 'Advanced - Area_Total (Km^2)'...
    ,'BAU - Water_Local (10^6*m^3)', 'Moderate - Water_Local (10^6*m^3)', 'Advanced - Water_Local (10^6*m^3)'...
    ,'BAU - Water_Global (10^6*m^3)', 'Moderate - Water_Global (10^6*m^3)', 'Advanced - Water_Global (10^6*m^3)'...
    ,'BAU - Water_Total (10^6*m^3)', 'Moderate - Water_Total (10^6*m^3)', 'Advanced - Water_Total (10^6*m^3)'};

TotalResults.Properties.VariableNames = YearsStringsForColNames;


%% BAU
RDB.BAU_RDB.TotalEmission1 = CalcUpDownStream(RDB.BAU_RDB.EmissionsByYearsTest1);
Emission1_Sum_Local = sum(RDB.BAU_RDB.TotalEmission1{[1,3,5,7,9,11], :}); 
Emission1_Sum_Global = sum(RDB.BAU_RDB.TotalEmission1{[2,4,6,8,10], :}); 
Emission1_Sum_Total = sum(RDB.BAU_RDB.TotalEmission1{1:11, :}); 

Area1_Sum_Local = sum(RDB.BAU_RDB.AreaSum1{[1, 2, 4], :});
Area1_Sum_Global = RDB.BAU_RDB.AreaSum1{3, :};
Area1_Sum_Total = sum(RDB.BAU_RDB.AreaSum1{1:4, :});

Water1_Sum_Local = sum(RDB.BAU_RDB.WaterSum1{1:4, :}); 
Water1_Sum_Global = RDB.BAU_RDB.WaterSum1{5, :}; 
Water1_Sum_Total = sum(RDB.BAU_RDB.WaterSum1{1:5, :}); 


%% Moderate
RDB.Moderate_RDB.TotalEmission2 = CalcUpDownStream(RDB.Moderate_RDB.EmissionsByYearsTest2);
Emission2_Sum_Local = sum(RDB.Moderate_RDB.TotalEmission2{[1,3,5,7,9,11], :}); 
Emission2_Sum_Global = sum(RDB.Moderate_RDB.TotalEmission2{[2,4,6,8,10], :}); 
Emission2_Sum_Total = sum(RDB.Moderate_RDB.TotalEmission2{1:11, :}); 

Area2_Sum_Local = sum(RDB.Moderate_RDB.AreaSum2{[1, 2, 4], :});
Area2_Sum_Global = RDB.Moderate_RDB.AreaSum2{3, :};
Area2_Sum_Total = sum(RDB.Moderate_RDB.AreaSum2{1:4, :});

Water2_Sum_Local = sum(RDB.Moderate_RDB.WaterSum2{1:4, :}); 
Water2_Sum_Global = RDB.Moderate_RDB.WaterSum2{5, :}; 
Water2_Sum_Total = sum(RDB.Moderate_RDB.WaterSum2{1:5, :}); 

%% Advanced
RDB.Advanced_RDB.TotalEmission3 = CalcUpDownStream(RDB.Advanced_RDB.EmissionsByYearsTest3);
Emission3_Sum_Local = sum(RDB.Advanced_RDB.TotalEmission3{[1,3,5,7,9,11], :}); 
Emission3_Sum_Global = sum(RDB.Advanced_RDB.TotalEmission3{[2,4,6,8,10], :}); 
Emission3_Sum_Total = sum(RDB.Advanced_RDB.TotalEmission3{1:11, :}); 

Area3_Sum_Local = sum(RDB.Advanced_RDB.AreaSum3{[1, 2, 4], :});
Area3_Sum_Global = RDB.Advanced_RDB.AreaSum3{3, :};
Area3_Sum_Total = sum(RDB.Advanced_RDB.AreaSum3{1:4, :});

Water3_Sum_Local = sum(RDB.Advanced_RDB.WaterSum3{1:4, :}); 
Water3_Sum_Global = RDB.Advanced_RDB.WaterSum3{5, :}; 
Water3_Sum_Total = sum(RDB.Advanced_RDB.WaterSum3{1:5, :}); 

%% Compare the Results for the "All the steps together"
BAU_Moderate = RDB.BAU_RDB.TotalEmission1 - RDB.Moderate_RDB.TotalEmission2;
BAU_Advanced = RDB.BAU_RDB.TotalEmission1 - RDB.Advanced_RDB.TotalEmission3;
Moderate_Advanced = RDB.Moderate_RDB.TotalEmission2 - RDB.Advanced_RDB.TotalEmission3;

%% delta tables:
AllTogetherCell{1, 1} = BAU_Moderate;
AllTogetherCell{2, 1} = BAU_Advanced;
AllTogetherCell{3, 1} = Moderate_Advanced;

%% summarized emission table:
TotalResults{1, :} = Emission1_Sum_Local;
TotalResults{2, :} = Emission2_Sum_Local;
TotalResults{3, :} = Emission3_Sum_Local;

TotalResults{4, :} = Emission1_Sum_Global;
TotalResults{5, :} = Emission2_Sum_Global;
TotalResults{6, :} = Emission3_Sum_Global;

TotalResults{7, :} = Emission1_Sum_Total;
TotalResults{8, :} = Emission2_Sum_Total;
TotalResults{9, :} = Emission3_Sum_Total;

%% summarized area table:
TotalResults{10, :} = Area1_Sum_Local;
TotalResults{11, :} = Area2_Sum_Local;
TotalResults{12, :} = Area3_Sum_Local;

TotalResults{13, :} = Area1_Sum_Global;
TotalResults{14, :} = Area2_Sum_Global;
TotalResults{15, :} = Area3_Sum_Global;

TotalResults{16, :} = Area1_Sum_Total;
TotalResults{17, :} = Area2_Sum_Total;
TotalResults{18, :} = Area3_Sum_Total;

%% summarized water table:
TotalResults{19, :} = Water1_Sum_Local;
TotalResults{20, :} = Water2_Sum_Local;
TotalResults{21, :} = Water3_Sum_Local;

TotalResults{22, :} = Water1_Sum_Global;
TotalResults{23, :} = Water2_Sum_Global;
TotalResults{24, :} = Water3_Sum_Global;

TotalResults{25, :} = Water1_Sum_Total;
TotalResults{26, :} = Water2_Sum_Total;
TotalResults{27, :} = Water3_Sum_Total;

AllTogetherTable = cell2table(AllTogetherCell);
AllTogetherTable.Properties.VariableNames = {'delta eCo2 Emission (Ton)'};
AllTogetherTable.Properties.RowNames = {'BAU_Moderate', 'BAU_Advanced', 'Moderate_Advanced'};
AllTogetherCell = table2cell(AllTogetherTable);

%% Saving all the sensetivity results in the DataBase
RDB.TotalResults       = TotalResults;
%RDB.DeltaTables        = AllTogetherCell;
RDB.DeltaTableFull     = AllTogetherTable;

%% Plots - Lidor
plotGroupedStackedEmissions( ...
        {RDB.BAU_RDB}, ...
        '2020', ...
        {'BAU', 'Moderate', 'Advanced'} ...
        );

        plotGroupedStackedEmissions( ...
        {RDB.BAU_RDB, RDB.Moderate_RDB, RDB.Advanced_RDB}, ...
        '2030', ...
        {'BAU', 'Moderate', 'Advanced'} ...
        );

        plotGroupedStackedEmissions( ...
        {RDB.BAU_RDB, RDB.Moderate_RDB, RDB.Advanced_RDB}, ...
        '2050', ...
        {'BAU', 'Moderate', 'Advanced'} ...
        );

% Return to the original DataBases
ResultsDataBase = RDB;
writetable(ResultsDataBase.TotalResults, 'TotalResults.xlsx', 'WriteRowNames', true)

clear Emission1_Sum_Local Emission1_Sum_Global Emission1_Sum_Total Area1_Sum_Local Area1_Sum_Global Area1_Sum_Total Water1_Sum_Local Water1_Sum_Global Water1_Sum_Total
clear Emission2_Sum_Local Emission2_Sum_Global Emission2_Sum_Total Area2_Sum_Local Area2_Sum_Global Area2_Sum_Total Water2_Sum_Local Water2_Sum_Global Water2_Sum_Total
clear Emission3_Sum_Local Emission3_Sum_Global Emission3_Sum_Total Area3_Sum_Local Area3_Sum_Global Area3_Sum_Total Water3_Sum_Local Water3_Sum_Global Water3_Sum_Total
