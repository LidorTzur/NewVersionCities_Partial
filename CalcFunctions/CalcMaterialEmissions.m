function [MaterialEmissionsByYear] = CalcMaterialEmissions(Data, MaterialAmounts)

% -------------------------------------------------------------------------
% FUNCTION: CalcMaterialEmissions
% PURPOSE:
%   Calculates annual CO2e emissions from materials, including:
%   - Production emissions
%   - Landfill emissions
%   - Recycling emissions
%   - Recycling credit (avoided emissions)
% -------------------------------------------------------------------------

%% === Extract table if input is a cell ===
if iscell(MaterialAmounts)
    MaterialAmounts = MaterialAmounts{1}; % unwrap from cell if needed
end

%% === Load coefficients (same for all years) ===
CoeffTable = Data.Materials_DataBase.WateAndRecycling_Coeff;
CoeffArray = CoeffTable{:,:}; % convert table to numeric matrix

RowNames = CoeffTable.Properties.RowNames;
ColNames = {'Production_tCO2e', 'Landfill_tCO2e', 'Recycling_tCO2e', 'Recycling_Benefit_tCO2e', 'Total_tCO2e'};

MaterialEmissionsByYear = array2table(zeros(length(RowNames), length(ColNames)),'RowNames', RowNames, 'VariableNames', ColNames);

%% === Calculate emissions per material ===
for i = 1:length(RowNames)
    EF_production = CoeffArray(i,1);
    EF_recycling  = CoeffArray(i,2);
    EF_benefit    = CoeffArray(i,3);
    EF_landfill   = CoeffArray(i,4);

    prodAmount = MaterialAmounts{i,1} + MaterialAmounts{i,2};
    recycleAmount = MaterialAmounts{i,2};
    landfillAmount = MaterialAmounts{i,1};

    ProductionEmis = prodAmount * EF_production;
    LandfillEmis   = landfillAmount * EF_landfill;
    RecyclingEmis  = recycleAmount * EF_recycling;
    RecycleCredit  = recycleAmount * EF_benefit;

    Total = ProductionEmis + LandfillEmis + RecyclingEmis - RecycleCredit;

    MaterialEmissionsByYear{i, 'Production_tCO2e'} = ProductionEmis + RecyclingEmis - RecycleCredit;
    MaterialEmissionsByYear{i, 'Landfill_tCO2e'}   = LandfillEmis;
    MaterialEmissionsByYear{i, 'Recycling_tCO2e'}  = RecyclingEmis;
    MaterialEmissionsByYear{i, 'Recycling_Benefit_tCO2e'} = -RecycleCredit;
    MaterialEmissionsByYear{i, 'Total_tCO2e'}      = Total;
end
end
