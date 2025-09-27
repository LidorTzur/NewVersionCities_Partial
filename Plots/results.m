RDB = ResultsDataBase;

Year_Stone = 2035;
Middle_Year  = (Year_Stone - BaseYear + 1);

%% preparations

[AreaSum1, CostsSum1, WaterSum1, NoPolicy] = deal(RDB.BAU_RDB.AreaSum1, RDB.BAU_RDB.CostsSum1, RDB.BAU_RDB.WaterSum1, RDB.BAU_RDB.TotalEmission1);
[AreaSum2, CostsSum2, WaterSum2, Scenario1] = deal(RDB.Moderate_RDB.AreaSum2, RDB.Moderate_RDB.CostsSum2, RDB.Moderate_RDB.WaterSum2, RDB.Moderate_RDB.TotalEmission2);
[AreaSum3, CostsSum3, WaterSum3, Scenario2] = deal(RDB.Advanced_RDB.AreaSum3, RDB.Advanced_RDB.CostsSum3, RDB.Advanced_RDB.WaterSum3, RDB.Advanced_RDB.TotalEmission3);
 
NoPolicy.Properties.RowNames = strrep(NoPolicy.Properties.RowNames, 'Local', ' Domestic');
AreaSum3.Properties.RowNames = strrep(AreaSum3.Properties.RowNames, 'Local', 'Domestic');

AreaSum1 = sortrows(AreaSum1,1,'descend'); 
WaterSum1 = sortrows(WaterSum1,1,'descend');
CostsSum1 = sortrows(CostsSum1,1,'descend');
AreaSum1(1, :) = [];
WaterSum1(1, :) = [];
CostsSum1(1, :) = [];
AreaSum2 = sortrows(AreaSum2,1,'descend');
WaterSum2 = sortrows(WaterSum2,1,'descend');
CostsSum2 = sortrows(CostsSum2,1,'descend');
AreaSum2(1, :) = [];
WaterSum2(1, :) = [];
CostsSum2(1, :) = [];
AreaSum3 = sortrows(AreaSum3,1,'descend');
WaterSum3 = sortrows(WaterSum3,1,'descend');
CostsSum3 = sortrows(CostsSum3,1,'descend');
AreaSum3(1, :) = [];
WaterSum3(1, :) = [];
CostsSum3(1, :) = [];

% Arranging the data and building the graphs
colors1Em = [
   0.72, 0.27, 1.0; 
    0.49, 0.18, 0.56;  
    0.93, 0.69, 0.13;  
    0.51, 0.37, 0.01;  
    0.29, 0.89, 0.69;  
    0.47, 0.67, 0.19;  
    0.85, 0.33, 0.1;  
    0.64, 0.08, 0.18;  
    0.3, 0.75, 0.93;  
    0, 0.45, 0.74;
    0, 1, 0.74;
];

colors2Area = [
    0.47, 0.67, 0.19;
    0.29, 0.89, 0.69; 
    0.85, 0.33, 0.1; 
    0.72, 0.27, 1.0;
];

colors3Water = [
    0.1, 0.31, 0.5;  
    0, 0.45, 0.74;  
    0.46, 0.72, 0.89;  
    0.92, 0.93, 0.93;  
    0.72, 0.27, 1.0;
];

colors4Cost = [
    0.1, 0.31, 0.5;  
    0, 0.45, 0.74;  
    0.85, 0.33, 0.1; 
    0.72, 0.27, 1.0;
];


%% 1. Main graph - For the first base year
Order = {'BAU'};
x = categorical(Order);
x = reordercats(x, Order);

figure;
t = tiledlayout(1,3);

nexttile
plotStackedBar('Emissions', NoPolicy{1:11,1}, colors1Em, NoPolicy.Properties.RowNames(1:11), 'MtCO2Eq', {'Base Year'});
nexttile
plotStackedBar('Area', AreaSum1{1:4,1}, colors2Area, AreaSum1.Properties.RowNames(1:4), 'km^2', {'Base Year'});
nexttile
plotStackedBar('Water', WaterSum1{1:5,1}, colors3Water, WaterSum1.Properties.RowNames(1:5), 'Million m^3', {'Base Year'});
% nexttile
% plotStackedBar('Cost- 2019', CostsSum1{1:4,1}, colors4Cost, CostsSum1.Properties.RowNames(1:4), 'Billion ILS', {'Base Year'});
title(t, sprintf('Emissions, Area, and Water for Base Year - 2019 (%s)', cityCode), 'FontSize', 20, 'FontWeight', 'bold');



%% 2. emissions-area-water-base year to Target year *****
% To be used after selecting "all steps together" 

Order = {'2019','No Policy (2050)', 'Moderate (2050)', 'Advanced (2050)'};
x = categorical({'2019','No Policy (2050)', 'Moderate (2050)', 'Advanced (2050)'});
x = reordercats(x, Order);

figure;
t = tiledlayout(1,3);

% Emissions
nexttile
dataEm = [NoPolicy{1:11,1}, NoPolicy{1:11,Years}, Scenario1{1:11,Years}, Scenario2{1:11,Years}];
plotStackedBar('Emissions', dataEm, colors1Em, NoPolicy.Properties.RowNames(1:11), 'MtCO2Eq', Order);

% Area
nexttile
dataArea = [AreaSum1{1:4,1}, AreaSum1{1:4,Years}, AreaSum2{1:4,Years}, AreaSum3{1:4,Years}];
plotStackedBar('Area', dataArea, colors2Area, AreaSum3.Properties.RowNames(1:4), 'km^2', Order);

% Water
nexttile
dataWater = [WaterSum1{1:5,1}, WaterSum1{1:5,Years}, WaterSum2{1:5,Years}, WaterSum3{1:5,Years}];
plotStackedBar( 'Water', dataWater, colors3Water, WaterSum3.Properties.RowNames(1:5), 'Million m^3', Order);

% % Costs
% nexttile
% dataCost = [CostsSum1{1:4,1}, CostsSum1{1:4,Years}, CostsSum2{1:4,Years}, CostsSum3{1:4,Years}];
% plotStackedBar('Costs', dataCost, colors4Cost, CostsSum3.Properties.RowNames(1:4), 'Billion ILS', Order);
title(t, sprintf('Compare Emissions, Area, and Water for 2019 VS 2050 (%s)', cityCode), 'FontSize', 20, 'FontWeight', 'bold');



% %% 3. emissions-area-water: base year to 2035 with specific scenario
% % To be used after selecting "all steps together" (FOR 2035!) - index 7
% 
% % % Arranging the data and building the graph
% % colors1Em = [
% %     0.902, 0.373, 0.145; % electricity - L
% %     0.6353, 0.0824, 0.1843
% %     0.949, 0.737, 0.239;  % transportaion - L
% %     0.7098, 0.5333, 0.1765
% %     0.784, 0.910, 0.690; % food - L 
% %     0.4314, 0.6196, 0.4627
% %     0.871, 0.761, 0.941; % construction - L 
% %     0.4941, 0.3490, 0.6039
% %     0.302, 0.749, 0.929; % water - L
% %     0.0039, 0.4471, 0.7451
% %     0.361, 0.325, 0.325; % fuels - L
% % ];
% % 
% % colors2Area = [
% %     0.4314, 0.6196, 0.4627;
% %     0.7961, 0.8863, 0.6667; 
% %     0.7843, 0.5961, 0.6824; 
% %     0.8510, 0.3216, 0.0941;
% % ];
% % 
% % colors3Water = [
% %     24/255, 80/255, 129/255; 
% %     0.0039, 0.4471, 0.7451;
% %     0.4627, 0.7216, 0.8902;    
% %     0.9176, 0.9255, 0.9216;        
% %     0.3608, 0.4667, 0.5098;   
% %     ];
% 
% Order = {'Base Year','No Policy (2035)', 'Chosen Scenario (2035)'};
% x = categorical({'Base Year','No Policy (2035)', 'Chosen Scenario (2035)'});
% x = reordercats(x, Order);
% 
% figure;
% t = tiledlayout(1,3);
% 
% % Tile 1 – Emission
% nexttile
% dataEm = [NoPolicy{1:11,1}, NoPolicy{1:11,Middle_Year}, Scenario2{1:11,Middle_Year}];
% plotStackedBar('Emissions', dataEm, colors1Em, NoPolicy.Properties.RowNames(1:11), 'MtCO2Eq', Order);
% 
% % Tile 2 – Area
% nexttile
% dataArea = [AreaSum1{1:4,1}, AreaSum1{1:4,Middle_Year}, AreaSum3{1:4,Middle_Year}];
% plotStackedBar('Area', dataArea, colors2Area, AreaSum3.Properties.RowNames(1:4), 'km^2', Order);
% 
% % Tile 3 – Water
% nexttile
% dataWater = [WaterSum1{1:5,1}, WaterSum1{1:5,Middle_Year}, WaterSum3{1:5, Middle_Year}];
% plotStackedBar('Water', dataWater, colors3Water, WaterSum3.Properties.RowNames(1:5), 'Million m^3', Order);
% title(t, 'Compare Emissions, Area, and Water for 2019 VS 2035', 'FontSize', 20, 'FontWeight', 'bold');



% %% 4. Discussion - emissions
% % To be used after selecting "sensitivity analysis"
% 
% BySectors = cell(1,11);
% for i = 2:10
%     BySectors{i} = CalcUpDownStream(SensitivityAnalysisCell{1,i-1});
%     BySectors{i}(12,:) = [];
% end    
% 
% Order = {'Base Year','Pop 0%\newlineElec 0%', 'Pop 0%\newlineElec 20%', 'Pop 0%\newlineElec 41%','Pop 45%\newlineElec 0%','Pop 45%\newlineElec 20%','Pop 45%\newlineElec 41%','Pop 90%\newlineElec 0%','Pop 90%\newlineElec 20%','Pop 90%\newlineElec 41%'};
% h = categorical({'Base\nYear','1\nPop 0%\nElec 0%', '2\n', '3\n','4\n','5\n','6\n','7\n','8\n','9\n'});
% 
% x = categorical(0:1:9);
% y = zeros(11,10);
% for i = 2:10
%     y(:,i) = BySectors{1,i}{1:11,Years};
% end
% 
% y(:, 1) = BySectors{2}{1:11,1};
% 
% b = bar(x,y,'stacked');
% 
% for i = 1:11
%     set(b(i), 'FaceColor', colors1Em(i, :));
% end
% %ylim([0 110]) 
% legend(flip(b(1:11)), flip(BySectors{3}.Properties.RowNames(1:11,1)), 'FontSize',12,'Location','north')
% title('Emissions By Sectors - 2050',  'FontSize', 28);
% ylabel('MtCO2Eq', 'FontSize', 20);
% xticklabels(Order);
% xtickangle(0);
% xlabel('State', 'FontSize', 20);


% %% 5. NEW NEW NEW - LOCAL 2035
% % only local emissions, base year and 2035 by chosen scenario.
% 
% % Arranging the data and building the graph
% 
% colors1Em = [
%     0.902, 0.373, 0.145; % electricity 
%     0.949, 0.737, 0.239;  % transportaion - L
%     0.784, 0.910, 0.690; % food - L 
%     0.871, 0.761, 0.941; % construction - L 
%     0.302, 0.749, 0.929; % water - L
%     0.361, 0.325, 0.325; % fuels - L
% ];
% 
% 
% NoPolicy = RDB.BAU_RDB.TotalEmission1;
% Scenario2 = RDB.Advanced_RDB.TotalEmission3; 
% Order = {'Base Year - 2019', 'No Policy - 2035', 'Chosen Scenario - 2035'};
% NoPolicy.Properties.RowNames = strrep(NoPolicy.Properties.RowNames, 'Local', ' Domestic');
% 
% y = [NoPolicy{1:2:11,1}, NoPolicy{1:2:11,Middle_Year}, Scenario2{1:2:11,Middle_Year}];
% y = y';
% x = categorical({'Base Year - 2019', 'No Policy - 2035', 'Chosen Scenario - 2035'});
% x = reordercats(x, Order);
% b = bar(x, y, 'stacked');
% 
% for i = 1:numel(b)
%     set(b(i), 'FaceColor', colors1Em(i, :));
% end
% 
% %ylim([0 110])
% title('Emissions - Domestic', 'FontSize', 14);
% xticklabels(Order);
% xtickangle(20);
% xlabel('Scenarios', 'FontSize', 20);
% 
% ylabel('MtCO2Eq', 'FontSize', 20);
% legend(flip(b), flip(NoPolicy.Properties.RowNames(1:2:11)), 'FontSize',10,'Location','northwest')
% 


% %% 6. NEW NEW NEW - GLOBAL 2035
% % only global emissions, base year and 2035 by chosen scenario.
% % Arranging the data and building the graph
% 
% colors1Em = [
%     0.6353, 0.0824, 0.1843
%     0.7098, 0.5333, 0.1765
%     0.4314, 0.6196, 0.4627
%     0.4941, 0.3490, 0.6039
%     0.0039, 0.4471, 0.7451
% ];
% 
% 
% NoPolicy = RDB.BAU_RDB.TotalEmission1;
% Scenario2 = RDB.Advanced_RDB.TotalEmission3; 
% Order = {'Base Year - 2019', 'No Policy - 2035', 'Chosen Scenario - 2035'};
% y = [NoPolicy{2:2:11,1}, NoPolicy{2:2:11,Middle_Year}, Scenario2{2:2:11,Middle_Year}];
% y = y';
% x = categorical({'Base Year - 2019', 'No Policy - 2035', 'Chosen Scenario - 2035'});
% x = reordercats(x, Order);
% b = bar(x, y, 'stacked');
% 
% for i = 1:numel(b)
%     set(b(i), 'FaceColor', colors1Em(i, :));
% end
% 
% %ylim([0 110])
% title('Emissions - Global', 'FontSize', 14);
% xticklabels(Order);
% xtickangle(20);
% xlabel('Scenarios', 'FontSize', 20);
% 
% ylabel('MtCO2Eq', 'FontSize', 20);
% legend(flip(b), flip(NoPolicy.Properties.RowNames(2:2:11)), 'FontSize',10,'Location','northwest')

% %% %% 7. NEW NEW NEW - Sensitivity +-10% (FOR 2035!!)
% 
% DeltaCell = cell(2, Middle_Year); 
% for i = 1:2
%     for j = RelevantScenarios 
%         currentTable = SensitivityAnalysisCell{i, j}; % Extract the table from the current cell - each table is for a specific factor
%         sumValue = sum(currentTable(1:11, Middle_Year)); % total emissions
%         DeltaCell{i, j} = sumValue;
%     end
% end
% 
% rowNames = SensitivityAnalysisTable.Properties.RowNames;
% colNames = SensitivityAnalysisTable.Properties.VariableNames;
% DeltaTable = cell2table(DeltaCell, 'VariableNames', colNames);
% 
% % Presenting te data as numbers:
% UpdatedData = cell(size(DeltaTable));
% for row = 1:size(DeltaTable, 1)
%     for col = 1:size(DeltaTable, 2)
%         % Check if the cell is not empty and is a table
%         if ~isempty(DeltaTable{row, col}) && istable(DeltaTable{row, col})
%             number = DeltaTable{row, col}.Variables;
%             UpdatedData{row, col} = number;
%         end
%     end
% end

% % Convert the cell array to a table
% UpdatedDeltaTable = cell2table(UpdatedData);
% UpdatedDeltaTable.Properties.RowNames = rowNames;
% UpdatedDeltaTable.Properties.VariableNames = DeltaTable.Properties.VariableNames;
% disp(UpdatedDeltaTable);

ResultsDataBase = RDB;


function plotStackedBar(tileTitle, dataMat, colors, rowLabels, ylabelText, Order)
    % % סדר לפי סכום כל שורה
    % rowSums = sum(dataMat, 2);                     % סכום לכל שורה (קטגוריה)
    % [~, sortIdx] = sort(rowSums, 'descend');       % כדי שגדול יהיה בתחתית
    % 
    % % מיין את הנתונים לפי הסדר
    % dataMat = dataMat(sortIdx, :);
    % rowLabels = rowLabels(sortIdx);
    % colors = colors(sortIdx, :);    

    y = dataMat';
    x = categorical(Order);
    x = reordercats(x, Order);
    
    b = bar(x, y, 'stacked');
    for i = 1:numel(b)
        set(b(i), 'FaceColor', colors(i, :));
    end
    
    title(tileTitle, 'FontSize', 14);
    xlabel('Scenarios', 'FontSize', 12);
    ylabel(ylabelText, 'FontSize', 12);
    xticklabels(Order);
    xtickangle(16);
    legend(flip(b), flip(rowLabels), 'FontSize', 7, 'FontWeight', 'bold', 'Location', 'southoutside', 'NumColumns', 2);
end

clear ans AreaSum1 AreaSum2 AreaSum3 b colors3Water colors2Area colors1Em colors4Cost
clear CostsSum3 CostsSum2 CostsSum1 dataWater dataArea dataEm dataCost
clear Middle_Year NoPolicy Order RDB Scenario2 Scenario1 Scenario2 t 
clear WaterSum3 WaterSum1 WaterSum2 x y Year_Stone YearsStringsForColNames