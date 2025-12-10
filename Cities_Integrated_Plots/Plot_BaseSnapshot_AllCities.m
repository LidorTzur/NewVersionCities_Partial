%% =====================================================================
%  Plot_BaseSnapshot_AllCities.m
%  תמונת בסיס: פליטות אבסולוטיות ופר קפיטה לשנת 2019 (BAU)
%% =====================================================================

addpath('helpers');

cityNames = fieldnames(AllCities);
cities    = struct2cell(AllCities);
nCities   = numel(cities);

scenario = 'BAU';    % תרחיש בסיס
baseCol  = 1;        % שנת 2019

%% --- מפה של צבעים עבור כל עיר ---
cityColors = lines(nCities);   % צבעים שונים לכל עיר

%% --- איסוף נתונים לכל עיר ---
AbsValues = zeros(nCities,1);
PCValues  = zeros(nCities,1);

for c = 1:nCities
    C = cities{c};
    tbl = getScenarioTable(C, scenario);

    % סה"כ פליטות (השורה האחרונה בטבלה)
    totalRowName = tbl.Properties.RowNames{end};
    AbsValues(c) = tbl{totalRowName, baseCol};

    % אוכלוסייה במיליונים
    pop = getPopMillionsByCol(C, baseCol, scenario, tbl.Properties.VariableNames);
    PCValues(c) = AbsValues(c) ./ max(pop, eps);
end

%% --- יצירת חלון גרפים ---
fig = figure('Name','Base Snapshot – 2019 BAU', ...
             'Color','w','Units','pixels', ...
             'Position',[200 150 1200 550]);

tl = tiledlayout(fig, 1, 2, 'TileSpacing','compact','Padding','compact');


%% =====================================================================
%  גרף שמאל: פליטות אבסולוטיות
%% =====================================================================

axAbs = nexttile(tl);

bAbs = bar(axAbs, categorical(cityNames), AbsValues, 'BarWidth', 0.7);
bAbs.FaceColor = 'flat';   % חשוב כדי שכל עיר תקבל צבע שונה

for c = 1:nCities
    bAbs.CData(c,:) = cityColors(c,:);
end

ylabel(axAbs,'MtCO2eq');
title(axAbs,'Absolute Emissions – 2019 (BAU)');
grid(axAbs,'on'); 
axAbs.Box = 'off';
axAbs.FontSize = 10;
set(axAbs,'XTickLabelRotation',45);


%% =====================================================================
%  גרף ימין: פליטות פר קפיטה
%% =====================================================================

axPC = nexttile(tl);

bPC = bar(axPC, categorical(cityNames), PCValues, 'BarWidth', 0.7);
bPC.FaceColor = 'flat';  % חשוב כדי לאפשר צבעי עיר

for c = 1:nCities
    bPC.CData(c,:) = cityColors(c,:);
end

ylabel(axPC,'tCO2e per capita');
title(axPC,'Per Capita Emissions – 2019 (BAU)');
grid(axPC,'on'); 
axPC.Box = 'off';
axPC.FontSize = 10;
set(axPC,'XTickLabelRotation',45);


%% =====================================================================
%  כותרת עליונה לכל החלון
%% =====================================================================

try
    title(tl, 'Base Snapshot – Emissions of All Cities (2019, BAU)');
catch
    sgtitle('Base Snapshot – Emissions of All Cities (2019, BAU)');
end


%% =====================================================================
%  שמירת הגרפים בתיקייה
%% =====================================================================

outputDir = 'C:\Users\צור\Documents\MATLAB\NewVersionCities_Partial\Results_Plots\Base_Snapshot';
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

fileNamePNG = fullfile(outputDir, 'BaseSnapshot_AllCities_2019_BAU.png');
fileNameFIG = fullfile(outputDir, 'BaseSnapshot_AllCities_2019_BAU.fig');

saveas(fig, fileNamePNG);
saveas(fig, fileNameFIG);

disp(['✔ הגרפים נשמרו ב: ' outputDir]);
disp('✔ סיימתי להפיק את תמונת הבסיס של כל הערים (2019 BAU).');
