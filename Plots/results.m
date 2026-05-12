RDB = ResultsDataBase;

Year_Stone = 2050;
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

%Arranging the data and building the graphs
colors1Em = [
    0.72, 0.27, 1.00;   % סגול עז
    0.49, 0.18, 0.56;   % בורדו כהה
    0.93, 0.69, 0.13;   % זהב
    0.51, 0.37, 0.01;   % חום כהה
    0.29, 0.89, 0.69;   % טורקיז בהיר
    0.47, 0.67, 0.19;   % ירוק זית
    0.85, 0.33, 0.10;   % כתום
    0.64, 0.08, 0.18;   % אדום כהה
    0.30, 0.75, 0.93;   % תכלת
    0.00, 0.45, 0.74;   % כחול כהה
    0.00, 1.00, 0.74;   % טורקיז רך
    0.13, 0.55, 0.13;   % ירוק חורשה
    0.75, 0.00, 0.75;   % מג’נטה
    1.00, 0.60, 0.80;   % ורוד בהיר
    0.40, 0.20, 0.00;   % חום אדמדם
    0.25, 0.25, 0.75;   % כחול עמוק
    0.80, 0.40, 0.00;   % כתום כהה
    0.70, 0.70, 0.70;   % אפור בינוני
    0.90, 0.50, 0.10;   % כתום זהוב
    0.10, 0.10, 0.10;   % שחור כמעט מוחלט
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

%% 2. emissions-area-water-base year to Target year *****
% To be used after selecting "all steps together" 

Order = {'2019','No Policy (2050)', 'Moderate (2050)', 'Advanced (2050)'};
x = categorical({'2019','No Policy (2050)', 'Moderate (2050)', 'Advanced (2050)'});
x = reordercats(x, Order);

Size_Emission = (height(NoPolicy)-1);
Size_Area = (height(AreaSum1)-1);
Size_Water = (height(WaterSum1)-1);

figure;
t = tiledlayout(1,3);

% Emissions
nexttile
dataEm = [NoPolicy{1:Size_Emission,1}, NoPolicy{1:Size_Emission,Years}, Scenario1{1:Size_Emission,Years}, Scenario2{1:Size_Emission,Years}];
plotStackedBar('Emissions', dataEm, colors1Em, NoPolicy.Properties.RowNames(1:Size_Emission), 'MtCO2Eq', Order);

% Area
nexttile
dataArea = [AreaSum1{1:Size_Area,1}, AreaSum1{1:Size_Area,Years}, AreaSum2{1:Size_Area,Years}, AreaSum3{1:Size_Area,Years}];
plotStackedBar('Area', dataArea, colors2Area, AreaSum3.Properties.RowNames(1:Size_Area), 'km^2', Order);

% Water
nexttile
dataWater = [WaterSum1{1:Size_Water,1}, WaterSum1{1:Size_Water,Years}, WaterSum2{1:Size_Water,Years}, WaterSum3{1:Size_Water,Years}];
plotStackedBar( 'Water', dataWater, colors3Water, WaterSum3.Properties.RowNames(1:Size_Water), 'Million m^3', Order);

% % Costs
% nexttile
% dataCost = [CostsSum1{1:4,1}, CostsSum1{1:4,Years}, CostsSum2{1:4,Years}, CostsSum3{1:4,Years}];
% plotStackedBar('Costs', dataCost, colors4Cost, CostsSum3.Properties.RowNames(1:4), 'Billion ILS', Order);
title(t, sprintf('Compare Emissions, Area, and Water for 2019 VS 2050 (%s)', cityCode), 'FontSize', 20, 'FontWeight', 'bold');
% UpdatedDeltaTable = cell2table(UpdatedData);
% UpdatedDeltaTable.Properties.RowNames = rowNames;
% UpdatedDeltaTable.Properties.VariableNames = DeltaTable.Properties.VariableNames;
% disp(UpdatedDeltaTable);

ResultsDataBase = RDB;

% Save the results
outFolder = 'C:\Users\צור\Documents\MATLAB\NewVersionCities_Partial\Results_Plots\Cities_Graphs_Sep';
fileName = sprintf('Compare_Emissions_Area_Water_%s.png', cityCode);
exportgraphics(t, fullfile(outFolder, fileName), 'Resolution', 300);

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

    % % If there are more bars than colors, repeat the color list cyclically
    % if size(colors,1) < numel(b)
    %     colors = repmat(colors, ceil(numel(b)/size(colors,1)), 1);
    % end

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