 function UpDownStreamEmissions = CalcUpDownStream(EmissionsByYears)
    
    global BaseYear;

    % The rows of the final table
    RowNames = {'Electricity-Local', 'Electricity-Global','Transportation-Local','Transportation-Global','Food-Local','Food-Global', 'Construction-Local','Construction-Global', 'Water-Local','Water-Global', 'Fuel for Industry - Local','Total'};%%'6 Food-Global'
    
    %% Create the Final Tables
    % Initialize result table with 12 rows and same number of columns as input
    UpDownStreamEmissions = array2table(zeros(numel(RowNames), width(EmissionsByYears)));
    UpDownStreamEmissions.Properties.RowNames = RowNames;
    
    %% Calculate the emission per Category - To each Year
    for i = 1:width(UpDownStreamEmissions)

        % Electricity - Local: sum emissions from sub-sector rows 1 to 4, column 9
        %UpDownStreamEmissions{1,i} = sum(EmissionsByYears{2,i}{1,1}{1:4,9})/1000000;
        UpDownStreamEmissions{1,i} = sum(EmissionsByYears{2,i}{1,1}{1:5,9})/1000000;
        % Electricity - Global: sum all rows, column 7
        UpDownStreamEmissions{2,i} = sum(EmissionsByYears{3,i}{1,1}{:,7})/1000000;
        
        % Transportation - Local: sum two local transport columns
        UpDownStreamEmissions{3,i} = (sum(EmissionsByYears{4,i}{1,1}{:,16}) + sum(EmissionsByYears{5,i}{1,1}{:,12}))/1000000;
        % Transportation - Global: sum all global rows and one local fallback row
        %UpDownStreamEmissions{4,i} = (sum(EmissionsByYears{6,i}{1,1}{:,7}) + EmissionsByYears{2,i}{1,1}{5,9})/1000000;
        UpDownStreamEmissions{4,i} = (sum(EmissionsByYears{6,i}{1,1}{:,7}))/1000000;
      
        % % Construction - Local: sum rows 11–12, column 2
        % UpDownStreamEmissions{7,i} = sum(EmissionsByYears{7,i}{1,1}{11:12,2})/1000000;
        % % Construction - Global: row 13, column 2
        % UpDownStreamEmissions{8,i} = sum(EmissionsByYears{7,i}{1,1}{13,2})/1000000;

        %Lidor's addition (for the construction that we changed
        UpDownStreamEmissions{7,i} = sum(EmissionsByYears{7,i}{1,1}{1:11,6})/1000000;
        % Construction - Global: sum rows 1-11, column 2
        UpDownStreamEmissions{8,i} = sum(EmissionsByYears{7,i}{1,1}{1:11,2})/1000000;

        % Water - Local: sum two water-related sources
        UpDownStreamEmissions{9,i} = (EmissionsByYears{10,i}{1,1}{1,2} + EmissionsByYears{2,i}{1,1}{6,9})/1000000;
        % Water - Global: specific cell
        UpDownStreamEmissions{10,i} = EmissionsByYears{2,i}{1,1}{7,9}/10^6;

        %UpDownStreamEmissions{10,i} = ((EmissionsByYears{11,i}{1,1}{1,3} + EmissionsByYears{11,i}{1,1}{1,4})*(0.51+0.4)*(888.07+0.00944*28+0.1408*265))/(1000000*100000) ;%%The amount of global water, under the assumption that all of it is natural water, times the electricity production costs of natural water times the emissions they produce 
      
        %%old water
        %%UpDownStreamEmissions{7,i} = (sum(EmissionsByYears{8,i}{1,1}{:,3}) + sum(EmissionsByYears{9,i}{1,1}{2,:}) + sum(EmissionsByYears{9,i}{1,1}{6,:}) + sum(EmissionsByYears{9,i}{1,1}{10,:}))/1000000; %% fuels in production
        %%UpDownStreamEmissions{7,i} = (UpDownStreamEmissions{7,i} + sum(EmissionsByYears{9,i}{1,1}{:,12}))/1000000; %% added downstream
    
        % Food - Local: sum columns 1–2 of row 1
        UpDownStreamEmissions{5,i} = sum(EmissionsByYears{1,i}{1,1}{1,1:2})/1000000;
        % Food - Global: sum columns 3–5 of row 1
        UpDownStreamEmissions{6,i} = sum(EmissionsByYears{1,i}{1,1}{1,3:5})/1000000;

        % Fuel for Industry - Local: sum all columns in row 1, and specific cells in rows 2,3
        UpDownStreamEmissions{11,i} = (sum(EmissionsByYears{9,i}{1,1}{1,:})+EmissionsByYears{9,i}{1,1}{2,6}+EmissionsByYears{9,i}{1,1}{3,6})/1000000;

    end
    


    % Compute total upstream + downstream emissions per year (sum of rows 1–11)
    for i = 1:width(UpDownStreamEmissions)
        UpDownStreamEmissions{12,i} = sum(UpDownStreamEmissions{1:11,i});
    end   

    % Set column names as years, starting from BaseYear
    ColumnNames = cell(1,width(EmissionsByYears));
    for i=1:width(EmissionsByYears)
        s1 = num2str(i+BaseYear-1); % changed
        ColumnNames{i} = s1;
    end
    UpDownStreamEmissions.Properties.VariableNames = ColumnNames;
end