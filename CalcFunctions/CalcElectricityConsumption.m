function [TotalElectricityConsumptionEmissions, CurrentYearTotal] = CalcElectricityConsumption(Data, CurrentYearConsumption,ElectricityConsumptionPercentages, WasteIncinaration, year)

% Description:
%   Calculates total emissions resulting from electricity consumption by sector and energy source.

% Inputs:
%   CurrentYearConsumption       - Electricity consumption per sector (KWh).
%   ElectricityConsumptionPercentages - Share of each energy source used for electricity generation.
%   WasteIncinaration            - Amount of waste incinerated for electricity.
%   year                         - Current simulation year (for time-based emission updates).

% Outputs:
%   TotalElectricityConsumptionEmissions - Table with emissions (tons) by sector and pollutant.
%   CurrentYearTotal                    - Vector of total KWh per energy source.
    
    %% Inputs
    % Emissions From Mining, Manufacturing Etc Fuels (g/KWh)
    Emissions = Data.Electricity_DataBase.EmissionsFromElectricityConsumption; 
    % 'Co2', 'CH4', 'Nitrous Oxide (N2O)', 'NOX', 'PM', 'SO2', 'Other Air Pollutants', 'Sewage', 'Co2e'
    ElectricityEmissionTypes = Data.Electricity_DataBase.ElectricityEmissionTypes;
    EmissionsCoefficientsForPv = Data.EmissionsCoefficientsForPv;

    %% Create Table of total emmisions by electricity and energy source
    RowNames = {'Home', 'Public & Commercial', 'Industrial', 'Other', 'Transportation', 'Water Local','Water Global','Total'};
    ColNames = {'KWh From Coal', 'KWh From Natural Gas', 'KWh From Renewable Energies', 'KWh From Soler', 'KWh From Mazut', 'KWh From Waste Incinaration'};
    CurrentYear = zeros(numel(RowNames),numel(ColNames));
    CurrentYear = array2table(CurrentYear, 'RowNames', RowNames);
    CurrentYear.Properties.VariableNames = ColNames;

    %% KWH from sources     
    Total=0;
    
    for j=1:width(CurrentYear)-1
        for i=1:height(CurrentYear)-1
            CurrentYear{i,j} = CurrentYearConsumption(i)*ElectricityConsumptionPercentages(j); % KWH from sources
            Total = Total + CurrentYear{i,j};
        end
        CurrentYear{i+1,j} = Total;
        Total=0;
    end

    KwhFromInciniration = Data.Electricity_DataBase.WasteToElectricity*WasteIncinaration;
    
    if(CurrentYear{8,1} > KwhFromInciniration)
        CurrentYear{8,1} = CurrentYear{8,1}-KwhFromInciniration;
    else
        KwhFromInciniration = CurrentYear{8,1};
        CurrentYear{:,1} = 0;
    end

    CurrentYear{8,6} = KwhFromInciniration;
    CurrentYearTotal = table2array(CurrentYear('Total',:))';


    %% Total Emissions Tables (emission factors * consumption)

    NumOfSources = numel(Data.Electricity_DataBase.ElectricityBySources_row_names)-1;
    
    for Table=1:NumOfSources %( Create 6 tables (named Temp) for - Coal, Natural Gas, Renewable Energies, Soler, Mazut, Burning Waste)
        Temp = zeros(numel(RowNames),numel(ElectricityEmissionTypes)); 
        Temp = array2table(Temp, 'RowNames', RowNames);
        Temp.Properties.VariableNames = ElectricityEmissionTypes;

        %%% Lidor's adding
        %%%%%%% We need To change the electricity consumption by PV- its not like they did in the project!!!!!!
        % maybe we need to add the consumption to the electricity
        % consumption in the excel, or change it here somehow
        
        % Fill the right emission values of renewable energies by the year
        if Table == 3 % Renewable energies
            CurrentYearIndex = find(EmissionsCoefficientsForPv{:,1} == year, 1); 
            if ~isempty(CurrentYearIndex)
                Emissions(3,1) = EmissionsCoefficientsForPv{CurrentYearIndex,2};
                %disp('Emissions From Electricity Consumption');
                %disp(Emissions(:,:));
            end
        end


        for j=1:width(Temp)-1
            for i=1:height(Temp)                
                Temp{i,j} = Emissions(Table,j)*CurrentYear{i,Table}/1000000; %% tons
            end
        end
        for i=1:height(Temp)
            Temp{i,9}=Temp{i,1}+Temp{i,2}*28+Temp{i,3}*265; %Temporary - convert to ECo2
        end
        switch Table
        case 1
            CoalEmissions=Temp;
        case 2
            NaturalGasEmissions=Temp;
        case 3
            RenewableEnergiesEmissions=Temp;
        case 4
            SolerEmissions=Temp;
        case 5
            MazutEmissions=Temp;
        case 6
            IncinarationEmissions = Temp;
        end
    end
    %disp('Emissions From Electricity Consumption - RenewableEnergiesEmissions');
    %disp(RenewableEnergiesEmissions);
    
    
    TotalElectricityConsumptionEmissions = array2table(zeros(numel(RowNames),numel(ElectricityEmissionTypes)), 'RowNames', RowNames);
    TotalElectricityConsumptionEmissions.Properties.VariableNames = ElectricityEmissionTypes;
    for i=1:height(TotalElectricityConsumptionEmissions)
        for j=1:width(TotalElectricityConsumptionEmissions)
            TotalElectricityConsumptionEmissions{i,j} = CoalEmissions{i,j} + NaturalGasEmissions{i,j}+RenewableEnergiesEmissions{i,j}+SolerEmissions{i,j}+MazutEmissions{i,j}+IncinarationEmissions{i,j};
        end
    end
    
    
end

