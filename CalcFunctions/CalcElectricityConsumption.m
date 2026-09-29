% function [TotalElectricityConsumptionEmissions, CurrentYearTotal] = CalcElectricityConsumption(Data, CurrentYearConsumption,ElectricityConsumptionPercentages, WasteIncinaration, year)
% 
% % Description:
% %   Calculates total emissions resulting from electricity consumption by sector and energy source.
% 
% % Inputs:
% %   CurrentYearConsumption       - Electricity consumption per sector (KWh).
% %   ElectricityConsumptionPercentages - Share of each energy source used for electricity generation.
% %   WasteIncinaration            - Amount of waste incinerated for electricity.
% %   year                         - Current simulation year (for time-based emission updates).
% 
% % Outputs:
% %   TotalElectricityConsumptionEmissions - Table with emissions (tons) by sector and pollutant.
% %   CurrentYearTotal                    - Vector of total KWh per energy source.
% 
%     %% Inputs
%     % Emissions From Mining, Manufacturing Etc Fuels (g/KWh)
%     Emissions = Data.Electricity_DataBase.EmissionsFromElectricityConsumption_Base; 
%     % 'Co2', 'CH4', 'Nitrous Oxide (N2O)', 'NOX', 'PM', 'SO2', 'Other Air Pollutants', 'Sewage', 'Co2e'
%     ElectricityEmissionTypes = Data.Electricity_DataBase.ElectricityEmissionTypes;
%     EmissionsCoefficientsForPv = Data.EmissionsCoefficientsForPv;
% 
%     %% Create Table of total emmisions by electricity and energy source
%     RowNames = {'Home', 'Public & Commercial', 'Industrial', 'Other', 'Transportation', 'Water Local','Water Global','Total'};
%     ColNames = {'KWh From Coal', 'KWh From Natural Gas', 'KWh From Renewable Energies', 'KWh From Soler', 'KWh From Mazut', 'KWh From Waste Incinaration'};
%     CurrentYear = zeros(numel(RowNames),numel(ColNames));
%     CurrentYear = array2table(CurrentYear, 'RowNames', RowNames);
%     CurrentYear.Properties.VariableNames = ColNames;
% 
%     %% KWH from sources     
%     Total=0;
% 
%     for j=1:width(CurrentYear)-1
%         for i=1:height(CurrentYear)-1
%             CurrentYear{i,j} = CurrentYearConsumption(i)*ElectricityConsumptionPercentages(j); % KWH from sources
%             Total = Total + CurrentYear{i,j};
%         end
%         CurrentYear{i+1,j} = Total;
%         Total=0;
%     end
% 
%     KwhFromInciniration = Data.Electricity_DataBase.WasteToElectricity*WasteIncinaration;
% 
%     if(CurrentYear{8,1} > KwhFromInciniration)
%         CurrentYear{8,1} = CurrentYear{8,1}-KwhFromInciniration;
%     else
%         KwhFromInciniration = CurrentYear{8,1};
%         CurrentYear{:,1} = 0;
%     end
% 
%     CurrentYear{8,6} = KwhFromInciniration;
%     CurrentYearTotal = table2array(CurrentYear('Total',:))';
% 
% 
%     %% Total Emissions Tables (emission factors * consumption)
% 
%     NumOfSources = numel(Data.Electricity_DataBase.ElectricityBySources_row_names)-1;
% 
%     for Table=1:NumOfSources %( Create 6 tables (named Temp) for - Coal, Natural Gas, Renewable Energies, Soler, Mazut, Burning Waste)
%         Temp = zeros(numel(RowNames),numel(ElectricityEmissionTypes)); 
%         Temp = array2table(Temp, 'RowNames', RowNames);
%         Temp.Properties.VariableNames = ElectricityEmissionTypes;
% 
%         % Fill the right emission values of renewable energies by the year
%         if Table == 3 % Renewable energies
%             CurrentYearIndex = find(EmissionsCoefficientsForPv{:,1} == year, 1); 
%             if ~isempty(CurrentYearIndex)
%                 Emissions(3,1) = EmissionsCoefficientsForPv{CurrentYearIndex,2};
%             end
%         end
% 
%         for j=1:width(Temp)-1
%             for i=1:height(Temp)                
%                 Temp{i,j} = Emissions(Table,j)*CurrentYear{i,Table}/1000000; %% tons
%             end
%         end
%         for i=1:height(Temp)
%             Temp{i,9}=Temp{i,1}+Temp{i,2}*28+Temp{i,3}*265; %Temporary - convert to ECo2
%         end
%         switch Table
%         case 1
%             CoalEmissions=Temp;
%         case 2
%             NaturalGasEmissions=Temp;
%         case 3
%             RenewableEnergiesEmissions=Temp;
%         case 4
%             SolerEmissions=Temp;
%         case 5
%             MazutEmissions=Temp;
%         case 6
%             IncinarationEmissions = Temp;
%         end
%     end
%     %disp('Emissions From Electricity Consumption - RenewableEnergiesEmissions');
%     %disp(RenewableEnergiesEmissions);
% 
% 
%     TotalElectricityConsumptionEmissions = array2table(zeros(numel(RowNames),numel(ElectricityEmissionTypes)), 'RowNames', RowNames);
%     TotalElectricityConsumptionEmissions.Properties.VariableNames = ElectricityEmissionTypes;
%     for i=1:height(TotalElectricityConsumptionEmissions)
%         for j=1:width(TotalElectricityConsumptionEmissions)
%             TotalElectricityConsumptionEmissions{i,j} = CoalEmissions{i,j} + NaturalGasEmissions{i,j}+RenewableEnergiesEmissions{i,j}+SolerEmissions{i,j}+MazutEmissions{i,j}+IncinarationEmissions{i,j};
%         end
%     end
% 
% 
% end


function [TotalElectricityConsumptionEmissions, CurrentYearTotal] = CalcElectricityConsumption(Data, CurrentYearConsumption, ElectricityConsumptionPercentages, WasteIncinaration, year)

    % --- Configuration ---
    RowNames = {'Home', 'Public & Commercial', 'Industrial', 'Other', 'Transportation', 'Water Local','Water Global','Total'};
    ElectricityEmissionTypes = Data.Electricity_DataBase.ElectricityEmissionTypes;

    % 1. VECTORIZATION: Calculate KWH matrix (7 sectors x 5 sources)
    % Initializing 8 rows (7 sectors + Total) and 6 sources
    KWH_Matrix = zeros(8, 6);
    KWH_Matrix(1:7, 1:5) = CurrentYearConsumption(:) * ElectricityConsumptionPercentages(:)';

    % 2. Calculate Totals for the first 5 sources (Row 8)
    KWH_Matrix(8, 1:5) = sum(KWH_Matrix(1:7, 1:5), 1);

    % 3. Waste Incineration Logic (Exact parity with original logic)
    KwhFromInciniration = Data.Electricity_DataBase.WasteToElectricity * WasteIncinaration;

    if KWH_Matrix(8, 1) > KwhFromInciniration
        % Subtract from the Total of Coal
        KWH_Matrix(8, 1) = KWH_Matrix(8, 1) - KwhFromInciniration;
    else
        % If incineration covers all coal, zero out coal and cap incineration
        KwhFromInciniration = KWH_Matrix(8, 1);
        KWH_Matrix(:, 1) = 0;
    end

    % Assign incineration value to the "Total" row, column 6
    KWH_Matrix(8, 6) = KwhFromInciniration;

    % Output 1: Total KWh per source (Column vector)
    CurrentYearTotal = KWH_Matrix(8, :)';

    % 4. DYNAMIC EMISSION FACTORS: Update based on the year
    % Check if Data has a time-series of emission factors. 
    % We use 'year' to index into the database.
    if isfield(Data.Electricity_DataBase.EmissionsFromElectricityConsumption, 'EmissionsFromElectricityConsumption')
        % Assuming Data.Electricity_DataBase.EmissionsByYear is a cell array or struct indexed by year
        EmissionsBase = Data.Electricity_DataBase.EmissionsFromElectricityConsumption{year};
    else
        % Fallback to base if no yearly data exists
        EmissionsBase = Data.Electricity_DataBase.EmissionsFromElectricityConsumption_Base; 
    end

    % 5. Specific PV Update (Kept for compatibility with your PV logic)
    EmissionsCoefficientsForPv = Data.EmissionsCoefficientsForPv;
    currYearIdx = (EmissionsCoefficientsForPv{:,1} == year);
    if any(currYearIdx)
        % Updates Source 3 (Renewables), Pollutant 1 (CO2)
        EmissionsBase(3, 1) = EmissionsCoefficientsForPv{currYearIdx, 2};
    end

    % 6. VECTORIZATION: Calculate Total Emissions (8 sectors x 9 pollutants)
    % (KWH_Matrix [8x6]) * (EmissionsBase [6x8]) / 1,000,000 (grams to tons)
    TotalEmissions_Mat = (KWH_Matrix * EmissionsBase) / 1000000;

    % 7. Calculate CO2e (Column 9) 
    % Formula: CO2 + CH4*28 + N2O*265
    TotalEmissions_Mat(:, 9) = TotalEmissions_Mat(:, 1) + TotalEmissions_Mat(:, 2) * 28 + TotalEmissions_Mat(:, 3) * 265;

    % 8. Final Table Conversion
    TotalElectricityConsumptionEmissions = array2table(TotalEmissions_Mat,'RowNames', RowNames, 'VariableNames', ElectricityEmissionTypes);
end




% function [TotalElectricityConsumptionEmissions, CurrentYearTotal] = CalcElectricityConsumption(Data, CurrentYearConsumption, ElectricityConsumptionPercentages, WasteIncinaration, year)
% 
%     % --- הגדרות בסיס ---
%     RowNames = {'Home', 'Public & Commercial', 'Industrial', 'Other', 'Transportation', 'Water Local','Water Global','Total'};
%     ElectricityEmissionTypes = Data.Electricity_DataBase.ElectricityEmissionTypes;
% 
%     % 1. חישוב ראשוני של מטריצת קוט"ש (7 מגזרים x 5 מקורות אנרגיה ראשוניים)
%     % עמודות: 1-פחם, 2-גז, 3-מתחדשות, 4-סולר, 5-מזוט, 6-שריפת פסולת
%     KWH_Matrix = zeros(8, 6);
%     KWH_Matrix(1:7, 1:5) = CurrentYearConsumption(:) * ElectricityConsumptionPercentages(:)';
% 
%     % 2. סיכום ביניים לשורת ה-Total (שורה 8)
%     KWH_Matrix(8, 1:5) = sum(KWH_Matrix(1:7, 1:5), 1);
% 
%     % 3. לוגיקת שריפת פסולת (Waste Incineration) - החלפת פחם
%     % הערך WasteIncinaration מגיע מהחישוב בסקריפט ה-FULLSCENARIO (סעיף C בלולאה)
%     KwhFromInciniration = Data.Electricity_DataBase.WasteToElectricity * WasteIncinaration;
%     TotalCoalOriginal = KWH_Matrix(8, 1);
% 
%     if TotalCoalOriginal > 0
%         if TotalCoalOriginal > KwhFromInciniration
%             % חישוב מקדם הפחתה יחסי לכל המגזרים
%             reductionFactor = (TotalCoalOriginal - KwhFromInciniration) / TotalCoalOriginal;
% 
%             % עדכון עמודת הפחם בכל המגזרים (ניכוי יחסי)
%             KWH_Matrix(:, 1) = KWH_Matrix(:, 1) * reductionFactor;
% 
%             actualIncinerated = KwhFromInciniration;
%         else
%             % אם הפסולת מחליפה את כל הפחם
%             actualIncinerated = TotalCoalOriginal;
%             KWH_Matrix(:, 1) = 0; % איפוס פחם בכל המגזרים
%         end
%     else
%         actualIncinerated = 0;
%     end
% 
%     % השמת האנרגיה משריפת פסולת בשורת ה-Total (עמודה 6)
%     KWH_Matrix(8, 6) = actualIncinerated;
% 
%     % פלט 1: סך הקוט"ש לפי מקור (עמודה וקטורית עבור CalcElectricityManufacturing)
%     CurrentYearTotal = KWH_Matrix(8, :)';
% 
%     % 4. טעינת מקדמי פליטה דינמיים לפי השנה (מתוך מסד הנתונים)
%     if isfield(Data.Electricity_DataBase, 'EmissionsFromElectricityConsumption') && ...
%        length(Data.Electricity_DataBase.EmissionsFromElectricityConsumption) >= year
% 
%         EmissionsBase = Data.Electricity_DataBase.EmissionsFromElectricityConsumption{year};
%     else
%         EmissionsBase = Data.Electricity_DataBase.EmissionsFromElectricityConsumption_Base; 
%     end
% 
%     % 5. עדכון מקדם PV (סולארי) ספציפי לשנה מתוך טבלת המקדמים
%     EmissionsCoefficientsForPv = Data.EmissionsCoefficientsForPv;
%     currYearIdx = (EmissionsCoefficientsForPv{:,1} == year);
%     if any(currYearIdx)
%         % עדכון CO2 (עמודה 1) למקור המתחדשות (שורה 3)
%         EmissionsBase(3, 1) = EmissionsCoefficientsForPv{currYearIdx, 2};
%     end
% 
%     % 6. חישוב פליטות וקטורי (צריכה X מקדמים)
%     % המרה מגרמים לטונות (חילוק במיליון)
%     TotalEmissions_Mat = (KWH_Matrix * EmissionsBase) / 1000000;
% 
%     % 7. חישוב CO2 Equivalent (CO2e) בעמודה 9
%     % נוסחה: CO2 + CH4*28 + N2O*265
%     TotalEmissions_Mat(:, 9) = TotalEmissions_Mat(:, 1) + ...
%                                TotalEmissions_Mat(:, 2) * 28 + ...
%                                TotalEmissions_Mat(:, 3) * 265;
% 
%     % 8. יצירת טבלת הפלט
%     TotalElectricityConsumptionEmissions = array2table(TotalEmissions_Mat, ...
%         'RowNames', RowNames, 'VariableNames', ElectricityEmissionTypes);
% end