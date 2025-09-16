% function compare_cities_results(cityStructs, cityNames, baseCol, targetCol)
% % השוואת ערים – ערכים כוללים + פירוק פליטות לפי סקטורים, כולל פלוטים.
% % INPUTS
% %   cityStructs : cell array של מבני תוצאות: {ResultsDataBase_BeerSheva, ResultsDataBase_Rashlaz, ...}
% %   cityNames   : cell array של שמות לתצוגה: {'Beer-Sheva','Rishon LeZion', ...}
% %   baseCol     : אינדקס העמודה של שנת הבסיס (למשל 1 עבור 2019)
% %   targetCol   : אינדקס העמודה של שנת היעד (למשל העמודה של 2050)
% %
% % דרישות מבני הנתונים בכל עיר:
% %   RDB.TotalResults : table עם RowNames בדיוק כפי שתיארת (BAU/Moderate/Advanced × (Emission/Area/Water) × (Local/Global/Total))
% %   RDB.BAU_RDB.TotalEmission1     (11×Years)
% %   RDB.Moderate_RDB.TotalEmission2 (11×Years)
% %   RDB.Advanced_RDB.TotalEmission3 (11×Years)
% 
% assert(iscell(cityStructs) && iscell(cityNames) && numel(cityStructs)==numel(cityNames), ...
%     'cityStructs ו-cityNames חייבים להיות באותו גודל ובהתאמה');
% nCities = numel(cityStructs);
% scenarios = {'BAU','Moderate','Advanced'};
% 
% %% צבעים קבועים
% colorsEm = [  % 11 סקטורים – כמו אצלך (ניתן לשנות)
%    0.72, 0.27, 1.00;
%    0.49, 0.18, 0.56;
%    0.93, 0.69, 0.13;
%    0.51, 0.37, 0.01;
%    0.29, 0.89, 0.69;
%    0.47, 0.67, 0.19;
%    0.85, 0.33, 0.10;
%    0.64, 0.08, 0.18;
%    0.30, 0.75, 0.93;
%    0.00, 0.45, 0.74;
%    0.00, 1.00, 0.74 ];
% colorsArea = [
%    0.47, 0.67, 0.19;
%    0.29, 0.89, 0.69;
%    0.85, 0.33, 0.10;
%    0.72, 0.27, 1.00 ];
% colorsWater = [
%    0.10, 0.31, 0.50;
%    0.00, 0.45, 0.74;
%    0.46, 0.72, 0.89;
%    0.92, 0.93, 0.93;
%    0.72, 0.27, 1.00 ];
% 
% %% --------- 1) השוואת ערכים כוללים בין ערים (Base vs Target) ---------
% % נגדיר מה לשלוף מתוך TotalResults
% metrics = { ...
%   'Emission_Local','Emission_Global','Emission_Total', ...
%   'Area_Local','Area_Global','Area_Total', ...
%   'Water_Local','Water_Global','Water_Total'};
% 
% % איסוף נתונים: city × scenario × metric × {base,target}
% dataTotals = nan(nCities, numel(scenarios), numel(metrics), 2);
% 
% for c = 1:nCities
%     RDB = cityStructs{c};
%     if ~isfield(RDB, 'TotalResults') || ~istable(RDB.TotalResults)
%         warning('(%s) חסרה הטבלה TotalResults – מדלג על השוואת totals לעיר זו.', cityNames{c});
%         continue;
%     end
%     TR = RDB.TotalResults;
%     rn = string(TR.Properties.RowNames);
% 
%     for s = 1:numel(scenarios)
%         sc = scenarios{s};
%         for m = 1:numel(metrics)
%             met = metrics{m};
%             needle = string(compose('%s - %s', sc, strrep(met,'_',' ')));
%             rowKey = startsWith(rn, needle, 'IgnoreCase', true);
%             if ~any(rowKey)
%                 rowKey = contains(rn, needle, 'IgnoreCase', true);
%             end
%             if any(rowKey)
%                 trRow = TR(find(rowKey,1), :);
%                 % בדיקת גבולות
%                 bVal = safeGetCol(trRow, baseCol);
%                 tVal = safeGetCol(trRow, targetCol);
%                 dataTotals(c,s,m,1) = bVal;
%                 dataTotals(c,s,m,2) = tVal;
%             end
%         end
%     end
% end
% 
% % פלוטים: עבור כל metric – עמודה אחת (Base) ועמודה אחת (Target), מקובץ לפי תרחישים, ציר X=ערים
% for m = 1:numel(metrics)
%     met = metrics{m};
%     % Base
%     figure('Name',['Totals - ',met,' (Base)'],'Color','w');
%     tiledlayout(1,1,'Padding','compact'); nexttile;
%     Y = squeeze(dataTotals(:, :, m, 1)); % cities × scenarios
%     bar(Y); grid on; box off;
%     title(sprintf('%s – Base', strrep(met,'_',' ')));
%     ylabel(metricUnit(met));
%     set(gca,'XTick',1:nCities,'XTickLabel',cityNames,'XTickLabelRotation',18);
%     legend(scenarios,'Location','bestoutside');
% 
%     % Target
%     figure('Name',['Totals - ',met,' (Target)'],'Color','w');
%     tiledlayout(1,1,'Padding','compact'); nexttile;
%     Y = squeeze(dataTotals(:, :, m, 2));
%     bar(Y); grid on; box off;
%     title(sprintf('%s – Target', strrep(met,'_',' ')));
%     ylabel(metricUnit(met));
%     set(gca,'XTick',1:nCities,'XTickLabel',cityNames,'XTickLabelRotation',18);
%     legend(scenarios,'Location','bestoutside');
% end
% 
% %% --------- 2) פירוק פליטות לפי סקטורים (Base & Target) ---------
% % נשלוף לכל עיר את טבלאות הפליטות לפי סקטורים מכל תרחיש
% for s = 1:numel(scenarios)
%     figure('Name',['Emissions by Sectors – ',scenarios{s}],'Color','w');
%     t = tiledlayout(ceil(nCities/2), 2, 'TileSpacing','compact','Padding','compact');
%     title(t, ['Emissions by Sectors (',scenarios{s},') – Base vs Target']);
% 
%     for c = 1:nCities
%         RDB = cityStructs{c};
%         [tbl, rowLabels] = getScenarioEmissionTable(RDB, scenarios{s});
%         if isempty(tbl), continue; end
% 
%         % ודא שסדר השורות עקבי בין ערים – אם צריך, מיישר מול התוויות של העיר הראשונה
%         if c==1
%             baseRowOrder = rowLabels;
%         else
%             [tbl, rowLabels] = reorderToMatch(tbl, rowLabels, baseRowOrder);
%         end
% 
%         % y = [Base, Target] לכל שורה (11×2) – מציירים כ-Stacked
%         y = [tbl{1:11, baseCol}, tbl{1:11, targetCol}];
% 
%         nexttile;
%         b = bar(categorical({'Base','Target'}), y', 'stacked'); hold on
%         for i = 1:min(numel(b), size(colorsEm,1)), set(b(i),'FaceColor',colorsEnforce(i, colorsEm)); end
%         title(cityNames{c});
%         ylabel('MtCO2Eq'); grid on; box off;
%         lg = legend(flip(b), flip(rowLabels(1:11)), 'NumColumns',2, 'Location','southoutside');
%         lg.ItemTokenSize = [14,14];
%         xtickangle(0);
%     end
% end
% 
% %% --------- 3) הדגשת סקטור חשמל (Local/Global/Total) בין ערים ---------
% % מתוך טבלת הסקטורים – לוקחים את Electricity-Local/Global (שורות 1–2 בהגדרה שלך),
% % וגם מחשבים Electricity-Total = sum(Local,Global).
% elecLocalIdx  = 1;   % לפי הדאטה שלך
% elecGlobalIdx = 2;
% 
% for s = 1:numel(scenarios)
%     Ebase = nan(nCities, 3);  % [Local, Global, Total]
%     Etarg = nan(nCities, 3);
% 
%     for c = 1:nCities
%         [tbl, rowLabels] = getScenarioEmissionTable(cityStructs{c}, scenarios{s});
%         if isempty(tbl) || size(tbl,1) < max(elecGlobalIdx, elecLocalIdx), continue; end
%         eL_b = tbl{elecLocalIdx,  baseCol};   eG_b = tbl{elecGlobalIdx,  baseCol};
%         eL_t = tbl{elecLocalIdx,  targetCol}; eG_t = tbl{elecGlobalIdx,  targetCol};
%         Ebase(c,:) = [eL_b, eG_b, eL_b+eG_b];
%         Etarg(c,:) = [eL_t, eG_t, eL_t+eG_t];
%     end
% 
%     figure('Name',['Electricity – ',scenarios{s}],'Color','w');
%     tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
% 
%     nexttile
%     bar(Ebase); grid on; box off;
%     title(['Electricity (Base) – ',scenarios{s}]); ylabel('MtCO2Eq');
%     set(gca,'XTick',1:nCities,'XTickLabel',cityNames,'XTickLabelRotation',18);
%     legend({'Local','Global','Total'},'Location','bestoutside');
% 
%     nexttile
%     bar(Etarg); grid on; box off;
%     title(['Electricity (Target) – ',scenarios{s}]); ylabel('MtCO2Eq');
%     set(gca,'XTick',1:nCities,'XTickLabel',cityNames,'XTickLabelRotation',18);
%     legend({'Local','Global','Total'},'Location','bestoutside');
% end
% 
% %% --------- 4) היטל/Heatmap – Emission_Total ב-Target ---------
% EtotalTarget = squeeze(dataTotals(:,:, strcmp(metrics,'Emission_Total'), 2)); % cities × scenarios
% figure('Name','Heatmap – Emission Total (Target)','Color','w');
% h = heatmap(categorical(cityNames), categorical(scenarios), EtotalTarget');
% h.Title = 'Emission Total – Target Year';
% h.XLabel = 'Cities'; h.YLabel = 'Scenario';
% h.CellLabelFormat = '%.3g';
% 
% end % function compare_cities_results
% 
% %% ==================== פונקציות עזר ====================
% 
% function val = safeGetCol(t, idx)
% if idx >= 1 && idx <= width(t)
%     val = t{1, idx};
% else
%     val = NaN;
% end
% end
% 
% function [tbl, rowLabels] = getScenarioEmissionTable(RDB, scenarioName)
% tbl = []; rowLabels = [];
% try
%     switch lower(scenarioName)
%         case 'bau'
%             if isfield(RDB,'BAU_RDB') && istable(RDB.BAU_RDB.TotalEmission1)
%                 tbl = RDB.BAU_RDB.TotalEmission1;
%             end
%         case 'moderate'
%             if isfield(RDB,'Moderate_RDB') && istable(RDB.Moderate_RDB.TotalEmission2)
%                 tbl = RDB.Moderate_RDB.TotalEmission2;
%             end
%         case 'advanced'
%             if isfield(RDB,'Advanced_RDB') && istable(RDB.Advanced_RDB.TotalEmission3)
%                 tbl = RDB.Advanced_RDB.TotalEmission3;
%             end
%     end
%     if ~isempty(tbl)
%         % התאמות קלות לשמות, כמו אצלך:
%         if ~isempty(tbl.Properties.RowNames)
%             rowLabels = string(tbl.Properties.RowNames);
%             rowLabels = strrep(rowLabels,'Local','Domestic'); % אם תרצי להציג Domestic
%         else
%             rowLabels = string( (1:height(tbl))' );
%         end
%     else
%         warning('Missing TotalEmission table for scenario "%s".', scenarioName);
%     end
% catch ME
%     warning('getScenarioEmissionTable: %s', ME.message);
% end
% end
% 
% function [tblOut, labelsOut] = reorderToMatch(tblIn, labelsIn, targetLabels)
% % מיישר סדר שורות של טבלה ו-labels לרשימה נתונה; אם חסר – ממלא NaN
% labelsIn = string(labelsIn);
% targetLabels = string(targetLabels);
% tblOut = array2table(nan(numel(targetLabels), width(tblIn)));
% tblOut.Properties.VariableNames = tblIn.Properties.VariableNames;
% labelsOut = targetLabels;
% 
% for i = 1:numel(targetLabels)
%     k = find(labelsIn==targetLabels(i),1);
%     if ~isempty(k)
%         tblOut{i, :} = tblIn{k, :};
%     end
% end
% tblOut.Properties.RowNames = cellstr(labelsOut);
% end
% 
% function col = colorsEnforce(i, palette)
% col = palette( mod(i-1, size(palette,1)) + 1, : );
% end
% 
% function u = metricUnit(met)
% if startsWith(met,'Emission','IgnoreCase',true)
%     u = 'MtCO2Eq';
% elseif startsWith(met,'Area','IgnoreCase',true)
%     u = 'km^2';
% elseif startsWith(met,'Water','IgnoreCase',true)
%     u = 'Million m^3';
% else
%     u = '';
% end
% end
% 
% 
% 
% % 
% % function compare_cities_results(cityStructs, cityNames, baseCol, targetCol)
% % % השוואת ערים – ערכים כוללים + פירוק פליטות לפי סקטורים, כולל פלוטים.
% % % INPUTS
% % %   cityStructs : {ResultsDataBase_BeerSheva, ResultsDataBase_Rashlaz, ...}
% % %   cityNames   : {'Beer-Sheva','Rishon LeZion', ...}
% % %   baseCol     : אינדקס שנת בסיס (למשל 1 עבור 2019)
% % %   targetCol   : אינדקס שנת יעד (למשל 2050)
% % 
% % assert(iscell(cityStructs) && iscell(cityNames) && numel(cityStructs)==numel(cityNames), ...
% %     'cityStructs ו-cityNames חייבים להיות באותו גודל ובהתאמה');
% % nCities   = numel(cityStructs);
% % scenarios = {'BAU','Moderate','Advanced'};
% % 
% % %% צבעים
% % colorsEm = [
% %    0.72, 0.27, 1.00;
% %    0.49, 0.18, 0.56;
% %    0.93, 0.69, 0.13;
% %    0.51, 0.37, 0.01;
% %    0.29, 0.89, 0.69;
% %    0.47, 0.67, 0.19;
% %    0.85, 0.33, 0.10;
% %    0.64, 0.08, 0.18;
% %    0.30, 0.75, 0.93;
% %    0.00, 0.45, 0.74;
% %    0.00, 1.00, 0.74 ];
% % colorsArea = [
% %    0.47, 0.67, 0.19;
% %    0.29, 0.89, 0.69;
% %    0.85, 0.33, 0.10;
% %    0.72, 0.27, 1.00 ];
% % colorsWater = [
% %    0.10, 0.31, 0.50;
% %    0.00, 0.45, 0.74;
% %    0.46, 0.72, 0.89;
% %    0.92, 0.93, 0.93;
% %    0.72, 0.27, 1.00 ];
% % 
% % %% --------- 1) Totals: Base vs Target ---------
% % metrics = {'Emission_Local','Emission_Global','Emission_Total', ...
% %            'Area_Local','Area_Global','Area_Total', ...
% %            'Water_Local','Water_Global','Water_Total'};
% % 
% % dataTotals = nan(nCities, numel(scenarios), numel(metrics), 2); % city × scen × metric × {base,target}
% % 
% % for c = 1:nCities
% %     RDB = cityStructs{c};
% %     if ~isfield(RDB, 'TotalResults') || ~istable(RDB.TotalResults)
% %         warning('(%s) חסרה TotalResults – דילוג.', cityNames{c});
% %         continue;
% %     end
% %     TR = RDB.TotalResults;
% %     rn = string(TR.Properties.RowNames);
% % 
% %     for s = 1:numel(scenarios)
% %         sc = scenarios{s};
% %         for m = 1:numel(metrics)
% %             met    = metrics{m};
% %             needle = string(compose('%s - %s', sc, strrep(met,'_',' ')));
% %             rowKey = startsWith(rn, needle, 'IgnoreCase', true);
% %             if ~any(rowKey), rowKey = contains(rn, needle, 'IgnoreCase', true); end
% %             if any(rowKey)
% %                 trRow = TR(find(rowKey,1), :);
% %                 dataTotals(c,s,m,1) = safeGetCol(trRow, baseCol);
% %                 dataTotals(c,s,m,2) = safeGetCol(trRow, targetCol);
% %             end
% %         end
% %     end
% % end
% % 
% % for m = 1:numel(metrics)
% %     met = metrics{m};
% %     % Base
% %     fig = figure('Name',['Totals - ',met,' (Base)'],'Color','w','Units','normalized','Position',[0.1 0.1 0.6 0.45]);
% %     set(fig,'SizeChangedFcn',@(src,evt) resizeFonts(src));
% %     tiledlayout(1,1,'Padding','compact'); nexttile;
% %     Y = squeeze(dataTotals(:, :, m, 1)); % cities × scenarios
% %     bar(Y); grid on; box off;
% %     title(sprintf('%s – Base', strrep(met,'_',' ')));
% %     ylabel(metricUnit(met));
% %     set(gca,'XTick',1:nCities,'XTickLabel',cityNames,'XTickLabelRotation',18);
% %     legend(scenarios,'Location','bestoutside');
% % 
% %     % Target
% %     fig = figure('Name',['Totals - ',met,' (Target)'],'Color','w','Units','normalized','Position',[0.1 0.1 0.6 0.45]);
% %     set(fig,'SizeChangedFcn',@(src,evt) resizeFonts(src));
% %     tiledlayout(1,1,'Padding','compact'); nexttile;
% %     Y = squeeze(dataTotals(:, :, m, 2));
% %     bar(Y); grid on; box off;
% %     title(sprintf('%s – Target', strrep(met,'_',' ')));
% %     ylabel(metricUnit(met));
% %     set(gca,'XTick',1:nCities,'XTickLabel',cityNames,'XTickLabelRotation',18);
% %     legend(scenarios,'Location','bestoutside');
% % end
% % 
% % %% --------- 2) פירוק פליטות לפי סקטורים (Base & Target) עם Y אחיד ---------
% % for s = 1:numel(scenarios)
% %     % PASS 1 – איסוף כל ה-y לכל הערים כדי לקבוע ylim אחיד
% %     yCells      = cell(1,nCities);
% %     labelCells  = cell(1,nCities);
% %     baseRowOrder = [];
% %     for c = 1:nCities
% %         RDB = cityStructs{c};
% %         [tbl, rowLabels] = getScenarioEmissionTable(RDB, scenarios{s});
% %         if isempty(tbl), continue; end
% %         if isempty(baseRowOrder), baseRowOrder = rowLabels; end
% %         [tbl, rowLabels] = reorderToMatch(tbl, rowLabels, baseRowOrder);
% %         yCells{c}     = [tbl{1:11, baseCol}, tbl{1:11, targetCol}]; % 11×2
% %         labelCells{c} = rowLabels;
% %     end
% %     % מקסימום לכל הפיגורה
% %     yMax = 0;
% %     for c = 1:nCities
% %         if ~isempty(yCells{c})
% %             yMax = max(yMax, max(yCells{c}(:)));
% %         end
% %     end
% %     ylimVals = [0, padTop(yMax)];
% % 
% %     % PASS 2 – ציור
% %     fig = figure('Name',['Emissions by Sectors – ',scenarios{s}], ...
% %                  'Color','w','Units','normalized','Position',[0.05 0.1 0.9 0.65]);
% %     set(fig,'SizeChangedFcn',@(src,evt) resizeFonts(src));
% %     t = tiledlayout(ceil(nCities/2), 2, 'TileSpacing','compact','Padding','compact');
% %     title(t, ['Emissions by Sectors (',scenarios{s},') – Base vs Target']);
% % 
% %     for c = 1:nCities
% %         if isempty(yCells{c}), nexttile; axis off; continue; end
% %         y          = yCells{c};
% %         rowLabels  = labelCells{c};
% %         ax = nexttile;
% %         b = bar(categorical({'Base','Target'}), y', 'stacked'); hold(ax,'on');
% %         for i = 1:min(numel(b), size(colorsEm,1)), set(b(i),'FaceColor',colorsEnforce(i, colorsEm)); end
% %         ylim(ax, ylimVals);
% %         title(ax, cityNames{c});
% %         ylabel(ax, 'MtCO2Eq'); grid(ax,'on'); box(ax,'off');
% %         lg = legend(ax, flip(b), flip(rowLabels(1:11)), 'NumColumns',2, 'Location','southoutside');
% %         lg.ItemTokenSize = [14,14];
% %         xtickangle(ax, 0);
% %     end
% % end
% % 
% % %% --------- 3) חשמל (Local/Global/Total) – Y אחיד בשני ה-tiles ---------
% % elecLocalIdx  = 1;
% % elecGlobalIdx = 2;
% % 
% % for s = 1:numel(scenarios)
% %     Ebase = nan(nCities, 3);  % [Local, Global, Total]
% %     Etarg = nan(nCities, 3);
% %     for c = 1:nCities
% %         [tbl, ~] = getScenarioEmissionTable(cityStructs{c}, scenarios{s});
% %         if isempty(tbl) || size(tbl,1) < max(elecGlobalIdx, elecLocalIdx), continue; end
% %         eL_b = tbl{elecLocalIdx,  baseCol};   eG_b = tbl{elecGlobalIdx,  baseCol};
% %         eL_t = tbl{elecLocalIdx,  targetCol}; eG_t = tbl{elecGlobalIdx,  targetCol};
% %         Ebase(c,:) = [eL_b, eG_b, eL_b+eG_b];
% %         Etarg(c,:) = [eL_t, eG_t, eL_t+eG_t];
% %     end
% %     yMax = max([Ebase(:); Etarg(:)],[],'omitnan');
% %     ylimVals = [0, padTop(yMax)];
% % 
% %     fig = figure('Name',['Electricity – ',scenarios{s}],'Color','w','Units','normalized','Position',[0.1 0.1 0.8 0.45]);
% %     set(fig,'SizeChangedFcn',@(src,evt) resizeFonts(src));
% %     tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
% % 
% %     ax1 = nexttile; bar(ax1, Ebase); grid(ax1,'on'); box(ax1,'off');
% %     ylim(ax1, ylimVals);
% %     title(ax1, ['Electricity (Base) – ',scenarios{s}]); ylabel(ax1,'MtCO2Eq');
% %     set(ax1,'XTick',1:nCities,'XTickLabel',cityNames,'XTickLabelRotation',18);
% %     legend(ax1, {'Local','Global','Total'},'Location','bestoutside');
% % 
% %     ax2 = nexttile; bar(ax2, Etarg); grid(ax2,'on'); box(ax2,'off');
% %     ylim(ax2, ylimVals);
% %     title(ax2, ['Electricity (Target) – ',scenarios{s}]); ylabel(ax2,'MtCO2Eq');
% %     set(ax2,'XTick',1:nCities,'XTickLabel',cityNames,'XTickLabelRotation',18);
% %     legend(ax2, {'Local','Global','Total'},'Location','bestoutside');
% % end
% % 
% % %% --------- 4) Heatmap סיכום ---------
% % EtotalTarget = squeeze(dataTotals(:,:, strcmp(metrics,'Emission_Total'), 2)); % cities × scenarios
% % fig = figure('Name','Heatmap – Emission Total (Target)','Color','w','Units','normalized','Position',[0.15 0.2 0.65 0.55]);
% % set(fig,'SizeChangedFcn',@(src,evt) resizeFonts(src));
% % h = heatmap(categorical(cityNames), categorical(scenarios), EtotalTarget');
% % h.Title = 'Emission Total – Target Year';
% % h.XLabel = 'Cities'; h.YLabel = 'Scenario';
% % h.CellLabelFormat = '%.3g';
% % 
% % end % compare_cities_results
% % 
% % 
% % 
% % 
% % 
% % 
% % 
% % 
% % 
% % 
% % function val = safeGetCol(t, idx)
% % if idx >= 1 && idx <= width(t), val = t{1, idx}; else, val = NaN; end
% % end
% % 
% % function [tbl, rowLabels] = getScenarioEmissionTable(RDB, scenarioName)
% % tbl = []; rowLabels = [];
% % try
% %     switch lower(scenarioName)
% %         case 'bau'
% %             if isfield(RDB,'BAU_RDB') && istable(RDB.BAU_RDB.TotalEmission1)
% %                 tbl = RDB.BAU_RDB.TotalEmission1;
% %             end
% %         case 'moderate'
% %             if isfield(RDB,'Moderate_RDB') && istable(RDB.Moderate_RDB.TotalEmission2)
% %                 tbl = RDB.Moderate_RDB.TotalEmission2;
% %             end
% %         case 'advanced'
% %             if isfield(RDB,'Advanced_RDB') && istable(RDB.Advanced_RDB.TotalEmission3)
% %                 tbl = RDB.Advanced_RDB.TotalEmission3;
% %             end
% %     end
% %     if ~isempty(tbl)
% %         if ~isempty(tbl.Properties.RowNames)
% %             rowLabels = string(tbl.Properties.RowNames);
% %             rowLabels = strrep(rowLabels,'Local','Domestic'); % אופציונלי להצגה
% %         else
% %             rowLabels = string( (1:height(tbl))' );
% %         end
% %     else
% %         warning('Missing TotalEmission table for scenario "%s".', scenarioName);
% %     end
% % catch ME
% %     warning('getScenarioEmissionTable: %s', ME.message);
% % end
% % end
% % 
% % function [tblOut, labelsOut] = reorderToMatch(tblIn, labelsIn, targetLabels)
% % labelsIn     = string(labelsIn);
% % targetLabels = string(targetLabels);
% % tblOut       = array2table(nan(numel(targetLabels), width(tblIn)));
% % tblOut.Properties.VariableNames = tblIn.Properties.VariableNames;
% % labelsOut    = targetLabels;
% % for i = 1:numel(targetLabels)
% %     k = find(labelsIn==targetLabels(i),1);
% %     if ~isempty(k), tblOut{i, :} = tblIn{k, :}; end
% % end
% % tblOut.Properties.RowNames = cellstr(labelsOut);
% % end
% % 
% % function col = colorsEnforce(i, palette)
% % col = palette( mod(i-1, size(palette,1)) + 1, : );
% % end
% % 
% % function u = metricUnit(met)
% % if startsWith(met,'Emission','IgnoreCase',true)
% %     u = 'MtCO2Eq';
% % elseif startsWith(met,'Area','IgnoreCase',true)
% %     u = 'km^2';
% % elseif startsWith(met,'Water','IgnoreCase',true)
% %     u = 'Million m^3';
% % else
% %     u = '';
% % end
% % end
% % 
% % function yTop = padTop(yMax)
% % if isempty(yMax) || isnan(yMax), yTop = 1; else, yTop = ceil(yMax*1.10); end
% % end
% % 
% % function resizeFonts(fig)
% % % התאמת גודל פונטים באופן פרופורציונלי לגודל החלון
% % ax = findall(fig,'Type','axes');
% % % רוחב החלון בפיקסלים (Position(3)); אם ב-normalized – MATLAB ממיר אוטומטית.
% % base = 9;                           % מינימום
% % scale = max(base, round(fig.Position(3)/90));
% % for i = 1:numel(ax)
% %     ax(i).FontSize = scale;
% %     % כותרים/מקרא
% %     if isfield(ax(i),'Title') && ~isempty(ax(i).Title), ax(i).Title.FontSize = scale+2; end
% % end
% % lg = findall(fig,'Type','legend');
% % for i = 1:numel(lg), lg(i).FontSize = max(base-1, scale-1); end
% % end
