% 1. טעינת הנתונים והגדרות בסיס
data = [
    8.42,  227.82, 3181.47; % RishonLeZion
    9.64,  248.45, 2988.98; % BeerSheva
    9.63,  262.11, 2922.78; % Tlv
    10.05, 245.15, 3039.99; % Raanana
    9.27,  234.09, 3389.49; % Modiin
    8.66,  228.08, 3081.49; % Afula
    8.58,  229.60, 3011.72; % Hadera
    8.74,  224.57, 3107.19; % KiryatGat
    6.97,  213.57, 3009.54; % MazkeretBatya
    6.28,  182.47, 3035.21; % Rahat
    7.23,  175.79, 3034.79; % Sakhnin
    7.46,  193.40, 3332.01  % BeitShemesh
];

varnames = {'Carbon (tCO_2e/cap)', 'Water (m^3/cap)', 'Land (m^2/cap)'};

% הגדרת הטיפולוגיות לצבעים
groups = { 'Metropolises'; 'Metropolises'; 'Metropolises'; ...
           'Established Satellites'; 'Established Satellites'; ...
           'Growth Cities'; 'Growth Cities'; 'Growth Cities'; ...
           'Sectoral & Small'; 'Sectoral & Small'; 'Sectoral & Small'; 'Sectoral & Small' };

uniqueGroups = unique(groups, 'stable');
colors = [0, 0.4470, 0.7410;   % כחול עמוק
          0.8500, 0.3250, 0.0980; % כתום-אדום בולט
          0.9290, 0.6940, 0.1250; % צהוב-חרדל
          0.4940, 0.1840, 0.5560]; % סגול

% 2. יצירת מטריצה בפריסה המשלבת מקרא קומפקטי בצד
figure('Position', [100, 100, 950, 750], 'Color', 'w');

% פריסה של 3 שורות על 4 עמודות (העמודה ה-4 מוקדשת למקרא קומפקטי באמצע)
t = tiledlayout(3, 4, 'TileSpacing', 'tight', 'Padding', 'compact');

panel_grid = [1, 2, 3; 
              5, 6, 7; 
              9, 10, 11]; 

for i = 1:3
    for j = 1:3
        tile_num = panel_grid(i, j);
        nexttile(tile_num);
        hold on;
        
        if i == j
            % אלכסון: מלבן נקי לשם המשתנה
            rectangle('Position', [0, 0, 1, 1], 'FaceColor', [0.95 0.95 0.95], 'EdgeColor', [0.6 0.6 0.6], 'LineWidth', 1.2);
            text(0.5, 0.5, varnames{i}, 'HorizontalAlignment', 'center', ...
                 'VerticalAlignment', 'middle', 'FontWeight', 'bold', 'FontSize', 14, ...
                 'Color', [0.1 0.1 0.1], 'Units', 'normalized');
            set(gca, 'XTick', [], 'YTick', [], 'XColor', 'none', 'YColor', 'none');
            box off;
            
        else
            % תאים מחוץ לאלכסון: גרף פיזור מודגש
            x_data = data(:, j);
            y_data = data(:, i);
            
            for g = 1:length(uniqueGroups)
                idx = strcmp(groups, uniqueGroups{g});
                scatter(x_data(idx), y_data(idx), 70, colors(g,:), 'filled', ...
                        'MarkerEdgeColor', 'k', 'LineWidth', 0.8);
            end
            
            rho = compute_spearman(x_data, y_data);
            
            % מתאם מוגדל בולט
            text(0.05, 0.78, sprintf('\\rho = %.3f', rho), ...
                 'Units', 'normalized', 'FontSize', 16, 'FontWeight', 'bold', ...
                 'BackgroundColor', [1 1 1 0.9], 'EdgeColor', [0.5 0.5 0.5], ...
                 'LineWidth', 1, 'Margin', 4);
             
            set(gca, 'LineWidth', 1, 'FontSize', 10, 'Box', 'on', 'TickDir', 'in');
            
            if i == 3
                xlabel('', 'FontSize', 11); 
            else
                set(gca, 'XTickLabel', []);
            end
            
            if j == 1
                ylabel('', 'FontSize', 11); 
            else
                set(gca, 'YTickLabel', []);
            end
            
            grid on;
            set(gca, 'GridLineStyle', ':', 'GridColor', [0.7 0.7 0.7], 'GridAlpha', 0.6);
        end
        hold off;
    end
end

% 3. מלבן מקרא קומפקטי ומרוכז (ממוקם רק בשורה השנייה בעמודה ה-4)
nexttile(4); % משאיר את תאים 4 ו-12 ריקים ומאזנים
lgd_ax = nexttile(8, [1, 1]); 
hold on;
rectangle('Position', [0, 0, 1, 1], 'FaceColor', [0.98 0.98 0.98], 'EdgeColor', [0.5 0.5 0.5], 'LineWidth', 1.5);

% כותרת למלבן המקרא (מוגדלת)
text(lgd_ax, 0.5, 0.85, 'Typologies', 'HorizontalAlignment', 'center', 'FontSize', 13, 'FontWeight', 'bold');

% הוספת פריטי המקרא בטקסט מוגדל ובולט
y_pos = [0.64, 0.46, 0.28, 0.10];
for g = 1:length(uniqueGroups)
    plot(lgd_ax, 0.18, y_pos(g), 'o', 'MarkerSize', 8, ...
         'MarkerFaceColor', colors(g,:), 'MarkerEdgeColor', 'k', 'LineWidth', 0.9);
    text(lgd_ax, 0.32, y_pos(g), uniqueGroups{g}, 'FontSize', 11, ...
         'FontWeight', 'bold', 'VerticalAlignment', 'middle');
end

set(lgd_ax, 'XTick', [], 'YTick', [], 'XColor', 'none', 'YColor', 'none');
box off;
hold off;

% כותרת ראשית כוללת למעלה
title(t, 'Figure 4: Cross-indicator concordance across 12 localities', 'FontSize', 14, 'FontWeight', 'bold');

% 4. שמירה
outputFolder = 'C:\Users\צור\Documents\MATLAB\NewVersionCities_Partial\Results_Plots\Manual Plots';
if ~exist(outputFolder, 'dir'), mkdir(outputFolder); end
fullFilePath = fullfile(outputFolder, 'Figure4_CrossIndicator_CompactLegend.png');
print(gcf, fullFilePath, '-dpng', '-r300');
disp(['הגרף עם מלבן המקרא הקומפקטי נשמר בנתיב: ', fullFilePath]);

% --- פונקציות עזר ---
function rho = compute_spearman(x, y)
    rx = get_ranks(x);
    ry = get_ranks(y);
    rx_mean = mean(rx); ry_mean = mean(ry);
    numerator = sum((rx - rx_mean) .* (ry - ry_mean));
    denominator = sqrt(sum((rx - rx_mean).^2) * sum((ry - ry_mean).^2));
    if denominator == 0, rho = 0; else, rho = numerator / denominator; end
end

function r = get_ranks(v)
    [sorted_v, sortIdx] = sort(v);
    n = length(v); r = zeros(size(v)); i = 1;
    while i <= n
        j = i;
        while j < n && sorted_v(j+1) == sorted_v(i), j = j + 1; end
        if j > i, avg_rank = (i + j) / 2; r(sortIdx(i:j)) = avg_rank;
        else, r(sortIdx(i)) = i; end
        i = j + 1;
    end
end