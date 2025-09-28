% % Read Files
% createPath;
% % Preparations
% preparation;
% % Calculate emissions by specific steps
% runningSteps;

createPath;
cities = {
    "RishonLeZion"     , "Data\RishonLeZion.xlsx" , "Scenarios_Rishon.xlsx"
    "BeerSheva"    , "Data\BeerSheva.xlsx"    , "Scenarios_BeerSheva.xlsx"
    "BeitShemesh" , "Data\BeitShemesh.xlsx"  , "Scenarios_BeitShemesh.xlsx"
    "Tlv" , "Data\Tlv.xlsx"  , "Scenarios_Tlv.xlsx"
    };

% cities = {
%     "BeitShemesh" , "Data\BeitShemesh.xlsx"  , "Scenarios_BeitShemesh.xlsx"
%     };

% מבנה שיאחסן את כל התוצאות
AllCities = struct();

for i = 1:size(cities,1)
    cityCode  = cities{i,1};
    excelFile = cities{i,2};
    scenariosFile= cities{i,3};

    fprintf('\n=== מריץ את העיר: %s ===\n', cityCode);

    % הרצה לעיר אחת
    run_city_once;

    % הוספה ל-struct ראשי לפי City_Tag
    AllCities.(cityCode) = RDB;
end

% שמירה של כל הערים בקובץ אחד
save('AllCitiesResults.mat', 'AllCities');