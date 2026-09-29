function SR = runSensitivityAnalysis_All_Years(DataBase, ScenariosAndValues, Years, varargin)
    %% 1. Input Parsing
    p = inputParser;
    addRequired(p, 'DataBase');
    addRequired(p, 'ScenariosAndValues');
    addRequired(p, 'Years');
    addParameter(p, 'RelevantScenarios', [1, 2, 4]);
    addParameter(p, 'Deviation', 0.1); 
    addParameter(p, 'BaseColumn', 9);  
    addParameter(p, 'EnergyIdx', [6, 7]); 
    addParameter(p, 'ExistingSR', struct());
    parse(p, DataBase, ScenariosAndValues, Years, varargin{:});
    res = p.Results;
    RelScenIndices = res.RelevantScenarios;
    RowNames = ScenariosAndValues.Properties.RowNames;
    RelNames = RowNames(RelScenIndices);
    Dev = res.Deviation;
    Col = res.BaseColumn;
    
    %% 2. Initialize Results Structure
    SR = res.ExistingSR; 
    rowLabels = {'As-Is', ['+', num2str(Dev*100), '%'], ['-', num2str(Dev*100), '%']};
    
    % הגנה מורחבת: מאתחל מחדש אם המבנה ריק או אם הוא מכיל מבנה ישן שאינו Cell Array
    if ~isfield(SR, 'EmissionByScenario') || ~iscell(SR.EmissionByScenario)
        SR.EmissionByScenario = cell(1, Years);
        SR.AreaByScenario     = cell(1, Years);
        SR.WaterByScenario    = cell(1, Years);
        for t = 1:Years
            SR.EmissionByScenario{t} = array2table(zeros(3, 0), 'RowNames', rowLabels);
            SR.AreaByScenario{t}     = array2table(zeros(3, 0), 'RowNames', rowLabels);
            SR.WaterByScenario{t}    = array2table(zeros(3, 0), 'RowNames', rowLabels);
        end
        SR.DeltaTables = cell(2, height(ScenariosAndValues));
    end
    
    E1_orig = ScenariosAndValues{res.EnergyIdx(1), Col};
    E2_orig = ScenariosAndValues{res.EnergyIdx(2), Col};
    
    %% 3. Main Calculation Loop
    for i = 1:length(RelScenIndices)
        Idx = RelScenIndices(i);
        scenName = RowNames{Idx}; 
        OrigVal = ScenariosAndValues{Idx, Col};
        if ~isfield(SR, 'OrigParamValue') || ~isa(SR.OrigParamValue, 'containers.Map')
            SR.OrigParamValue = containers.Map();
        end
        SR.OrigParamValue(scenName) = OrigVal;
        Offsets = [0, Dev, -Dev];
        TmpResultsAllYears = zeros(3, 3, Years); 
        TmpTables = cell(1, 3);    
        
        for v = 1:3
            CurrentScenarios = ScenariosAndValues;
            current_offset = Offsets(v);
            CurrentScenarios{Idx, Col} = OrigVal + current_offset;
            
            if Idx == res.EnergyIdx(1)
                CurrentScenarios{res.EnergyIdx(2), Col} = E2_orig - current_offset;
            elseif Idx == res.EnergyIdx(2)
                CurrentScenarios{res.EnergyIdx(1), Col} = E1_orig - current_offset;
            end
            
            [FT] = AllButOneChangesByScenarios(DataBase, 0, Years, CurrentScenarios{:, Col}, 'MileStones', false);
            [pop] = populationCal(FT);
            [Emissions, Consump, Res, WaterFood, ~] = FullScenario(DataBase, FT, Years, pop, 2, 0);
            TotalEmTable = CalcUpDownStream(Emissions);
            TmpTables{v} = TotalEmTable;
            [AreaSum, ~, WaterSum] = CalcTotalResources(Res, Consump, WaterFood);
            
            for t = 1:Years
                TmpResultsAllYears(v, 1, t) = sum(TotalEmTable{1:12, t});
                TmpResultsAllYears(v, 2, t) = sum(AreaSum{1:4, t});
                TmpResultsAllYears(v, 3, t) = sum(WaterSum{1:5, t});
            end
        end
        
        for t = 1:Years
            SR.EmissionByScenario{t}.(scenName) = TmpResultsAllYears(:, 1, t);
            SR.AreaByScenario{t}.(scenName)     = TmpResultsAllYears(:, 2, t);
            SR.WaterByScenario{t}.(scenName)    = TmpResultsAllYears(:, 3, t);
        end
        
        % שמירת טבלאות ההפרשים (Delta) תוך התאמה לפרמטר הספציפי
        if Idx == 1
            normalization_factor = (Dev * 100); 
            
            DiffMat1 = (TmpTables{2}{:, :} - TmpTables{1}{:, :}) / normalization_factor;
            SR.DeltaTables{1, Idx} = TmpTables{1};
            SR.DeltaTables{1, Idx}{:, :} = DiffMat1;
            
            DiffMat2 = (TmpTables{1}{:, :} - TmpTables{3}{:, :}) / normalization_factor;
            SR.DeltaTables{2, Idx} = TmpTables{1};
            SR.DeltaTables{2, Idx}{:, :} = DiffMat2;
        else
            SR.DeltaTables{1, Idx} = TmpTables{2} - TmpTables{1};
            SR.DeltaTables{2, Idx} = TmpTables{1} - TmpTables{3};
        end
    end
    
    SR.RelevantScenarioNames = RelNames;
    SR.DeviationUsed = Dev;
    SR.BaseColumnUsed = Col;
end


% function SR = runSensitivityAnalysis_All_Years(DataBase, ScenariosAndValues, Years, varargin)
%     %% 1. Input Parsing
%     p = inputParser;
%     addRequired(p, 'DataBase');
%     addRequired(p, 'ScenariosAndValues');
%     addRequired(p, 'Years');
% 
%     addParameter(p, 'RelevantScenarios', [1, 2, 4]);
%     addParameter(p, 'Deviation', 0.1); 
%     addParameter(p, 'BaseColumn', 9);  
%     addParameter(p, 'EnergyIdx', [6, 7]); 
%     addParameter(p, 'ExistingSR', struct());
% 
%     parse(p, DataBase, ScenariosAndValues, Years, varargin{:});
%     res = p.Results;
% 
%     RelScenIndices = res.RelevantScenarios;
%     RowNames = ScenariosAndValues.Properties.RowNames;
%     RelNames = RowNames(RelScenIndices);
%     Dev = res.Deviation;
%     Col = res.BaseColumn;
% 
%     %% 2. Initialize Results Structure
%     SR = res.ExistingSR; 
%     rowLabels = {'As-Is', ['+', num2str(Dev*100), '%'], ['-', num2str(Dev*100), '%']};
% 
%     % הגנה מורחבת: מאתחל מחדש אם המבנה ריק או אם הוא מכיל מבנה ישן שאינו Cell Array
%     if ~isfield(SR, 'EmissionByScenario') || ~iscell(SR.EmissionByScenario)
%         SR.EmissionByScenario = cell(1, Years);
%         SR.AreaByScenario     = cell(1, Years);
%         SR.WaterByScenario    = cell(1, Years);
% 
%         for t = 1:Years
%             SR.EmissionByScenario{t} = array2table(zeros(3, 0), 'RowNames', rowLabels);
%             SR.AreaByScenario{t}     = array2table(zeros(3, 0), 'RowNames', rowLabels);
%             SR.WaterByScenario{t}    = array2table(zeros(3, 0), 'RowNames', rowLabels);
%         end
%         SR.DeltaTables = cell(2, height(ScenariosAndValues));
%     end
% 
%     E1_orig = ScenariosAndValues{res.EnergyIdx(1), Col};
%     E2_orig = ScenariosAndValues{res.EnergyIdx(2), Col};
% 
%     %% 3. Main Calculation Loop
%     for i = 1:length(RelScenIndices)
%         Idx = RelScenIndices(i);
%         scenName = RowNames{Idx}; 
%         OrigVal = ScenariosAndValues{Idx, Col};
% 
%         Offsets = [0, Dev, -Dev];
%         TmpResultsAllYears = zeros(3, 3, Years); 
%         TmpTables = cell(1, 3);    
%         for v = 1:3
%             CurrentScenarios = ScenariosAndValues;
%             current_offset = Offsets(v);
% 
%             CurrentScenarios{Idx, Col} = OrigVal + current_offset;
% 
%             if Idx == res.EnergyIdx(1)
%                 CurrentScenarios{res.EnergyIdx(2), Col} = E2_orig - current_offset;
%             elseif Idx == res.EnergyIdx(2)
%                 CurrentScenarios{res.EnergyIdx(1), Col} = E1_orig - current_offset;
%             end
% 
%             [FT] = AllButOneChangesByScenarios(DataBase, 0, Years, CurrentScenarios{:, Col}, 'MileStones', false);
%             [pop] = populationCal(FT);
%             [Emissions, Consump, Res, WaterFood, ~] = FullScenario(DataBase, FT, Years, pop, 2, 0);
% 
%             TotalEmTable = CalcUpDownStream(Emissions);
%             TmpTables{v} = TotalEmTable;
% 
%             [AreaSum, ~, WaterSum] = CalcTotalResources(Res, Consump, WaterFood);
% 
%             for t = 1:Years
%                 TmpResultsAllYears(v, 1, t) = sum(TotalEmTable{1:12, t});
%                 TmpResultsAllYears(v, 2, t) = sum(AreaSum{1:4, t});
%                 TmpResultsAllYears(v, 3, t) = sum(WaterSum{1:5, t});
%             end
%         end
% 
%         for t = 1:Years
%             SR.EmissionByScenario{t}.(scenName) = TmpResultsAllYears(:, 1, t);
%             SR.AreaByScenario{t}.(scenName)     = TmpResultsAllYears(:, 2, t);
%             SR.WaterByScenario{t}.(scenName)    = TmpResultsAllYears(:, 3, t);
%         end
% 
%         SR.DeltaTables{1, Idx} = TmpTables{2} - TmpTables{1};
%         SR.DeltaTables{2, Idx} = TmpTables{1} - TmpTables{3};
%     end
% 
%     SR.RelevantScenarioNames = RelNames;
%     SR.DeviationUsed = Dev;
%     SR.BaseColumnUsed = Col;
% end


% function SR = runSensitivityAnalysis_All_Years(DataBase, ScenariosAndValues, Years, varargin)
%     %% 1. הגדרות בסיס וערים
%     allCityNames = {'Tlv', 'RishonLeZion', 'BeerSheva', 'Raanana', 'Modiin','Hadera', 'Afula', 'KiryatGat','BeitShemesh', 'MazkeretBatya'};
%     nCities = numel(allCityNames);
%     baseOutputDir = fullfile('Results_Plots', 'Sensitivity Analysis', 'Temporal_Elasticity_Trends');
% 
%     % הגדרת ציר השנים לניתוח המגמה (מ-2025 עד 2050 בקפיצות של 5 שנים)
%     trendYears = 2025:5:2050;
%     nYears = numel(trendYears);
% 
%     % הגדרת סוגי הניתוח והשדות התואמים להם במבנה הנתונים
%     analysisTypes = {'Emissions', 'Area', 'Water'};
%     structFields  = {'EmissionByScenario', 'AreaByScenario', 'WaterByScenario'};
%     nTypes = numel(analysisTypes);
% 
%     % צבעים קבועים לערים
%     customColors = [
%         0.15, 0.15, 0.50;  % Tlv (Navy)
%         0.85, 0.33, 0.10;  % RishonLeZion (Orange)
%         0.10, 0.60, 0.20;  % BeerSheva (Green)
%         0.45, 0.20, 0.60;  % Raanana (Purple)
%         0.00, 0.75, 0.75;  % Modiin (Turquoise)
%         0.65, 0.10, 0.10;  % Hadera (Red)
%         0.95, 0.75, 0.00;  % Afula (Yellow)
%         0.40, 0.40, 0.40;  % KiryatGat (Gray)
%         0.20, 0.80, 0.50;  % BeitShemesh (Mint)
%         0.60, 0.40, 0.20   % MazkeretBatya (Brown)
%     ];
% 
%     %% 2. לולאה ראשית על פני שלושת סוגי המדדים
%     for tIdx = 1:nTypes
%         curType = analysisTypes{tIdx};
%         curField = structFields{tIdx};
% 
%         fprintf('\n==================================================\n');
%         fprintf('Starting Longitudinal Analysis for: %s\n', curType);
%         fprintf('==================================================\n');
% 
%         % יצירת תת-תיקייה ייעודית (למשל: Temporal_Elasticity_Trends/Water)
%         outputDir = fullfile(baseOutputDir, curType);
%         if ~exist(outputDir, 'dir'), mkdir(outputDir); end
% 
%         % שליפת שמות התרחישים וסינון ראשוני מהעיר הראשונה
%         firstCity = allCityNames{1};
%         if isfield(AllCities, firstCity) && isfield(AllCities.(firstCity), 'Sensitivity_RDB_All_Years')
%             if isfield(AllCities.(firstCity).Sensitivity_RDB_All_Years, curField)
%                 scenNames = AllCities.(firstCity).Sensitivity_RDB_All_Years.(curField){1}.Properties.VariableNames;
%                 scenNames([6, 13, 14]) = []; % השמטת העמודות שביקשת להסיר
%                 nScens = numel(scenNames);
%             else
%                 fprintf('Warning: Field %s not found for %s. Skipping this analysis.\n', curField, firstCity);
%                 continue;
%             end
%         else
%             error('Sensitivity_RDB_All_Years not found. Run the simulation first.');
%         end
% 
%         %% 3. בניית מערך נתונים מלא של מדדי אלסטיות: [ערים X תרחישים X שנים]
%         trendTensor = zeros(nCities, nScens, nYears);
%         for y = 1:nYears
%             currentYear = trendYears(y);
%             yearIdx = currentYear - 2019 + 1; % אינדקס סלולרי במודל
% 
%             for i = 1:nCities
%                 cityName = allCityNames{i};
%                 if isfield(AllCities, cityName) && isfield(AllCities.(cityName), 'Sensitivity_RDB_All_Years')
%                     SR = AllCities.(cityName).Sensitivity_RDB_All_Years;
% 
%                     if isfield(SR, curField) && yearIdx <= numel(SR.(curField))
%                         T = SR.(curField){yearIdx};
%                         for s = 1:nScens
%                             targetName = scenNames{s};
%                             if ismember(targetName, T.Properties.VariableNames)
%                                 baseVal = T{1, targetName};
%                                 plusVal = T{2, targetName};
%                                 if baseVal ~= 0
%                                     percChange = ((plusVal - baseVal) / baseVal) * 100;
%                                     trendTensor(i, s, y) = percChange / 10; % נרמול למדד אלסטיות (1% שינוי בפרמטר)
%                                 end
%                             end
%                         end
%                     end
%                 end
%             end
%         end
% 
%         %% 3.1. סינון תרחישים זניחים (סף אלסטיות של 0.02 באחת השנים לפחות)
%         threshold = 0.0;
%         maxImpact = max(max(abs(trendTensor), [], 1), [], 3);
%         significantIdx = maxImpact >= threshold;
% 
%         filteredScenNames = scenNames(significantIdx);
%         nFilteredScens = numel(filteredScenNames);
%         filteredTensor = trendTensor(:, significantIdx, :);
% 
%         if nFilteredScens == 0
%             fprintf('No significant scenarios found for %s with threshold %g. Skipping plots.\n', curType, threshold);
%             continue;
%         end
% 
%         %% =====================================================================
%         %  פלוט מס' 1: גרפי קו של מגמת השינוי באלסטיות לאורך השנים
%         % =====================================================================
%         fprintf('Generating %d temporal elasticity trend line plots for %s...\n', nFilteredScens, curType);
%         for s = 1:nFilteredScens
%             scenName = filteredScenNames{s};
% 
%             fig = figure('Name', sprintf('ElasticityTrend (%s) - %s', curType, scenName), 'Color', 'w', 'Position', [150 150 950 600]);
%             ax = axes(fig);
%             hold on;
% 
%             % ריצה על פני הערים וציור קו לכל עיר לאורך השנים
%             for i = 1:nCities
%                 yData = squeeze(filteredTensor(i, s, :)); % נתוני האלסטיות של עיר i
%                 plot(ax, trendYears, yData, '-o', 'LineWidth', 2, ...
%                      'Color', customColors(i,:), 'MarkerFaceColor', customColors(i,:), ...
%                      'MarkerSize', 6);
%             end
% 
%             grid on;
%             set(ax, 'FontSize', 12, 'FontWeight', 'bold', 'XTick', trendYears);
%             xlabel('Forecast Year', 'FontSize', 13);
%             ylabel('Elasticity (\Delta% Value / 1% \DeltaParam)', 'FontSize', 13);
%             title(sprintf('%s Elasticity Evolution (2025-2050): %s', curType, strrep(scenName,'_',' ')), 'FontSize', 14, 'FontWeight', 'bold');
% 
%             legend(allCityNames, 'Location', 'northeastoutside', 'FontSize', 10);
%             yline(0, 'k--', 'LineWidth', 1.2); % קו אפס לייחוס
% 
%             % שמירה
%             safeName = regexprep(scenName, '[^\w\-_]', '_');
%             saveas(fig, fullfile(outputDir, ['ElasticityTrend_' safeName '.png']));
%             close(fig);
%         end
% 
%         %% =====================================================================
%         %  פלוט מס' 2: מטריצת חום (Heatmap) השוואתית בין שנות מפתח (2035 מול 2050)
%         %% =====================================================================
%         fprintf('Generating System-Wide Elasticity Heatmaps for 2035 and 2050 (%s)...\n', curType);
%         idx2035 = find(trendYears == 2035);
%         idx2050 = find(trendYears == 2050);
% 
%         if ~isempty(idx2035) && ~isempty(idx2050)
%             figHeat = figure('Name', sprintf('System-Wide Elasticity Heatmap - %s', curType), 'Color', 'w', 'Position', [50 50 1400 700]);
% 
%             % יצירת פריסת אריחים מפוצלת
%             t = tiledlayout(figHeat, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
% 
%             cleanScenNames = strrep(filteredScenNames, '_', ' ');
%             colorRange = [min(filteredTensor(:)) max(filteredTensor(:))];
% 
%             % מניעת קריסה במצב שבו המינימום שווה למקסימום (למשל הכל אפסים)
%             if colorRange(1) == colorRange(2)
%                 colorRange = [colorRange(1)-0.1, colorRange(2)+0.1];
%             end
% 
%             % --- תת-גרף שמאל: שנת 2035 ---
%             nexttile(t);
%             data2035 = filteredTensor(:, :, idx2035);
%             h1 = heatmap(figHeat, cleanScenNames, allCityNames, data2035, ...
%                 'Colormap', jet, 'ColorLimits', colorRange);
%             h1.Title = sprintf('%s Elasticity Index - Year 2035', curType);
%             h1.XLabel = 'Policy Parameters';
%             h1.YLabel = 'Cities';
% 
%             % --- תת-גרף ימין: שנת 2050 ---
%             nexttile(t);
%             data2050 = filteredTensor(:, :, idx2050);
%             h2 = heatmap(figHeat, cleanScenNames, allCityNames, data2050, ...
%                 'Colormap', jet, 'ColorLimits', colorRange);
%             h2.Title = sprintf('%s Elasticity Index - Year 2050', curType);
%             h2.XLabel = 'Policy Parameters';
%             h2.YLabel = ''; 
% 
%             % שמירת מפת החום המשותפת
%             saveas(figHeat, fullfile(outputDir, 'System_Elasticity_Heatmap_Comparison.png'));
%             close(figHeat);
%             fprintf('Successfully saved heatmap comparison for %s.\n', curType);
%         end
%     end
% 
%     fprintf('\n==================================================\n');
%     fprintf('All longitudinal analyses are completed!\n');
%     fprintf('Results are saved in subfolders under:\n%s\n', baseOutputDir);
% end