% % Read Files
% createPath;
% % Preparations
% preparation;
% % Calculate emissions by specific steps
% runningSteps;

createPath;
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
    "Tlv" , "Data\Tlv.xlsx"  , "Scenarios_Tlv.xlsx"
    "BeitShemesh" , "Data\BeitShemesh.xlsx"  , "Scenarios_BeitShemesh.xlsx"
    };

% cities = {
%     "BeerSheva" , "Data\BeerSheva.xlsx"  , "Scenarios_BeerSheva.xlsx"
%     };



% 1. Load existing data or initialize new structure
if exist('AllCities.mat', 'file')
    fprintf('Loading existing AllCities.mat file...\n');
    load('AllCities.mat', 'AllCities');
else
    fprintf('No previous data found. Creating a new AllCities structure.\n');
    AllCities = struct(); 
end

% 2. Main Loop
for i = 1:size(cities,1)
    cityCode      = cities{i,1};
    excelFile     = cities{i,2};
    scenariosFile = cities{i,3};
    
    fprintf('\n>>> Processing City: %s (%d of %d) <<<\n', cityCode, i, size(cities,1));
    
    % Protect master variables from internal 'clear' commands
    % (Make sure to include any variables you need to keep)
    %keepVars = {'AllCities', 'cities', 'i', 'cityCode', 'excelFile', 'scenariosFile', 'outDir', 'orderIndex'};
    
    % Execute the single city logic (creates the 'RDB' variable)
    run_city_once; 
    
    % 3. MERGING LOGIC: Add new results without deleting old ones
    if isfield(AllCities, cityCode)
        fprintf('City %s already exists in AllCities. Merging new fields...\n', cityCode);
        
        % Get names of all new result fields (e.g., BAU_RDB, Moderate_RDB...)
        newFields = fieldnames(RDB);
        
        for f = 1:numel(newFields)
            fieldName = newFields{f};
            % This line adds/updates the specific field (like 'BAU_RDB') 
            % inside the city, but leaves other fields (like 'Sensitivity_RDB') untouched.
            AllCities.(cityCode).(fieldName) = RDB.(fieldName);
        end
    else
        % If city doesn't exist yet, create it
        fprintf('Adding new city entry for %s.\n', cityCode);
        AllCities.(cityCode) = RDB;
    end
    
    % 4. Incremental Save (Safety first!)
    save('AllCities.mat', 'AllCities');
    fprintf('Saved: AllCities now contains %d cities.\n', numel(fieldnames(AllCities)));
end


% Final variables to keep
%clearvars -except AllCities Years
fprintf('\nProcess completed successfully.\n');