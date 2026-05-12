% % % Read Files
% % createPath;
% % % Preparations
% % preparation;
% % % Calculate emissions by specific steps
% % runningSteps;
% 
createPath;

% % cities = {
% %     "BeerSheva" , "Data\BeerSheva.xlsx"  , "Scenarios_BeerSheva.xlsx"
% %     "Tlv" , "Data\Tlv.xlsx"  , "Scenarios_Tlv.xlsx"
% %     "BeitShemesh" , "Data\BeitShemesh.xlsx"  , "Scenarios_BeitShemesh.xlsx"
% %     };
%
% 
% % 1. Load existing data or initialize new structure
% if exist('AllCities.mat', 'file')
%     fprintf('Accessing existing AllCities.mat file...\n');
%     m = matfile('AllCities.mat', 'Writable', true);
%     AllCities = m.AllCities; 
% else
%     fprintf('No previous data found. Creating a new structure.\n');
%     AllCities = struct(); 
%     save('AllCities.mat', 'AllCities', '-v7.3'); 
%     m = matfile('AllCities.mat', 'Writable', true);
% end
% 
%
% % 2. Main Loop
% for i = 1:size(cities,1)
%     cityCode      = cities{i,1};
%     excelFile     = cities{i,2};
%     scenariosFile = cities{i,3};
% 
%     fprintf('\n>>> Processing City: %s (%d of %d) <<<\n', cityCode, i, size(cities,1));
% 
%     % Execute the single city logic (creates the 'RDB' variable)
%     AllCities = m.AllCities;
%     run_city_once; 
% 
%     % 3. MERGING LOGIC: Add new results without deleting old ones
%     if isfield(AllCities, cityCode)
%         fprintf('City %s already exists in AllCities. Merging new fields...\n', cityCode);
% 
%         % Get names of all new result fields (e.g., BAU_RDB, Moderate_RDB...)
%         newFields = fieldnames(RDB);
% 
%         for f = 1:numel(newFields)
%             fieldName = newFields{f};
%             % This line adds/updates the specific field (like 'BAU_RDB') 
%             % inside the city, but leaves other fields (like 'Sensitivity_RDB') untouched.
%             AllCities.(cityCode).(fieldName) = RDB.(fieldName);
%         end
%     else
%         % If city doesn't exist yet, create it
%         fprintf('Adding new city entry for %s.\n', cityCode);
%         AllCities.(cityCode) = RDB;
%     end
% 
%     % --- השורה החדשה והחשובה ביותר ---
%     % 4. שמירה "נקודתית" - מעדכן רק את המשתנה AllCities בתוך הקובץ
%     % בזכות matfile, מטלב תעשה את זה הרבה יותר מהר משמירה רגילה
%     m.AllCities = AllCities; 
%     fprintf('City %s synced to disk.\n', cityCode);
% 
% end
% 
% %  % 4. Incremental Save (Safety first!)
% % save('AllCities.mat', 'AllCities');
% % fprintf('Saved: AllCities now contains %d cities.\n', numel(fieldnames(AllCities)));
% 
% % Final variables to keep
% %clearvars -except AllCities Years
% fprintf('\nProcess completed successfully.\n');

%createPath;

cities = {
    "RishonLeZion"     , "Data\RishonLeZion.xlsx" , "Scenarios_Rishon.xlsx"
    "BeerSheva"    , "Data\BeerSheva.xlsx"    , "Scenarios_BeerSheva.xlsx"
    "BeitShemesh" , "Data\BeitShemesh.xlsx"  , "Scenarios_BeitShemesh.xlsx"
    "Tlv" , "Data\Tlv.xlsx"  , "Scenarios_Tlv.xlsx"

    "Modiin"     , "Data\Modiin.xlsx" , "Scenarios_Modiin.xlsx"
    "Afula"    , "Data\Afula.xlsx"     , "Scenarios_Afula.xlsx"
    "Raanana" , "Data\Raanana.xlsx"  , "Scenarios_Raanana.xlsx"
    "Hadera" , "Data\Hadera.xlsx"  , "Scenarios_Hadera.xlsx"
    "KiryatGat" , "Data\KiryatGat.xlsx"  , "Scenarios_KiryatGat.xlsx"
    "MazkeretBatya" , "Data\MazkeretBatya.xlsx"  , "Scenarios_MazkeretBatya.xlsx"     
    };


% cities = {
%      "BeerSheva"    , "Data\BeerSheva.xlsx"    , "Scenarios_BeerSheva.xlsx"
%     };

% 1. טעינה חד-פעמית לזיכרון (RAM) - זה מהיר מאוד
if exist('AllCities.mat', 'file')
    fprintf('Loading AllCities.mat into memory...\n');
    temp = load('AllCities.mat', 'AllCities');
    AllCities = temp.AllCities;
else
    fprintf('No previous data found. Creating a new structure.\n');
    AllCities = struct(); 
end

% 2. Main Loop
for i = 1:size(cities,1)
    cityCode      = cities{i,1};
    excelFile     = cities{i,2};
    scenariosFile = cities{i,3};

    fprintf('\n>>> Processing City: %s (%d of %d) <<<\n', cityCode, i, size(cities,1));

    % מריץ את החישוב - יוצר RDB בזיכרון
    run_city_once; 

    % 3. MERGING LOGIC בזיכרון (בלי לגשת לדיסק!)
    if isfield(AllCities, cityCode)
        fprintf('City %s already exists. Merging fields...\n', cityCode);
        newFields = fieldnames(RDB);
        for f = 1:numel(newFields)
            fieldName = newFields{f};
            AllCities.(cityCode).(fieldName) = RDB.(fieldName);
        end
    else
        fprintf('Adding new city entry for %s.\n', cityCode);
        AllCities.(cityCode) = RDB;
    end

    % טיפ: אם הריצה ארוכה מאוד ואת מפחדת מקריסה, אפשר להוסיף כאן שמירה זמנית, 
    % אבל זה מה שיאט אותך. עדיף לשמור בסוף.
end

% 4. שמירה סופית לדיסק - פעם אחת בלבד לכל הפרויקט
fprintf('\n>>> Saving all cities to disk... <<<\n');
save('AllCities.mat', 'AllCities', '-v7.3', '-nocompression'); 

fprintf('\nProcess completed successfully.\n');