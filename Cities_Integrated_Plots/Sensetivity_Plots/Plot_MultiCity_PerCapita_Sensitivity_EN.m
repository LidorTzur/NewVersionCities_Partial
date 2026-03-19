%% =====================================================================
%  Plot_MultiCity_PerCapita_HighPrecision.m
%  Fixed: High precision labels (6 decimal places) to show tiny changes.
%% =====================================================================

allCityNames = fieldnames(AllCities);
allCityNames = {'Tlv', 'RishonLeZion', 'BeerSheva', 'Raanana', 'Modiin','Hadera', 'Afula', 'KiryatGat','BeitShemesh', 'MazkeretBatya'};

%allCityNames = ["BeerSheva", "Tlv", "BeitShemesh"];
nCities = numel(allCityNames);
targetYearIdx = 32; % שנת 2050

firstCity = allCityNames{1};
SR_ref = AllCities.(firstCity).Sensitivity_RDB;
scenNames = SR_ref.RelevantScenarioNames;
nScens = numel(scenNames);

outputDir = 'Results_Plots\Scenario_Comparisons_PerCapita';
if ~exist(outputDir, 'dir'), mkdir(outputDir); end

for s = 1:nScens
    currentScen = scenNames{s};
    pcImpactValues = zeros(nCities, 1);
    
    fprintf('\n--- Analyzing Scenario: %s ---\n', currentScen);
    
    for i = 1:nCities
        cityName = allCityNames{i};
        C = AllCities.(cityName);
        SR = C.Sensitivity_RDB;
        
        % חישוב ההפרש בטונות
        baseTotal = SR.EmissionByScenario{1, s};
        plusTotal = SR.EmissionByScenario{2, s};
        deltaTons = plusTotal - baseTotal;
        
        % שליפת אוכלוסייה (במיליונים)
        if isfield(C, 'BAU_RDB') && isfield(C.BAU_RDB, 'population')
            P_table = C.BAU_RDB.population;
            popsRow = P_table{3,:};
            if iscell(popsRow), popsRow = cellfun(@str2double, popsRow); end
            popM = popsRow(targetYearIdx);
        else
            popM = 1; 
        end
        
        % חישוב ק"ג לנפש: (טונות * 1000) חלקי (מיליוני תושבים * 10^6)
        pcImpactValues(i) = (deltaTons * 1000) / (popM * 1e6);
        
        % הדפסה למעקב ב-Command Window
        fprintf('City: %-15s | Delta Tons: %10.6f | kg/Capita: %10.8f\n', ...
            cityName, deltaTons, pcImpactValues(i));
    end
    
    % --- יצירת הגרף ---
    fig = figure('Name', ['PerCapita - ' currentScen], 'Color', 'w', 'Position', [100 100 900 600]);
    ax = axes(fig);
    [sortedImpact, sortIdx] = sort(pcImpactValues, 'descend');
    sortedCityNames = allCityNames(sortIdx);
    
    b = bar(ax, categorical(sortedCityNames, sortedCityNames), sortedImpact, 'FaceColor', [0.46 0.67 0.19]);
    grid on;
    
    ylabel('Impact (kgCO2e per capita)', 'FontWeight', 'bold');
    title(['Per-Capita Sensitivity: ' currentScen], 'FontSize', 14);
    
    % --- הגדרת תוויות עם דיוק גבוה ---
    xtips = b.XEndPoints;
    ytips = b.YEndPoints;
    for k = 1:numel(sortedImpact)
        % שימוש ב-6 ספרות אחרי הנקודה להצגת שינויים קטנים
        labelStr = sprintf('%.6f', sortedImpact(k)); 
        text(xtips(k), ytips(k), labelStr, 'VerticalAlignment', 'bottom', ...
             'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 8);
    end
    
    drawnow;
    saveas(fig, fullfile(outputDir, ['PerCapita_' strrep(currentScen,' ','_') '.png']));
end