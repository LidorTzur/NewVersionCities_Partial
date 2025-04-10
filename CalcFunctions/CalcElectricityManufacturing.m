function [ElectricityManufacturingEmissions, FuelAmounts] = CalcElectricityManufacturing(Data, CurrentYearManufacturing, PreviousYearElectricity, ElectricityConsumptionPercentages, Year) 

% Description:
%   Calculates upstream emissions and fuel consumption associated with electricity production
%   for the current year, based on electricity demand by sector and energy source mix.

% Inputs:
%   CurrentYearManufacturing      - Electricity consumption by sector (KWh) for current year.
%   PreviousYearElectricity       - Electricity consumption by sector (KWh) for previous year.
%   ElectricityConsumptionPercentages - Matrix with electricity source distribution per year.
%   Year                          - Current simulation year.

% Outputs:
%   ElectricityManufacturingEmissions - Table with upstream emissions by energy source and pollutant.
%   FuelAmounts                       - Table with total fuel consumption (tons) by fuel type.

%% Validate Inputs
assert(Year >= 1 && Year <= size(ElectricityConsumptionPercentages, 2), 'Year index out of range');

%% Inputs
EmissionsCoefficientsUpstream = Data.Electricity_DataBase.EmissionsCoefficientsUpstreamElectricity;
EmissionsCoefficientsForPv = Data.EmissionsCoefficientsForPv;
ElectricityConsumers = Data.Electricity_DataBase.Electricity_Consumption_RowNames;
CrudeOilToFuelRatio = Data.Electricity_DataBase.CrudeOilToFuelRatio;
PVLifeCycle = Data.Electricity_DataBase.PVLifeCycle;
NewPV_PercentageBaseYear = Data.Electricity_DataBase.NewPV_PercentageBaseYear;

RowNames = ElectricityConsumers;
temp = strrep(Data.Electricity_DataBase.Electricity_Sources, 'Renewable', 'Renewable Energies');
ColNames = compose("KWh From %s", string(temp));


ElectrictyManufacturingCoefficients = Data.Electricity_DataBase.ElectrictyManufacturingCoefficients;

%% PV Adoption - Taking into account the changes in PV emissions by the year.
CurrentElectricityConsumptionPercentages = ElectricityConsumptionPercentages(:, Year);
if Year ~= 1 
    PreviousElectricityConsumptionPercentages = ElectricityConsumptionPercentages(:, Year-1); 
end

%% Create Tables for current and previous year
CurrentYearTable = BuildElectricityTable(CurrentYearManufacturing, CurrentElectricityConsumptionPercentages, RowNames, ColNames);
if Year ~= 1
    PrevYearTable = BuildElectricityTable(PreviousYearElectricity, PreviousElectricityConsumptionPercentages, RowNames, ColNames);
else
    PrevYearTable = BuildElectricityTable(zeros(size(CurrentYearManufacturing)), zeros(size(CurrentElectricityConsumptionPercentages)), RowNames, ColNames);
end

%% Calculate fuel amount to electricity needs (ton, including Crude Oil)
ElectricityForFules = CurrentYearTable{7,1:width(CurrentYearTable)};
ElectricityForFules(3) = []; % removing renewables
FuelAmounts = ElectricityForFules .* ElectrictyManufacturingCoefficients;
FuelAmounts(end+1) = (FuelAmounts(3)+FuelAmounts(4)) * CrudeOilToFuelRatio;

FuelAmounts = array2table(FuelAmounts, 'RowNames', {'Amount'});
FuelAmounts.Properties.VariableNames = {'Coal', 'Natural Gas','Diesel', 'Mazut','Crude Oil'};

%% Calculate Total Emissions from electricity Per Current Year
RowNames = {'Coal', 'Natural Gas','Soler', 'Mazut', 'Crude Oil', 'PV'};
ColNames = {'CH4', 'CO2','Hydroflour Carbon', 'Air Pollutants','Mining Waste', 'Waste Water', 'CO2 Equivalent'};
TotalEmissionsPerYear = array2table(zeros(numel(RowNames),numel(ColNames)), 'RowNames', RowNames);

for i = 1:height(EmissionsCoefficientsUpstream)
    for j = 1:width(EmissionsCoefficientsUpstream)
        if i == 6  % PV
            TotalEmissionsPerYear{i,j} = CalcPVEmissions(CurrentYearTable, PrevYearTable, Year, j, EmissionsCoefficientsForPv, PVLifeCycle, NewPV_PercentageBaseYear);
        else
            TotalEmissionsPerYear{i,j} = EmissionsCoefficientsUpstream(i,j) * FuelAmounts{1,i} / 1000;
        end
    end
end

TotalEmissionsPerYear.Properties.VariableNames = ColNames;
ElectricityManufacturingEmissions = TotalEmissionsPerYear;
FuelAmounts = removevars(FuelAmounts, 'Crude Oil');
end

%% Helper Functions
function Table = BuildElectricityTable(BaseVector, Percentages, RowNames, ColNames)
    Table = array2table(zeros(numel(RowNames), numel(ColNames)), 'RowNames', RowNames);
    Table.Properties.VariableNames = ColNames;
    for j = 1:width(Table)
        for i = 1:height(Table)-1
            Table{i,j} = BaseVector(i) * Percentages(j);
        end
        Table{end,j} = sum(Table{1:end-1,j});
    end
end

function emission = CalcPVEmissions(CurrentYearTable, PrevYearTable, Year, j, EmissionsCoefficientsForPv, PVLifeCycle, NewPV_PercentageBaseYear)
    if j == 2 || j == 7 % Only CO2 or CO2E
        Delta = CurrentYearTable{7,3} - PrevYearTable{7,3};
        Delta = max(0, Delta);
        if Year == 1
            Delta = Delta * NewPV_PercentageBaseYear;
        end
        emission = Delta * EmissionsCoefficientsForPv{Year, 2} / 1e6 * PVLifeCycle;
    else
        emission = 0;
    end
end
