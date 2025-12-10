%% =====================================================================
% Plot_Total_Emissions_Over_Time.m
% גרפי פליטה טוטאלית לאורך השנים לכל הערים ולכל התרחישים
%% =====================================================================

addpath('helpers');

cityNames = fieldnames(AllCities);
cities    = struct2cell(AllCities);
nCities   = numel(cities);

scenarios = {'BAU','Moderate','Advanced'};

yearLabels = cities{1}.TotalResults.Properties.VariableNames;
nYears     = numel(yearLabels);

% ממירים yearLabels למספרים (ליתר ביטחון)
yearsNum = str2double(yearLabels);

%% שורות הפליטה הכוללת בכל תרחיש
rows.Emission_Total = [7 8 9];   % BAU / Moderate / Advanced

colors = lines(nCities);

%% --- לולאה על תרחישים ---
for s = 1:numel(scenarios)

    scenName = scenarios{s};
    rowIdx   = rows.Emission_Total(s);

    figure('Name',['Total Emissions Over Time – ' scenName], ...
           'Color','w', 'Units','pixels', 'Position',[150 150 1200 600]);

    hold on;

    for c = 1:nCities
        TR = cities{c}.TotalResults;

        yVals = TR{rowIdx, :};   % הפליטה לכל השנים (שורה מלאה)
        xVals = yearsNum;        % השנים בפועל (2019–2050)

        scatter(xVals, yVals, 35, 'MarkerEdgeColor', colors(c,:), ...
                'DisplayName', cityNames{c});

        plot(xVals, yVals, '-', 'Color', colors(c,:), 'LineWidth', 1.6);
    end

    hold off;

    xlabel('Year');
    ylabel('Total Emissions (MtCO2eq)');
    title(['Total Emissions Over Time – ' scenName]);

    grid on;
    box off;

    legend('Location','bestoutside');

end

disp('✔ סיימתי להפיק את Total Emissions Over Time.');
