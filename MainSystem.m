
createPath;

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
    "Rahat" , "Data\Rahat.xlsx"  , "Scenarios_Rahat.xlsx"
    "Sakhnin" , "Data\Sakhnin.xlsx"  , "Scenarios_Sakhnin.xlsx"        
    };

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