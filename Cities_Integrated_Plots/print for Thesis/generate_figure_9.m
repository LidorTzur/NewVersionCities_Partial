% --- סקריפט סופי ומתוקן ליצירת איור 9 ---
% הרכב מקומי-עולמי של טביעת הרגל הפחמנית (2019 מול 2040 Advanced)

% 1. קבלת רשימת היישובים באמצעות פונקציית העזר שלך
cats = getCityCategorical(AllCities);
city_names = categories(cats)'; 
num_cities = length(city_names);

% 2. חישוב קצב גידול אוכלוסייה לצורך מיון לפי גידול האוכלוסייה החזוי
pop_growth = zeros(num_cities, 1);
for i = 1:num_cities
    cName = city_names{i};
    C = AllCities.(cName);
    
    % שליפת האוכלוסייה מתוך BAU_RDB.population (שורה 3)
    pop_table = C.BAU_RDB.population;
    popsRow = pop_table{3, :};
    if iscell(popsRow)
        popsRow = cellfun(@str2double, popsRow);
    end
    
    pop_2019 = popsRow(1);
    pop_2040 = popsRow(end);
    pop_growth(i) = (pop_2040 - pop_2019) / pop_2019;
end

% מיון מחדש של היישובים לפי גידול האוכלוסייה (מהנמוך לגבוה)
[~, sorted_idx] = sort(pop_growth);
sorted_cities = city_names(sorted_idx);

% 3. שליפת נתוני פחמן (מקומי ועולמי) עבור 2019 ו-2040 Advanced מתוך TotalResults
plot_matrix = zeros(num_cities * 2, 2); % עמודה 1: מקומי, עמודה 2: עולמי
x_labels = cell(num_cities * 2, 1);

for i = 1:num_cities
    cName = sorted_cities{i};
    res = AllCities.(cName).TotalResults;
    
    if istable(res)
        res_data = table2array(res);
    else
        res_data = res;
    end
    
    col_2019 = 1;
    col_2040 = 22;
    
    local_19 = double(res_data(1, col_2019));
    global_19 = double(res_data(4, col_2019));
    total_19 = local_19 + global_19;
    
    local_40 = double(res_data(3, col_2040));
    global_40 = double(res_data(6, col_2040));
    total_40 = local_40 + global_40;
    
    p_local_19  = (local_19 / total_19) * 100;
    p_global_19 = (global_19 / total_19) * 100;
    
    p_local_40  = (local_40 / total_40) * 100;
    p_global_40 = (global_40 / total_40) * 100;
    
    idx_2019 = 2*i - 1;
    idx_2040 = 2*i;
    
    plot_matrix(idx_2019, :) = [p_local_19, p_global_19];
    plot_matrix(idx_2040, :) = [p_local_40, p_global_40];
    
    x_labels{idx_2019} = sprintf('%s (19)', cName);
    x_labels{idx_2040} = sprintf('%s (40A)', cName);
end

% 4. בניית הגרף
figure('Color', 'white', 'Position', [100, 100, 1400, 680]);

% התאמת מיקום הגרף כדי להשאיר מספיק מרווח למעלה
axes('Position', [0.08, 0.20, 0.88, 0.62]); 

hb = bar(plot_matrix, 'stacked', 'BarWidth', 0.85);

hb(1).FaceColor = [0.2 0.5 0.7]; % מקומי
hb(2).FaceColor = [0.8 0.4 0.2]; % עולמי

% יצירת כותרת והגדרת ה-FontSize והמיקום בצורה מפורשת דרך האובייקט שלה
hTitle = title('Figure 9: Local-global composition of the carbon footprint (2019 vs 2040 Advanced)');
set(hTitle, 'FontSize', 26, 'FontWeight', 'bold', 'Units', 'normalized', 'Position', [0.5, 1.30, 0]);

% מקרא שמופיע מתחת לכותרת הראשית
legend({'Local', 'Global'}, ...
    'Location', 'northoutside', 'Orientation', 'horizontal', 'FontSize', 12);

ylabel('Share of Carbon Footprint (%)', 'FontSize', 14, 'FontWeight', 'bold');

set(gca, 'XTick', 1:(num_cities*2), 'XTickLabel', x_labels, 'FontSize', 10, 'FontWeight', 'bold');
xtickangle(50); % סיבוב שמות הערים ל-45 מעלות

ylim([0 100]);
grid on;
box on;

% 5. הוספת קווים מקווקוים שחורגים לחלוטין החוצה מגבולות הגרף למעלה ולמטה
hold on;
for k = 2:2:(num_cities*2 - 2)
    x_line = k + 0.5;
    h_line = line([x_line, x_line], [-15, 115], ...  
        'Color', [0.25 0.25 0.25], ...             
        'LineStyle', '--', ...
        'LineWidth', 1.5, ...
        'HandleVisibility', 'off');                
    
    set(h_line, 'Clipping', 'off'); 
end

% 6. הוספת תוויות מספרים על הברים
for col = 1:size(plot_matrix, 1)
    cum_y = 0;
    for row = 1:size(plot_matrix, 2)
        val = plot_matrix(col, row);
        if val > 5 
            y_pos = cum_y + (val / 2);
            text(col, y_pos, sprintf('%.1f%%', val), ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'Color', 'white', ...
                'FontSize', 9.5, ...         
                'FontWeight', 'bold', ...
                'Rotation', 30);             
        end
        cum_y = cum_y + val;
    end
end
hold off;