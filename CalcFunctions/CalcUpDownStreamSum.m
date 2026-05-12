function UpDownStreamSum_r = CalcUpDownStreamSum(TotalEmission)
    
    global BaseYear;

    % The rows of the final table
    RowNames = {'Electricity','Transportation','Food', 'Construction', 'Water', 'Fuel for Industry', 'Solid Materials (Production + Waste)', 'Total'};
    
    %% Create the Final Tables
    % Initialize result table with 13 rows and same number of columns as input
    UpDownStreamSum_r = array2table(zeros(numel(RowNames), width(TotalEmission)));
    UpDownStreamSum_r.Properties.RowNames = RowNames;
    
    %% Calculate the emission per Category - To each Year
    for i = 1:width(UpDownStreamSum_r)
        UpDownStreamSum_r{1,i} = sum(TotalEmission{[1,2], i});
        UpDownStreamSum_r{2,i} = sum(TotalEmission{[3,4], i});
        UpDownStreamSum_r{3,i} = sum(TotalEmission{[5,6], i});
        UpDownStreamSum_r{4,i} = sum(TotalEmission{[7,8], i});
        UpDownStreamSum_r{5,i} = sum(TotalEmission{[9,10], i});
        UpDownStreamSum_r{6,i} = TotalEmission{11, i};
        UpDownStreamSum_r{7,i} = TotalEmission{12, i};
        UpDownStreamSum_r{8,i} = TotalEmission{13, i};
    end

    % Set column names as years, starting from BaseYear
    ColumnNames = cell(1,width(TotalEmission));
    for i=1:width(TotalEmission)
        s1 = num2str(i+BaseYear-1); % changed
        ColumnNames{i} = s1;
    end
    UpDownStreamSum_r.Properties.VariableNames = ColumnNames;
end