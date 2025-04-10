function [MaterialConsumption, TotalConstructionEmissionsAndWaste] = CalcConstruction(Data, CurrentYearConstruction)

% Description:
%   Calculates the annual material consumption and associated emissions/waste
%   from construction activities, based on construction area by sector.

% Inputs:
%   CurrentYearConstruction - Vector of construction area per sector (e.g., residential, public, etc.).

% Outputs:
%   MaterialConsumption              - Table with total material use (tons) by construction sector and material type.
%   TotalConstructionEmissionsAndWaste - Table with emissions and waste (e.g., CO2, NOX, mining waste) by sector.

%% Inputs

EmissionCoefficients = Data.Const_DataBase.CostructionEmissionCoefficients;
MaterialCoefficients = Data.Const_DataBase.ConstructionMaterialCoefficients;
MortarProductionCO2ECoefficient = Data.Const_DataBase.MortarProductionCO2ECoefficient;

% 'Agriculture', 'Other Public Buldings', 'Healthcare', 'Education', 'Industry and Storage', 'Transportation and Communications', 'Trade', 'Offices', 'Hosting', 'Residential', 'Total For Construction', 'Local Cement For Other Uses', 'Imported Cement For Other Uses'
RowNames = Data.Const_DataBase.ConstructionTypes;
% 'Gravel', 'Sand', 'Calcite', 'Plaster', 'Clay', 'Other Constructionn Materials'
ColNames = Data.Const_DataBase.MaterialsForConstruction;

%% Materials Consumption Table

MaterialConsumption = array2table(zeros(numel(RowNames),numel(ColNames)), 'RowNames', RowNames);
for i=1:width(MaterialConsumption) %%1-6
    for j = 1:height(MaterialConsumption)-3 %%1-10
        MaterialConsumption{j,i} = CurrentYearConstruction(j)*MaterialCoefficients(i); % tons of materials
    end
    MaterialConsumption{11, i} = sum(MaterialConsumption{1:10, i});
end
MaterialConsumption{12:13, :} = Data.Const_DataBase.MaterialConsumption;
MaterialConsumption.Properties.VariableNames = ColNames;


%% emissions table

% Create the table
ColNames = Data.Const_DataBase.ConstructionEmissionTypes; % 'Mining Waste', 'CO2', 'NOX', 'PM10', 'SO2', 'CO2E From Mortar Production'
TotalConstructionEmissionsAndWaste = array2table(zeros(numel(RowNames),numel(ColNames)), 'RowNames', RowNames);

% Fill the table
for i = 1:width(TotalConstructionEmissionsAndWaste)-1 %% 1-5
    for j = 1:height(TotalConstructionEmissionsAndWaste) %% 1-13
        TotalConstructionEmissionsAndWaste{j,i} = EmissionCoefficients(i)*sum(MaterialConsumption{j, 3:5}); % million tons  
    end
end

TotalConstructionEmissionsAndWaste.Properties.VariableNames = ColNames;

%% Emissions from mortar manufacturing

for j = 1:height(TotalConstructionEmissionsAndWaste)
    TotalConstructionEmissionsAndWaste{j,6} = sum(MaterialConsumption{j, 3:5})*MortarProductionCO2ECoefficient;
end

end

