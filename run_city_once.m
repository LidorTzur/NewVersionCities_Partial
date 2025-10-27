
% run_city_once - מריץ את המודל עבור עיר אחת ושומר את הפלטים
% קלטים:
%   excelFile - קובץ האקסל עם הנתונים של העיר
% פלט:
%   RDB       - ResultsDataBase של העיר
% =====================
% 1. קריאה לנתוני קונפיגורציה
% =====================
[OutDir] = fullfile('C:\Users','צור','Documents','תואר שני','תזה','קיימות ערים','פלטים מהמודל');


% משתנה גלובלי או ב-base workspace כדי שהסקריפטים שלך יזהו
% assignin('base','Data', excelFile); 
% assignin('base', 'cityCode',  cityCode);
% assignin('base', 'scenariosFile',  scenariosFile);

% =====================
% 2. הרצת ה-MAIN הקיים שלך
% =====================
createPath;
preparation;
runningSteps;

% כאן מניחים ש-ResultsDataBase נוצר ע"י הסקריפטים שלך
RDB = ResultsDataBase;  

% =====================
% 3. כתיבת פלטים לאקסלים
% =====================
if ~exist(OutDir,'dir')
    mkdir(OutDir);
end

fnames = { ...
    {'TotalResults'           , RDB.TotalResults} ;
    {'TotalEmission_BAU'      , RDB.BAU_RDB.TotalEmission1} ;
    {'TotalEmission_Moderate' , RDB.Moderate_RDB.TotalEmission2} ;
    {'TotalEmission_Advanced' , RDB.Advanced_RDB.TotalEmission3} ;
};

for k = 1:numel(fnames)
    baseName = fnames{k}{1};
    T        = fnames{k}{2};

    % שמירה בתיקייה הנוכחית
    file1 = sprintf('Results_Plots\\%s_%s.xlsx', baseName, cityCode);
    writetable(T, file1, 'WriteRowNames', true);

    % שמירה בתיקייה הייעודית
    file2 = fullfile(OutDir, sprintf('%s_%s.xlsx', baseName, cityCode));
    writetable(T, file2, 'WriteRowNames', true);
end

clear file2 file1 baseName T k fnames
