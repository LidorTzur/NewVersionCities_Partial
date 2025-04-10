function [TotalTransportationConsumptionEmissions, TotalTrainEmissions] = CalcTransportationConsumption(Data, CurrentYearTransportationConsumption,VehicleAmount)
    
    %% Read Emissions table data

    TransportationHotEmissionsCoefficients = Data.Trans_DataBase.TransportationHotEmissionsCoefficients;
    TransportationColdEmissionsCoefficients = Data.Trans_DataBase.TransportationColdEmissionsCoefficients;
    TransportationEvaporationEmissionsWhileDriving = Data.Trans_DataBase.TransportationEvaporationEmissionsWhileDriving;
    TransportationEvaporationEmissionsAfterDriving = Data.Trans_DataBase.TransportationEvaporationEmissionsAfterDriving;
    TransportationGridingEmissions = Data.Trans_DataBase.TransportationGridingEmissions;
    PassengerTrainEmissionCoefficients = Data.Trans_DataBase.PassengerTrainEmissionCoefficients;    
    FreightTrainEmissionCoefficients = Data.Trans_DataBase.FreightTrainEmissionCoefficients;    
    TransportationEvaporationEmissionsEveryDay = Data.Trans_DataBase.TransportationEvaporationEmissionsEveryDay;

    %% Define the Setting of the Emission Tables
    
    % Define the headers ('c6h6', 'ch2o', 'ch4', 'co', 'n2o', 'nh3', 'nmvoc', 'no2', 'nox', 'PM2.5', 'PM10', 'so2', 'co2', 'Fuel Consumption', 'Total Air Pollutants', 'Co2e')
    TransEmissionTypes = Data.Trans_DataBase.TransEmissionTypes;
    % Define the Vehicles types {'Bus', 'Car', 'Minibus', 'Motorcycle', 'Truck', 'LCV'}
    VehicleTypes = Data.Trans_DataBase.Vehicle_Amounts_RowNames;
    % Define the train names ('Passenger Train', 'Friehgt Train')
    Train_Names = Data.Trans_DataBase.Train_Names;
    % Define the train emission types {'c6h6', 'ch2o', 'ch4', 'co', 'n2o', 'nh3', 'nmvoc', 'no2', 'nox', 'PM2.5', 'PM10', 'so2', 'co2', 'Fuel Consumption', 'Total Air Pollutants', 'Co2e'}
    Train_EmissionTypes = Data.Trans_DataBase.Train_EmissionTypes;

    % Define the col and row number (15*7)
    TransEmissionNumRows = Data.Trans_DataBase.TransEmissionNumRows; % First row is a header
    TransEmissionNumCols = Data.Trans_DataBase.TransEmissionNumCols; % Last col- The sum of the row
    MainEmissionTypesRows = Data.Trans_DataBase.MainEmissionTypesRows;

    % Define the tables (15*7)
    HotEmissionsTon = zeros(TransEmissionNumRows ,TransEmissionNumCols);
    ColdEmissionsTon = zeros(TransEmissionNumRows ,TransEmissionNumCols);
    EvaporationEmissionsWhileDrivingTon = zeros(TransEmissionNumRows ,TransEmissionNumCols);
    EvaporationEmissionsAfterDrivingTon = zeros(TransEmissionNumRows ,TransEmissionNumCols);
    EvaporationEmissionsEveryDayTon = zeros(TransEmissionNumRows ,TransEmissionNumCols);
    GridingEmissionsTon = zeros(TransEmissionNumRows ,TransEmissionNumCols);

    %% Calculate the all types of emission to the transportation (all kind but train)

    for i=1:height(CurrentYearTransportationConsumption)-2 %% vehicle types (all but train)

            TotalHotEmissionsTonAirPollutants=0;
            TotalEvaporationEmissionsWhileDrivingTonAirPollutants=0;
            TotalGridingEmissionsTonAirPollutants=0;

            % Running on the emission types
            for j=1:(TransEmissionNumRows-1) % First row is a header
                
                % Calculate emissions in Tons by the transportation consumption
                HotEmissionsTon(j,i) = CurrentYearTransportationConsumption(i)*TransportationHotEmissionsCoefficients(j,i)/1000000;
                EvaporationEmissionsWhileDrivingTon(j,i) = CurrentYearTransportationConsumption(i)*TransportationEvaporationEmissionsWhileDriving(j,i)/1000000;
                GridingEmissionsTon(j,i) = CurrentYearTransportationConsumption(i)*TransportationGridingEmissions(j,i)/1000000;
                
                if (j<=MainEmissionTypesRows)
                    TotalHotEmissionsTonAirPollutants=TotalHotEmissionsTonAirPollutants+HotEmissionsTon(j,i);
                    TotalEvaporationEmissionsWhileDrivingTonAirPollutants=TotalEvaporationEmissionsWhileDrivingTonAirPollutants+EvaporationEmissionsWhileDrivingTon(j,i);
                    TotalGridingEmissionsTonAirPollutants=TotalGridingEmissionsTonAirPollutants+GridingEmissionsTon(j,i);
                end

            end

            HotEmissionsTon(j+1,i) = TotalHotEmissionsTonAirPollutants;
            EvaporationEmissionsWhileDrivingTon(j+1,i) = TotalEvaporationEmissionsWhileDrivingTonAirPollutants;
            GridingEmissionsTon(j+1,i) = TotalGridingEmissionsTonAirPollutants;
    end

    for i=1:width(VehicleAmount)
            TotalColdEmissionsTonAirPollutants=0;
            TotalEvaporationEmissionsAfterDrivingTonAirPollutants=0;
            TotalEvaporationEmissionsEveryDayTonAirPollutants=0;
            for j=1:(TransEmissionNumRows-1)
                ColdEmissionsTon(j,i) = VehicleAmount(5,i)*TransportationColdEmissionsCoefficients(j,i)/1000000;
                EvaporationEmissionsAfterDrivingTon(j,i) = VehicleAmount(5,i)*TransportationEvaporationEmissionsAfterDriving(j,i)/1000000;
                EvaporationEmissionsEveryDayTon(j,i) = VehicleAmount(6,i)*TransportationEvaporationEmissionsEveryDay(j,i)/1000000;
                if (j<=MainEmissionTypesRows)
                    TotalColdEmissionsTonAirPollutants=TotalColdEmissionsTonAirPollutants+ColdEmissionsTon(j,i);
                    TotalEvaporationEmissionsAfterDrivingTonAirPollutants=TotalEvaporationEmissionsAfterDrivingTonAirPollutants+EvaporationEmissionsAfterDrivingTon(j,i);
                    TotalEvaporationEmissionsEveryDayTonAirPollutants=TotalEvaporationEmissionsEveryDayTonAirPollutants+EvaporationEmissionsEveryDayTon(j,i);
                end
            end
            ColdEmissionsTon(j+1,i) = TotalColdEmissionsTonAirPollutants;
            EvaporationEmissionsAfterDrivingTon(j+1,i) = TotalEvaporationEmissionsAfterDrivingTonAirPollutants;
            EvaporationEmissionsEveryDayTon(j+1,i) = TotalEvaporationEmissionsEveryDayTonAirPollutants;
    end
    
    RowNames = VehicleTypes;
    % (6*16 Table)
    TotalTransportationConsumptionEmissions = array2table(zeros(numel(RowNames),numel(TransEmissionTypes)), 'RowNames', RowNames);
    TotalTransportationConsumptionEmissions.Properties.VariableNames = TransEmissionTypes;

    for i=1:height(TotalTransportationConsumptionEmissions) %% 1-6
        for j=1:width(TotalTransportationConsumptionEmissions)-1 %% 1-15
            TotalTransportationConsumptionEmissions{i,j}=HotEmissionsTon(j,i)+ColdEmissionsTon(j,i)+EvaporationEmissionsWhileDrivingTon(j,i)+EvaporationEmissionsAfterDrivingTon(j,i)+EvaporationEmissionsEveryDayTon(j,i)+GridingEmissionsTon(j,i);
        end
    end
    
    %% Train
    RowNames = Train_Names;
    TotalTrainEmissions = array2table(zeros(numel(Train_Names),numel(Train_EmissionTypes)),'RowNames',RowNames);
    TotalTrainEmissions.Properties.VariableNames = Train_EmissionTypes;
    for i=1:width(TotalTrainEmissions)-1
        TotalTrainEmissions{1,i} = PassengerTrainEmissionCoefficients(i)*CurrentYearTransportationConsumption(7)/1000000;
        TotalTrainEmissions{2,i} = FreightTrainEmissionCoefficients(i)*CurrentYearTransportationConsumption(8)/1000000;
    end
    for i = 1:height(TotalTrainEmissions)
        TotalTrainEmissions{i,12} = TotalTrainEmissions{i,9}*28+TotalTrainEmissions{i,11};
    end    
    
    for i=1:height(TotalTransportationConsumptionEmissions) %% 1-6
        TotalTransportationConsumptionEmissions{i,width(TotalTransportationConsumptionEmissions)}=TotalTransportationConsumptionEmissions{i,3}*28+TotalTransportationConsumptionEmissions{i,5}*265+TotalTransportationConsumptionEmissions{i,13};
    end
end
