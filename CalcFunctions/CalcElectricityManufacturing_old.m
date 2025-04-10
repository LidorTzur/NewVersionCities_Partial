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

%% Inputs
EmissionsCoefficientsUpstream = Data.Electricity_DataBase.EmissionsCoefficientsUpstreamElectricity;
EmissionsCoefficientsForPv = Data.EmissionsCoefficientsForPv;
ElectricityConsumers = Data.Electricity_DatBase.Electricity_Consumption_RowNames; % 'Home', 'Public & Commercial', 'Industrial', 'Other', 'Transportation', 'Water Supply & Sewage Treatment', 'Total'
CrudeOilToFuelRatio = Data.Electricity_DataBase.CrudeOilToFuelRatio;
PVLifeCycle = Data.Electricity_DataBase.PVLifeCycle;
NewPV_PercentageBaseYear = Data.Electricity_DataBase.NewPV_PercentageBaseYear;

RowNames = ElectricityConsumers; % 'Home', 'Public & Commercial', 'Industrial', 'Other', 'Transportation', 'Water Supply & Sewage Treatment', 'Total'
temp = strrep(Data.Electricity_DatBase.Electricity_Sources, 'Renewable', 'Renewable Energies');
ColNames = compose('KWh From %s', temp); % 'KWh From Coal', 'KWh From Natural Gas', 'KWh From Renewable Energies', 'KWh From Soler', 'KWh From Mazut'

% Electricity Manufacturing Coefficients (ton of Coal, Soler, Gas etc' per KWH)
ElectrictyManufacturingCoefficients = Data.Electricity_DataBase.ElectrictyManufacturingCoefficients;


%% PV Adoption - Taking into account the changes in PV emissions by the year.
CurrentElectricityConsumptionPercentages = ElectricityConsumptionPercentages(:, Year);
if Year ~= 1 
    PreviousElectricityConsumptionPercentages = ElectricityConsumptionPercentages(:, Year-1); 
end

%% Create Table For current year
CurrentYearTable = array2table(zeros(numel(RowNames),numel(ColNames)), 'RowNames', RowNames);
CurrentYearTable.Properties.VariableNames = ColNames;

% insert consumption values
Total=0;
for j=1:width(CurrentYearTable) %% 1-5
    for i=1:height(CurrentYearTable)-1 %% 1-6
        CurrentYearTable{i,j} = CurrentYearManufacturing(i)*CurrentElectricityConsumptionPercentages(j);
        Total = Total + CurrentYearTable{i,j};
    end
    CurrentYearTable{7,j} = Total;
    Total=0;
end

%% Create Table for previous year

% (if its the first year creating a fictive tavle of zeros 
PrevYearTable = array2table(zeros(numel(RowNames),numel(ColNames)), 'RowNames', RowNames);
PrevYearTable.Properties.VariableNames = ColNames;

if Year ~= 1 
    % Consumption Table - prev year
    Total=0;
    for j=1:width(PrevYearTable) %% 1-5
        for i=1:height(PrevYearTable)-1 %% 1-6
            PrevYearTable{i,j} = PreviousYearElectricity(i)*PreviousElectricityConsumptionPercentages(j);
            Total = Total + PrevYearTable{i,j};
        end
     PrevYearTable{7,j} = Total;
     Total=0;
    end
end


%% Calculate fuel amount to electricity needs (ton, including Crude Oil)
ElectricityForFules = CurrentYearTable{7,1:width(CurrentYearTable)};
ElectricityForFules(3) = []; %removing renewables
FuelAmounts = ElectricityForFules.*ElectrictyManufacturingCoefficients;
FuelAmounts(end+1) = (FuelAmounts(3)+FuelAmounts(4))*CrudeOilToFuelRatio;

% table design - fuel amounts for electricity
FuelAmounts = array2table(FuelAmounts, 'RowNames', {'Amount'});
FuelAmounts.Properties.VariableNames = {'Coal', 'Natural Gas','Diesel', 'Mazut','Crude Oil'};

%% Calculate Total Emissions from electricity Per Current Year

RowNames = {'Coal', 'Natural Gas','Soler', 'Mazut', 'Crude Oil', 'PV'};
ColNames = {'CH4', 'CO2','Hydroflour Carbon', 'Air Pollutants','Mining Waste', 'Waste Water', 'CO2 Equivalent'};
TotalEmissionsPerYear = array2table(zeros(numel(RowNames),numel(ColNames)), 'RowNames', RowNames);
for i = 1:height(EmissionsCoefficientsUpstream) %% 1-6
    for  j = 1:width(EmissionsCoefficientsUpstream) %% 1-7
        if(i == 6) % dealing with PV
            if (j==2 || j==7) % only relevant for CO2 / CO2E
                Delta = CurrentYearTable{7,3} - PrevYearTable{7,3}; % extra KHW consumption for this year
                if Delta < 0
                    Delta = 0;
                end
                if Year == 1 
                    % For the base year - the assumption is that only 16% of the consumption is new PV
                    Delta = Delta * NewPV_PercentageBaseYear; 
                end
                
     % without the last if, the model calculates as all the panels were installed in 2017. since from 2016 to 2017,
     % the installed KW changed from 5% to 5.8%, we can assume that the delta is 0.8/5 
            TotalEmissionsPerYear{i,j} = Delta * EmissionsCoefficientsForPv{Year, 2}/1000000 * PVLifeCycle; %tons (PVLifeCycle=25 is because the panels works for 25 years)
            % TotalEmissionsPerYear{i,j} = CurrentYear{7,3}*EmissionsCoefficientsUpstream(i,j)/1000000; % tons
            end
        else % rest of the energy sources   
            TotalEmissionsPerYear{i,j} = EmissionsCoefficientsUpstream(i,j)*FuelAmounts{1,i}/1000; %tons
        end    
    end    
end 

TotalEmissionsPerYear.Properties.VariableNames = ColNames;
ElectricityManufacturingEmissions = TotalEmissionsPerYear;
FuelAmounts = removevars(FuelAmounts, 'Crude Oil');
end


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
