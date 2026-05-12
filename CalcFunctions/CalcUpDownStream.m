 function UpDownStreamEmissions = CalcUpDownStream(EmissionsByYears)
    
    global BaseYear;

    % The rows of the final table
    RowNames = {'Electricity-Local', 'Electricity-Global','Transportation-Local','Transportation-Global','Food-Local','Food-Global', 'Construction-Local','Construction-Global', 'Water-Local','Water-Global', 'Fuel for Industry - Local', 'Solid Materials (Production + Waste) - Global', 'Total'};%%'6 Food-Global'
    
    %% Create the Final Tables
    % Initialize result table with 13 rows and same number of columns as input
    UpDownStreamEmissions = array2table(zeros(numel(RowNames), width(EmissionsByYears)));
    UpDownStreamEmissions.Properties.RowNames = RowNames;
    
    %% Calculate the emission per Category - To each Year
    for i = 1:width(UpDownStreamEmissions)

        % Electricity - Local:
        UpDownStreamEmissions{1,i} = sum(EmissionsByYears{2,i}{1,1}{1:5,9})/1000000;
        % Electricity - Global: 
        UpDownStreamEmissions{2,i} = sum(EmissionsByYears{3,i}{1,1}{:,7})/1000000;
        
        % Transportation - Local: 
        UpDownStreamEmissions{3,i} = (sum(EmissionsByYears{4,i}{1,1}{:,16}) + sum(EmissionsByYears{5,i}{1,1}{:,12}))/1000000;
        % Transportation - Global: 
        UpDownStreamEmissions{4,i} = (sum(EmissionsByYears{6,i}{1,1}{:,7}))/1000000; %sum all global rows and one local fallback row
      

        %Lidor's addition (for the construction that we changed)
        % construction - Local
        UpDownStreamEmissions{7,i} = sum(EmissionsByYears{7,i}{1,1}{1:11,6})/1000000;
        % Construction - Global: 
        UpDownStreamEmissions{8,i} = sum(EmissionsByYears{7,i}{1,1}{1:11,7})/1000000;

        % Water - Local: sum two water-related sources
        UpDownStreamEmissions{9,i} = (EmissionsByYears{10,i}{1,1}{1,2} + EmissionsByYears{2,i}{1,1}{6,9})/1000000;
        % Water - Global: specific cell
        UpDownStreamEmissions{10,i} = EmissionsByYears{2,i}{1,1}{7,9}/10^6;

        % Food - Local: 
        UpDownStreamEmissions{5,i} = sum(EmissionsByYears{1,i}{1,1}{1,1:2})/1000000;
        % Food - Global: 
        UpDownStreamEmissions{6,i} = sum(EmissionsByYears{1,i}{1,1}{1,3:5})/1000000;

        % Fuel for Industry - Local: 
        UpDownStreamEmissions{11,i} = (sum(EmissionsByYears{9,i}{1,1}{1,:})+EmissionsByYears{9,i}{1,1}{2,6}+EmissionsByYears{9,i}{1,1}{3,6})/1000000;
        
        % Solid Materials Production + Waste - GLOBAL
        UpDownStreamEmissions{12,i} = sum(EmissionsByYears{11,i}{1,1}{1:13,5})/1000000;


    end
    


    % Compute total upstream + downstream emissions per year (sum of rows 1–12)
    for i = 1:width(UpDownStreamEmissions)
        UpDownStreamEmissions{(numel(RowNames)),i} = sum(UpDownStreamEmissions{1:(numel(RowNames)-1),i});
    end   

    % Set column names as years, starting from BaseYear
    ColumnNames = cell(1,width(EmissionsByYears));
    for i=1:width(EmissionsByYears)
        s1 = num2str(i+BaseYear-1); % changed
        ColumnNames{i} = s1;
    end
    UpDownStreamEmissions.Properties.VariableNames = ColumnNames;
end