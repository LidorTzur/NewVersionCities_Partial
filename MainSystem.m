% % Read Files
% createPath;
% % Preparations
% preparation;
% % Calculate emissions by specific steps
% runningSteps;

% createPath;
% cities = {
%     "RishonLeZion"     , "Data\RishonLeZion.xlsx" , "Scenarios_Rishon.xlsx"
%     "BeerSheva"    , "Data\BeerSheva.xlsx"    , "Scenarios_BeerSheva.xlsx"
%     "BeitShemesh" , "Data\BeitShemesh.xlsx"  , "Scenarios_BeitShemesh.xlsx"
%     "Tlv" , "Data\Tlv.xlsx"  , "Scenarios_Tlv.xlsx"
% 
%     "Modiin"     , "Data\Modiin.xlsx" , "Scenarios_Modiin.xlsx"
%     "Afula"    , "Data\Afula.xlsx"    , "Scenarios_Afula.xlsx"
%     "Raanana" , "Data\Raanana.xlsx"  , "Scenarios_Raanana.xlsx"
%     "Hadera" , "Data\Hadera.xlsx"  , "Scenarios_Hadera.xlsx"
%     "KiryatGat" , "Data\KiryatGat.xlsx"  , "Scenarios_KiryatGat.xlsx"
%     "MazkeretBatya" , "Data\MazkeretBatya.xlsx"  , "Scenarios_MazkeretBatya.xlsx"     
%     };


cities = {
    "BeerSheva" , "Data\BeerSheva.xlsx"  , "Scenarios_BeerSheva.xlsx"
    "RishonLeZion"     , "Data\RishonLeZion.xlsx" , "Scenarios_Rishon.xlsx"
    "BeitShemesh" , "Data\BeitShemesh.xlsx"  , "Scenarios_BeitShemesh.xlsx"
    };

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
save('AllCities.mat', 'AllCities');
save ('Years', 'Years');
clear palestinians_base_pop_global PopulationStartYear_global RDB s1 cities i 
clear Data scenarios