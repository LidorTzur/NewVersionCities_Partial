addpath("Scenarios");
addpath("CalcFunctions");
%addpath("UI");
addpath("Data");

%% insert the changes from the scenarios excel
ImprovementValues = readtable(scenarios,'Sheet','Improvements','Range','B2:B5','ReadVariableNames',false);

%% Inputs to the sheet
% Electricity Transportation row name
Electricity_Transportation_ColumnNames = ones(1, Years);
for i = 1:width(Electricity_Transportation_ColumnNames)
    Electricity_Transportation_ColumnNames(i) = BaseYear-1+i;
end
Electricity_Transportation_ColumnNames = string(Electricity_Transportation_ColumnNames);
Electricity_Transportation_RowNames = {'Electric Car', 'Electric Van', 'Electric Truck', 'Electric Bus'};

% Electricity Water row name
ElectricityFromWaterCoefficientsTable_RowNames = {'Desalination', 'Moving', 'Urban Water Moving', 'Treated Waste Water Moving', 'Sewege Treatment', 'Water Production'};

% Technological  Improvements
Electric_Vehicles_Improvements = ImprovementValues{2,1};
Water_Desalination_Improvements = ImprovementValues{1,1};
Electricity_From_Gas_Improvements = ImprovementValues{3,1};


%% 1. Electric Vehicles Improvements ((kWh/KM))
ElectricityConsumptionEmissionsInTransportationTable = array2table(zeros(height(DataBase.Electricity_DataBase.ElectricityConsumptionEmissionsInTransportation),Years));
ElectricVehicleImprovements = ReductionVectorCalc(BaseYear, TargetYear_global, Electric_Vehicles_Improvements);
ElectricityConsumptionEmissionsInTransportationTable{:,1} = DataBase.Electricity_DataBase.ElectricityConsumptionEmissionsInTransportation;
for i = 1:Years
    % The electricity coeff will improve by twice till 2050
    ElectricityConsumptionEmissionsInTransportationTable{1,i} = ElectricityConsumptionEmissionsInTransportationTable{1,1}*ElectricVehicleImprovements(i);
    ElectricityConsumptionEmissionsInTransportationTable{2,i} = ElectricityConsumptionEmissionsInTransportationTable{2,1}*ElectricVehicleImprovements(i);
    ElectricityConsumptionEmissionsInTransportationTable{3,i} = ElectricityConsumptionEmissionsInTransportationTable{3,1}*ElectricVehicleImprovements(i);
    ElectricityConsumptionEmissionsInTransportationTable{4,i} = ElectricityConsumptionEmissionsInTransportationTable{4,1}*ElectricVehicleImprovements(i);
end
ElectricityConsumptionEmissionsInTransportationTable.Properties.VariableNames = Electricity_Transportation_ColumnNames;
ElectricityConsumptionEmissionsInTransportationTable.Properties.RowNames = Electricity_Transportation_RowNames;
DataBase.Electricity_DataBase.ElectricityConsumptionEmissionsInTransportation = ElectricityConsumptionEmissionsInTransportationTable;

%% 2. Water Desalination Improvements
WaterDesalinationImprovements = ReductionVectorCalc(BaseYear,TargetYear_global, Water_Desalination_Improvements);
ElectricityFromWaterCoefficientsTable = array2table(zeros(height(DataBase.Water_DataBase.ElectricityConsumptionCoefficients),Years)); %create a table in a size of 6 on number of years
ElectricityFromWaterCoefficientsTable{:,1} = DataBase.Water_DataBase.ElectricityConsumptionCoefficients; % insert to the 2019 year (first column) the ElectricityConsumptionCoefficients we have
for i = 1:Years
    ElectricityFromWaterCoefficientsTable{1,i} = ElectricityFromWaterCoefficientsTable{1,1}.*WaterDesalinationImprovements(i);
    ElectricityFromWaterCoefficientsTable{2,i} = ElectricityFromWaterCoefficientsTable{2,1};
    ElectricityFromWaterCoefficientsTable{3,i} = ElectricityFromWaterCoefficientsTable{3,1};
    ElectricityFromWaterCoefficientsTable{4,i} = ElectricityFromWaterCoefficientsTable{4,1};
    ElectricityFromWaterCoefficientsTable{5,i} = ElectricityFromWaterCoefficientsTable{5,1};
    ElectricityFromWaterCoefficientsTable{6,i} = ElectricityFromWaterCoefficientsTable{6,1};
end
ElectricityFromWaterCoefficientsTable.Properties.VariableNames = Electricity_Transportation_ColumnNames;
ElectricityFromWaterCoefficientsTable.Properties.RowNames = ElectricityFromWaterCoefficientsTable_RowNames;
DataBase.Water_DataBase.ElectricityConsumptionCoefficients = ElectricityFromWaterCoefficientsTable;


%% 3. Natural Gas Improvements
NaturalGasImprovements = GrowthVectorCalc(BaseYear,TargetYear_global, Electricity_From_Gas_Improvements)-1;
DataBase.Electricity_DataBase.NaturalGasImprovements = NaturalGasImprovements;

%% Other functions

%return vector of percentage to reduce (1-improve)
function ReductionVector = ReductionVectorCalc(StartYear, EndYear, EndYearVal)
Period = EndYear-StartYear+1;
ReductionVector = ones(1, Period);
ReductionVector(Period) = 1-EndYearVal;
FutureValue = ReductionVector(Period);
Rate = nthroot(FutureValue/ReductionVector(1),Period-1);
    for i = 1:Period
        ReductionVector(i) = ReductionVector(1)*((Rate)^(i-1));
    end
end

%return vector of percentage to Increase (1-improve)
function GrowthVector = GrowthVectorCalc(StartYear, EndYear, EndYearVal)
Period = EndYear-StartYear+1;
GrowthVector = ones(1, Period);
GrowthVector(Period) = 1+EndYearVal;
FutureValue = GrowthVector(Period);
Rate = nthroot(FutureValue/GrowthVector(1),Period-1);
    for i = 1:Period
        GrowthVector(i) = GrowthVector(1)*((Rate)^(i-1));
    end
end


%%% cleaning
clear ElectricityConsumptionEmissionsInTransportationTable Electricity_Transportation_ColumnNames Electricity_Transportation_RowNames ElectricityFromWaterCoefficientsTable ElectricityFromWaterCoefficientsTable_RowNames ElectricVehicleImprovements 
clear WaterDesalinationImprovements Water_Desalination_Improvements Electricity_From_Gas_Improvements Electric_Vehicles_Improvements
clear i ImprovementValues NaturalGasImprovements