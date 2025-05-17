function [Area, Costs, Water] = CalcTotalResources(Resources, ConsumptionAmounts, WaterFromFood)

   global BaseYear

   %% Create the Resurces Tables

   % Set row labels for each table
    Area_RowNames = {'Electricity- Local', 'Food - Local', 'Food - Gloabl', 'Construction - Local', 'Total'};
    Costs_RowNames = {'Operating Costs', 'Setting Costs', 'Fuels Costs', 'Cost of Area for PV', 'Total'};
    Water_RowNames = {'Ground Water', 'Desalinated Water', 'Brackish & Reservoirs Water', 'Treated Wastewater', 'Global Water'};

    % Initialize output tables for Area (m²), Costs (billion currency units), and Water (million m³)
    Area = array2table(zeros(numel(Area_RowNames),width(Resources)));
    Costs = array2table(zeros(numel(Costs_RowNames),width(Resources)));
    Water = array2table(zeros(numel(Water_RowNames),width(Resources)));

    Area.Properties.RowNames = Area_RowNames;
    Costs.Properties.RowNames = Costs_RowNames;
    Water.Properties.RowNames = Water_RowNames;

    %% Generate column names as years starting from BaseYear
    ColumnNames = ones(1,width(Resources)); % Make the same number of Years
    for i = 1:width(ColumnNames) % For each Year
        ColumnNames(i) = BaseYear-1+i; % Name of the column (Year)
    end
    ColumnNames = string(ColumnNames);
    Area.Properties.VariableNames = ColumnNames;
    Costs.Properties.VariableNames = ColumnNames;
    Water.Properties.VariableNames = ColumnNames;

    %% % Pre-allocate helper arrays - Vectors for all Years
    OperatingCostsSum = zeros(1,width(Area));
    SettingCostsSum = zeros(1,width(Area));
    AreaElectricity = zeros(1,width(Area));
    AreaElectricityOfDualPV = zeros(1,width(Area));
    AreaConstruction = zeros(1,width(Area));
    PVAreaCost = zeros(1,width(Area));
    FuelCost = zeros(1,width(Area));

    %% Loop over each year
    for i = 1:length(OperatingCostsSum)
       % if i == 34
       %    check =1 ;
       % end
       %OperatingCostsSum(i) = Resources{4,i}{1}{6,1}/10^9;
       %SettingCostsSum(i) = Resources{5,i}{1}{6,1}/10^9;
       %PVAreaCost(i) = sum(Resources{7,i}{1}{1,:})/10^9;
       %FuelCost(i) = sum(Resources{6,i}{1}{:,1})/10^9;
        
        % Area of this year for Dual 
        AreaElectricity(i) = sum(Resources{1,i}{1}{1,:}) - Resources{1,i}{1}{1,4} ; % sum of area for this year minus the DUAL
        AreaElectricityOfDualPV(i) = Resources{1,i}{1}{1,4}; % the area needed for dual PV only
        if i > 1 % cumulative Year sum
            AreaElectricity(i) = AreaElectricity(i) + AreaElectricity(i-1);
            AreaElectricityOfDualPV(i) = AreaElectricityOfDualPV(i) + AreaElectricityOfDualPV(i-1);
        end

        % Area from contruction
        AreaConstruction(i) = Resources{8,i}{1};

    end

    %% The Area Table
    for i = 1:width(Area) % To all years

        %Area{1,i} = sum(AreaElectricity(1:i));
        Area{1,i} = AreaElectricity(1,i);
        Area{2,i} = Resources{3,i}{1}{height(Resources{3,i}{:,1}),1};
        Area{3,i} = Resources{3,i}{1}{height(Resources{3,i}{:,1}),2};

        % Costs{1,i} = Resources{4,i}{1}{6,1}/10^9;
        % Costs{2,i} = Resources{5,i}{1}{6,1}/10^9;
        % Costs{3,i} = sum(Resources{6,i}{1}{:,1})/10^9;
        % Costs{4,i} = sum(Resources{7,i}{1}{1,:})/10^9;

        Costs{1,i} = 0;
        Costs{2,i} = 0;
        Costs{3,i} = 0;
        Costs{4,i} = 0;
    end
    
    % Add construction area
    Area{4,:} = AreaConstruction;

    %% The Water table
    for i = 1:width(Water) % To all years
        %%Water{1:5,i} = ((ConsumptionAmounts.(i){1,1}{7,1:5}))';
         Water{1,i} = ConsumptionAmounts.(i){1,1}{1,5}; % Drilling Water
         Water{2,i} = ConsumptionAmounts.(i){1,1}{1,8}; % Desilinated Water
         %Water{3,i} = 250;
         Water{3,i} = ConsumptionAmounts.(i){1,1}{1,7}; % Breckish Water
         Water{4,i} = ConsumptionAmounts.(i){1,1}{1,6}; % Treated wastewater
         Water{5,i} = sum(WaterFromFood{1,i}{1,3:4})/10^6; % Global water from food (million m³)

    end    

    %% Sun to all tables
    for i = 1:width(Area) % To all Years
        Area{5,i} = sum(Area{1:4,i});
        Costs{5,i} = sum(Costs{1:4,i});       
        Water{6,i} = sum(Water{1:4,i});
    end    

end