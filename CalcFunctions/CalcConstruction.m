function [MaterialConsumption, TotalConstructionEmissionsAndWaste] = CalcConstruction(Data, CurrentYearConstruction, CurrentConstructionFootprint, CurrentConstructionECO2Coefficients_ByMaterial, ChangeInGreenMaterials)

% Description:
%   Calculates the annual material consumption and associated emissions/waste
%   from construction activities, based on construction area by sector.

% Inputs:
%   CurrentYearConstruction - Vector of construction area per sector (e.g., residential, public, etc.).

% Outputs:
%   MaterialConsumption              - Table with total material use (tons) by construction sector and material type.
%   TotalConstructionEmissionsAndWaste - Table with emissions and waste (e.g., CO2, NOX, mining waste) by sector.

% disp('--- CurrentYearConstruction ---')
% disp(class(CurrentYearConstruction))
% disp(size(CurrentYearConstruction))
% disp(CurrentYearConstruction)

%% Inputs

EmissionCoefficients = Data.Const_DataBase.CostructionEmissionCoefficients;
GlobalDistribution = Data.Const_DataBase.ConstructionMaterialImprotedRate;
LocalDistribution = Data.Const_DataBase.ConstructionMaterialLocalProductionRate;

% Lidor's addition
ConstructionECO2Coefficients_ByMaterial = CurrentConstructionECO2Coefficients_ByMaterial;
ConstructionMaterialCoefficients_HighDensity = Data.Const_DataBase.ConstructionMaterialCoefficients_HighDensity;
ConstructionMaterialCoefficients_LowDensity = Data.Const_DataBase.ConstructionMaterialCoefficients_LowDensity;

% Table Names
% 'Agriculture', 'Other Public Buldings', 'Healthcare', 'Education', 'Industry and Storage', 'Transportation and Communications', 'Trade', 'Offices', 'Hosting', 'Residential - High-Density Construction', 'Residential - Low-Density Construction', 'Total'
RowNames = Data.Const_DataBase.ConstructionTypes;
% 'Steel', 'Concrete', 'Asphalt', 'Autoclaved Aerated Concrete', 'Ceramic flooring', 'Gypsum plaster', 'Exterior cladding'
ColNames = Data.Const_DataBase.MaterialsForConstruction;

%% Materials Consumption Table

% Define the materials table
MaterialConsumption = array2table(zeros(numel(RowNames),numel(ColNames)), 'RowNames', RowNames);

% Lidor's addition
% Calculate the Ratio between the all area to the floor area to get thr avg number of floors - to match the materials coefficient properly
Ratio = CurrentYearConstruction ./ CurrentConstructionFootprint;

%disp(Ratio);

Ratio(CurrentConstructionFootprint == 0) = Inf;
isHighDensity = Ratio > 2;
Categories_to_run = height(MaterialConsumption)-3;

for i=1:width(MaterialConsumption) %%1-7 Materials
    for j = 1:Categories_to_run %%1-9 - construction categories
        if isHighDensity(j)
            coeff = ConstructionMaterialCoefficients_HighDensity(i);
        else
            coeff = ConstructionMaterialCoefficients_LowDensity(i);
        end
        MaterialConsumption{j,i} = CurrentYearConstruction(j) * coeff; % tons of materials
    end
    % Lidor: Enter the residential Data (separate from the rest)
    MaterialConsumption{10, i} = CurrentYearConstruction(10)* ConstructionMaterialCoefficients_HighDensity(i);
    MaterialConsumption{11, i} = CurrentYearConstruction(11)* ConstructionMaterialCoefficients_LowDensity(i);
    % The sum row
    MaterialConsumption{12, i} = sum(MaterialConsumption{1:11, i});
end
%MaterialConsumption{13:14, :} = Data.Const_DataBase.MaterialConsumption;
MaterialConsumption.Properties.VariableNames = ColNames;


%% emissions table

% Create the table
%ColNames = Data.Const_DataBase.ConstructionEmissionTypes; % 'Mining Waste', 'CO2', 'NOX', 'PM10', 'SO2', 'CO2E From Mortar Production'
ColNames = Data.Const_DataBase.ConstructionEmissionTypes; % 'Mining Waste', 'NOX', 'PM10', 'SO2'
TotalConstructionEmissionsAndWaste = array2table(zeros(numel(RowNames),numel(ColNames)), 'RowNames', RowNames);

Saving_Potential = Data.Const_DataBase.Saving_Green_Cement; % הוקטור מהתמונה שלך (0, 0.34, 0...)

% Fill the table
for i = 1:width(TotalConstructionEmissionsAndWaste) %% 1-7
    for j = 1:height(TotalConstructionEmissionsAndWaste) %% 1-12
        weightedSumWithGreenTransition = 0;
        for m = 1:width(MaterialConsumption)
            if Saving_Potential(m) > 0
                matMiningFactor = 1 - (ChangeInGreenMaterials - 1);
            else
                matMiningFactor = 1;
            end
            weightedSumWithGreenTransition = weightedSumWithGreenTransition + (MaterialConsumption{j,m} * matMiningFactor);
        end
        TotalConstructionEmissionsAndWaste{j,i} = EmissionCoefficients(i)*weightedSumWithGreenTransition; %  tons  eco2
    end
end

TotalConstructionEmissionsAndWaste.Properties.VariableNames = ColNames;

%% Emissions from eco2 from materials unique coefficient 

% Extract the table to matrix
materialAmounts = MaterialConsumption{:,:}; % גודל: N×M


% Calculate the Total emission, and the local, global distribution
localFactors = ConstructionECO2Coefficients_ByMaterial .* LocalDistribution;
globalFactors = ConstructionECO2Coefficients_ByMaterial .* GlobalDistribution;

%totalEmissions = materialAmounts * ConstructionECO2Coefficients_ByMaterial'; % N×1
totalEmissions = materialAmounts * ConstructionECO2Coefficients_ByMaterial(:);
LocalEmission = materialAmounts * localFactors';
GlobalEmission = materialAmounts * globalFactors';

% Add the emission of eCO2 to the final emission table
TotalConstructionEmissionsAndWaste = addvars(TotalConstructionEmissionsAndWaste, totalEmissions, 'Before', 2, 'NewVariableNames', 'CO2Emission_tons');
TotalConstructionEmissionsAndWaste = addvars(TotalConstructionEmissionsAndWaste, LocalEmission, 'Before', 6, 'NewVariableNames', 'CO2Emission_tons_Local');
TotalConstructionEmissionsAndWaste = addvars(TotalConstructionEmissionsAndWaste, GlobalEmission, 'Before', 7, 'NewVariableNames', 'CO2Emission_tons_Global');
%disp(TotalConstructionEmissionsAndWaste);


end

