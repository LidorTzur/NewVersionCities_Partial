function [AllButOneScenariosTable] = AllButOneChangesByScenarios(Data, ScenarioNumber, Years, S, varargin)
% מודל שמחשב את ההשפעה של תסריטים (Scenarios) על שינוי של פרמטרים במשק לאורך מספר שנים.
% הפלט הוא טבלה AllButOneScenariosTable שמכילה לכל פרמטר ולכל שנה את אחוז השינוי המצטבר.
% This function calculates the changes in various sectors (such as electricity consumption, food loss,
% renewable energy, electric vehicles, etc.) based on a given scenario.
% It then returns a table containing the results for each scenario, year by year.
% Inputs:
% - Data: A struct containing all the necessary data (The database)
% - ScenarioNumber: The scenario being analyzed (e.g., 1 for Population Growth, 2 for Increased Electricity)
% - Years: The number of years in the analysis period (e.g., from 2020 to 2050)
% - S: A vector containing the percentage change values for each sector
% - varargin: Optional parameters (e.g., 'OnlyOne' for a single scenario, 'MileStones' for milestone tracking)

% The 'MileStones' option allows the user to define specific milestone values for each parameter.
% If set to true, the user will be prompted to enter values for changes at specific years,
% enabling tracking of these intermediate targets over the years.

%% Inputs
global BaseYear; 
current_food_lost_global = Data.Food_DataBase.current_food_lost; % The global assumption that 33% of food manufactured is lost
current_Recycled_global = Data.Materials_DataBase.Recycle_Perc;

% Bring to current situation - 2020 (or 2025 if i have the data)
YearsAfterAnalysis = Data.Electricity_DataBase.CurrentYearReal - BaseYear; 
RenewableEnergies = Data.Electricity_DataBase.RenewableEnergies_CurrentYear; % Percentage of renewable energy
NaturalGas = Data.Electricity_DataBase.NaturalGas_CurrentYear; % Percentage of natural gas

% Define the current situation of energy consumption based on data (e.g., electricity consumption)
CurrentEnergyConsumptionFromRenewableEnergies = Data.Electricity_DataBase.InitialPercentage(3); % 0.05
CurrentEnergyConsumptionFromNaturalGas = Data.Electricity_DataBase.InitialPercentage(2); % 0.636

% Initialize input parser for handling optional parameters
q = inputParser;
% Adding optional parameters, if not provided, the default is false
addOptional(q, 'OnlyOne', false); % If only one scenario should be analyzed
addOptional(q, 'MileStones', false); % If milestone tracking is required

% Parse the provided arguments and assign them to the q object
parse(q, varargin{:});


%% Prepare data for analysis

% Define row names for each parameter (e.g., population growth, food loss, electric vehicles, etc.)
RowNames = Data.ScenarioRowNames;
ChangesNumRows = numel(RowNames); % Number of rows for each parameter
ColumnNames = ones(1, Years); % Initial column names (years)
AllButOneScenariosTable = array2table(zeros(length(S), Years), 'RowNames', RowNames); 

% Years as column names
for i = 1:width(ColumnNames)
    ColumnNames(i) = (BaseYear-1) + i; % Assign year labels starting from BaseYear
end
ColumnNames = string(ColumnNames); % Convert to string format
AllButOneScenariosTable.Properties.VariableNames = ColumnNames; 

%% Choose measures for each scenario based on user input

% Default setting for steps (can be changed depending on the input)
ChooseSteps = 6; 

% If the user choose to run only one scenario - we choose only that one, otherwise we run all the scenario
% exept the ScenarioNumber the user gave us 
if(ScenarioNumber ~= 0 && q.Results.OnlyOne == true)
    ChooseSteps = [ScenarioNumber]; % If only one scenario is chosen, use that scenario
elseif(ScenarioNumber ~= 0 && q.Results.OnlyOne == false)
    Delete = ScenarioNumber;
    ChooseSteps = 1:1:length(S); % Include all steps except the chosen one
    ChooseSteps(Delete) = [];
end

%% Insert Manual Milstone values for choosen years by the User
% אצלנו לא ראיתי ששומש הקטע הזה כי אנחנו תמיד שולחים פלס למיילסטון
%  User Input: Handle Milestones for each parameter (e.g., set targets for changes)
% Create an empty table for milestone values and then fill the milestone values to the choosen years
MilesTonesTable = array2table(zeros(ChangesNumRows, Years));
if(q.Results.MileStones == true)
    for i = 1:height(AllButOneScenariosTable)
        if(~ismember(i, ChooseSteps))
            continue; % Skip if the current parameter is not selected
        end
        defvalues = cell(1, Years); % Initialize default values as '0'
        defvalues(:) = {'0'};
        formatspec = 'Milestones in Measure %s'; 
        title = sprintf(formatspec, RowNames{1,i}); % Title for the milestone prompt
        dims = [1 35];
        prompt = {'Enter year then value'};
        answer = inputdlg(prompt, title, dims, defvalues, 'on');
        answer = answer{1};
        if(strcmp(answer, '0')) % If '0' is entered, skip milestone for this parameter
            continue;
        else     
            user_val = strsplit(answer, ', '); % Split the input into year-value pairs
            temp = zeros(1, length(user_val)); % Initialize temporary array
            for j = 1:length(temp)
                temp(j) = str2double(user_val{j}); % Convert input values to numbers
            end
            for j = 1:2:length(temp) % Set milestones for each year-value pair
                MilesTonesTable{i, temp(j)-(BaseYear-1)} = temp(j+1); 
            end  
        end
    end
end

%% ---------------------------------- This is executed from our running steps script ----------------------------------------
%%%% Calculate agg changes in consumption based on the chosen scenario and the given percentages (The scenario table)
%%% Based on the scenario excel table structure (important to keep it at the
% same structure)

AllButOneScenariosTable{1,:} = CalcChangeVector(MilesTonesTable{1,:}, Years, S(1)); % Population Growth

AllButOneScenariosTable{2,:} = CalcChangeVector(MilesTonesTable{2,:}, Years, S(2), 'Type', 'Linear'); % Increased Electricity Per Capita
AllButOneScenariosTable{3,:} = CalcChangeVector(MilesTonesTable{3,:}, Years, S(3), 'Type', 'Linear', 'Growth', false); % Desalinated Water
AllButOneScenariosTable{8,:} = CalcChangeVector(MilesTonesTable{8,:}, Years, S(8), 'Growth', false); % Electricity saving
AllButOneScenariosTable{9,:} = CalcChangeVector(MilesTonesTable{9,:}, Years, S(9), 'Growth', false); % Fuel for Energy

%%Lidor added
%AllButOneScenariosTable{10,:} = CalcChangeVector(MilesTonesTable{10,:}, Years, S(10), 'Growth', true); % Recycled Waste
AllButOneScenariosTable{11,:} = CalcChangeVector(MilesTonesTable{11,:}, Years, S(11), 'Growth', true); % Burning Waste

AllButOneScenariosTable{12,:} = CalcChangeVector(MilesTonesTable{12,:}, Years, S(12), 'Growth', false); % reducing mileage in the city
AllButOneScenariosTable{13,:} = CalcChangeVector(MilesTonesTable{13,:}, Years, S(13), 'Growth', false); % Transition To Public Transportation
AllButOneScenariosTable{19,:} = CalcChangeVector(MilesTonesTable{19,:}, Years, S(19), 'Growth', false); % Water Saving
AllButOneScenariosTable{20,:} = CalcChangeVector(MilesTonesTable{20,:}, Years, S(20), 'Growth', false); % Vegetarians

% Apply changes in supply-based sectors (such as food consumption, electricity production)
AllButOneScenariosTable{4,:} = CalcChangeVector(MilesTonesTable{4,:}, Years, S(4), 'Growth', false); % Reducing Beef Consumption

% %TargetLossPercentage = current_food_lost_global - S(5); % Adjust food loss based on the scenario- 0.33-0.16= 0.1733
% RelativeReduction = S(5) / current_food_lost_global;
% AllButOneScenariosTable{5,:} = CalcChangeVector(MilesTonesTable{5,:}, Years, RelativeReduction, 'Growth', false); % Preventing Food Loss


%% Food Loss
% 1. Calculate the remaining loss percentage (e.g., 0.1733)
TargetLossPercentage = current_food_lost_global - S(5);
% 2. Calculate the target reduction factor (e.g., 0.52)
TargetFactor = TargetLossPercentage / current_food_lost_global;
% 3. Critical step: Calculate the "S" value expected by the function
% Since the function uses (1 - S), we pass (1 - TargetFactor)
S_for_function = 1 - TargetFactor; 
% 4. Call the function
AllButOneScenariosTable{5,:} = CalcChangeVector(MilesTonesTable{5,:}, Years, S_for_function, 'Growth', false);


%% Recycled Waste
TargetRecycledPercentage = current_Recycled_global + S(10);
TargetFactor_Recycled = TargetRecycledPercentage / current_Recycled_global;
S_for_function_Recycled = TargetFactor_Recycled - 1; 
AllButOneScenariosTable{10,:} = CalcChangeVector(MilesTonesTable{10,:}, Years, S_for_function_Recycled, 'Growth', true); % Recycled Waste

%% renewable energy production
% 1. Parameters
InitialVal = CurrentEnergyConsumptionFromRenewableEnergies; % 0.05
TargetVal = S(6); % 0.80
% 2. Calculate the Ratio for CalcChangeVector, Since your function starts at 1.0, we find the ratio of 0.80/0.05 = 16
S_ratio = (TargetVal / InitialVal) - 1; 
% 3. Generate the Factor Path
RenewableFactors = CalcChangeVector(table2array(MilesTonesTable(6,:)), Years, S_ratio,'Type', 'Linear', 'Growth', true);
% 4. Convert Factors to Absolute Path (0.05 to 0.80)
AbsolutePath = RenewableFactors * InitialVal;
% 5. CREATE THE DELTA-FROM-START VECTOR
% ChangesFromStart = AbsolutePath - InitialVal;
% AllButOneScenariosTable{6,:} = ChangesFromStart;
AllButOneScenariosTable{6,:} = AbsolutePath;


% % Apply changes in natural gas consumption for electricity production
% MilesTonesTable{7, 1} = CurrentEnergyConsumptionFromNaturalGas;
% MilesTonesTable{7,Years} = S(7); % Natural gas change for final year
% %MilesTonesTable{7,YearsAfterAnalysis} = NaturalGas; % Natural gas assumption for 2023
% AllButOneScenariosTable{7,:} = CalcChangeVector(MilesTonesTable{7,:}, Years, S(7)); % Apply natural gas changes

%% 1. Parameters for Natural Gas
InitialGas = CurrentEnergyConsumptionFromNaturalGas; % e.g., 0.63
TargetGas = S(7); % The target share in 2050 (e.g., 0.20)
% 2. Calculate the Ratio for CalcChangeVector, We find the ratio between the target and the initial value.
% If it's a decrease (e.g., 0.20/0.63), S_ratio will be negative.
S_ratio_gas = (TargetGas / InitialGas) - 1; 
% 3. Generate the Factor Path
GasFactors = CalcChangeVector(table2array(MilesTonesTable(7,:)), Years, S_ratio_gas,'Type', 'Linear', 'Growth', true);
%GasFactors = CalcChangeVector(table2array(MilesTonesTable(7,:)), Years, S_ratio_gas);
% 4. Convert Factors to Absolute Path (e.g., from 0.63 down to 0.20)
AbsoluteGasPath = GasFactors * InitialGas;
% 5. CREATE THE DELTA-FROM-START VECTOR, Just like Renewables, we store the total change relative to Year 1.
% Year 1 will be 0. If the gas decreases, these will be negative numbers.
% GasChangesFromStart = AbsoluteGasPath - InitialGas;
% % 6. Final Assignment to Row 7
% AllButOneScenariosTable{7,:} = GasChangesFromStart;
AllButOneScenariosTable{7,:} = AbsoluteGasPath;


% Apply changes for electric vehicles and other transportation
AllButOneScenariosTable{14,:} = CalcChangeVector(MilesTonesTable{14,:}, Years, S(14)); % Electric Car transition
AllButOneScenariosTable{15,:} = CalcChangeVector(MilesTonesTable{15,:}, Years, S(15)); % Electric Van transition
AllButOneScenariosTable{16,:} = CalcChangeVector(MilesTonesTable{16,:}, Years, S(16)); % Electric Truck transition
AllButOneScenariosTable{17,:} = CalcChangeVector(MilesTonesTable{17,:}, Years, S(17)); % Electric Bus transition
AllButOneScenariosTable{18,:} = CalcChangeVector(MilesTonesTable{18,:}, Years, S(18)); 





%% --- Construction - Add New Scenario (Assuming it's now Row 21, 22, 23 in the scenarios table) ---
% Change in Building Type Distribution (Assuming S(21) holds the final High-Density target ratio, e.g., 0.7 for 70% HD)
% We calculate the change vector that interpolates the High-Density ratio from the current ratio to the target S(21).
% Assuming linear interpolation for the ratio itself (not the change *from* 1)
%AllButOneScenariosTable{21,:} = CalcChangeVector(MilesTonesTable{21,:}, Years, S(21), 'Type', 'Linear', 'Growth', true);
% AllButOneScenariosTable{22,:} = CalcChangeVector(MilesTonesTable{22,:}, Years, S(22), 'Type', 'Linear', 'Growth', false);
% AllButOneScenariosTable{23,:} = CalcChangeVector(MilesTonesTable{23,:}, Years, S(23), 'Type', 'Linear', 'Growth', false);
AllButOneScenariosTable{24,:} = CalcChangeVector(MilesTonesTable{24,:}, Years, S(24), 'Type', 'Linear', 'Growth', true); % Moving to a green materials

%% Apply changes in Construction distribution
BaseDistTable = Data.Const_DataBase.Building_Type_Distribution_Cell{1}; 
InitialVal_c = BaseDistTable{1, 1}; % 79% For Beer-Sheva
TargetVal_c = S(21); % 0.90 FOR Beer-Sheva
% 2. Calculate the Ratio for CalcChangeVector, Since your function starts at 1.0, we find the ratio of 0.90/0.79 = 1.13
C_ratio = (TargetVal_c / InitialVal_c) - 1; 
C_HB_Factor = CalcChangeVector(table2array(MilesTonesTable(21,:)), Years, C_ratio,'Type', 'Linear', 'Growth', true);
AbsolutePath_C = C_HB_Factor * InitialVal_c;
ChangesFromStart_C = AbsolutePath_C - InitialVal_c;
AllButOneScenariosTable{21,:} = ChangesFromStart_C;

% Get Base Year Values (2019) -- Cal on Zero
BaseFootprintTable = Data.Const_DataBase.Precent_Floor_Footprint_Cell{1}; 
baseHighFoot_ratio = (S(22) / BaseFootprintTable{1, 1}) - 1; 
baseLowFoot_ratio = (S(23) / BaseFootprintTable{1, 2}) - 1; 
HB_Factor = CalcChangeVector(table2array(MilesTonesTable(22,:)), Years, baseHighFoot_ratio,'Type', 'Linear', 'Growth', true);
LB_Factor = CalcChangeVector(table2array(MilesTonesTable(23,:)), Years, baseLowFoot_ratio,'Type', 'Linear', 'Growth', true);
HB_ChangesFromStart_C = (HB_Factor * BaseFootprintTable{1, 1}) - BaseFootprintTable{1, 1};
LB_ChangesFromStart_C = (LB_Factor * BaseFootprintTable{1, 2}) - BaseFootprintTable{1, 2};
AllButOneScenariosTable{22,:} = HB_ChangesFromStart_C;
AllButOneScenariosTable{23,:} = LB_ChangesFromStart_C;
% BECAUSE THE CALL ON ZERO WE WILL DO THAT
AllButOneScenariosTable{22,:} = 1;
AllButOneScenariosTable{23,:} = 1;


% For the all other categories floors number
AllButOneScenariosTable{25,:} = CalcChangeVector(MilesTonesTable{25,:}, Years, S(25), 'Type', 'Linear', 'Growth', true);
AllButOneScenariosTable{26,:} = CalcChangeVector(MilesTonesTable{26,:}, Years, S(26), 'Type', 'Linear', 'Growth', true);
AllButOneScenariosTable{27,:} = CalcChangeVector(MilesTonesTable{27,:}, Years, S(27), 'Type', 'Linear', 'Growth', true);
AllButOneScenariosTable{28,:} = CalcChangeVector(MilesTonesTable{28,:}, Years, S(28), 'Type', 'Linear', 'Growth', true);
AllButOneScenariosTable{29,:} = CalcChangeVector(MilesTonesTable{29,:}, Years, S(29), 'Type', 'Linear', 'Growth', true);
AllButOneScenariosTable{30,:} = CalcChangeVector(MilesTonesTable{30,:}, Years, S(30), 'Type', 'Linear', 'Growth', true);
AllButOneScenariosTable{31,:} = CalcChangeVector(MilesTonesTable{31,:}, Years, S(31), 'Type', 'Linear', 'Growth', true);
AllButOneScenariosTable{32,:} = CalcChangeVector(MilesTonesTable{32,:}, Years, S(32), 'Type', 'Linear', 'Growth', true);
AllButOneScenariosTable{33,:} = CalcChangeVector(MilesTonesTable{33,:}, Years, S(33), 'Type', 'Linear', 'Growth', true);





%% Everyone but one- If there is a scenario chosen : Apply specific changes based on scenario selection
% We will neutralize the effect of the chosen scenario by changing all the factors except this one.
if(q.Results.OnlyOne == false && ScenarioNumber ~= 0)
    switch ScenarioNumber
        case 1
            AllButOneScenariosTable{1,:} = 1; % Population Growth scenario
            AllButOneScenariosTable{3,:} = 1; % Desalinated Water scenario
        case 2
            AllButOneScenariosTable{2,:} = 1; % Increased Electricity scenario
        case 4
            AllButOneScenariosTable{4,:} = 1; % Reducing Beef Consumption
        case 5
            AllButOneScenariosTable{5,:} = 1; % Preventing Food Loss
        case 6
            AllButOneScenariosTable{7,:} = AllButOneScenariosTable{6,:}; % Renewable energy becomes equal to natural gas
            AllButOneScenariosTable{6,:} = CurrentEnergyConsumptionFromRenewableEnergies; % Reset renewable energy to current value
        case 7
            AllButOneScenariosTable{7,:} = CurrentEnergyConsumptionFromNaturalGas; % Reset natural gas to current value
            for i = 1:Years
                if(AllButOneScenariosTable{6,i} > (1 - CurrentEnergyConsumptionFromNaturalGas))
                    AllButOneScenariosTable{6,i} = (1 - CurrentEnergyConsumptionFromNaturalGas);
                end    
            end    
        case 8
            AllButOneScenariosTable{8,:} = 1; % Transition to public transportation
        case 9
            AllButOneScenariosTable{9,:} = 1; % Recycling waste
        case 10
            AllButOneScenariosTable{10,:} = 1; % Burning waste
        case 12
            AllButOneScenariosTable{12,:} = 1; % Reduction of mileage
        case 13
            AllButOneScenariosTable{13,:} = 1; % Vegetarian transition
        otherwise
    end

%% OnlyOne scenario: Checks if the 'OnlyOne' option is set to true.
% If true, only the selected scenario (ScenarioNumber) will be applied, 
% and all other scenarios will be set to default values (typically 1 or 0).
% This allows for focusing on a single scenario at a time.
% Parameters set to 0 have no effect (e.g., electric vehicles are not yet present). 
% Parameters set to 1 retain their current effect over the years. 
% Some parameters represent changes, others introduce new conditions (e.g., transition to electric transport).
elseif(q.Results.OnlyOne == true)
    % EV transitions are set to zero in single scenario mode to fully isolate the effect of the chosen scenario
    ZerosLines = Data.EvSenarioLines; 
    flag = false;
    for j = 1:height(AllButOneScenariosTable)
        if(j == ScenarioNumber)
            flag = true;
        elseif(ismember(j, ZerosLines))
            AllButOneScenariosTable{j,:} = 0; % Reset to 0 if the line is in ZerosLines
        else
            if(flag == true && j == 3)
                continue; % Skip population growth if it's the selected scenario
            else
                AllButOneScenariosTable{j,:} = 1; % Set to 1 for other scenarios
            end    
        end
    end
end

end



%% other functions

% CalcChangeVector: This function calculates the change for different parameters (e.g., population growth, renewable energy, etc.) 
% over a period of years based on the selected calculation type (Exponential, Linear, or Step).
% The function checks the 'Type' argument to decide which method to use for calculating the changes.
% It calls the corresponding calculation function based on the user's choice or defaults to zeros if an invalid type is provided.
% הערך שמתקבל מ־ CalcChangeVector לא מייצג את אחוז האובדן, אלא את פקטור ההכפלה של האובדן לאורך זמן, לדוגמה:
% שנה 1: 100% מהאובדן המקורי (33%)
% שנה אחרונה: ~40% ממנו (13%)
% כל שנה הערך הוא האחוז שנשאר מהאובד המקורי (נגיד 0.8 אומר שנשאר שהאובדן
% לאותה שנה הוא 80% מהאובדן בשנה הראשונה שהיא 33%).
function PercentVector = CalcChangeVector(MileStoneVector, Years, S, varargin)
    p = inputParser;
    addOptional(p, 'Type', 'Exponential'); % Default type is 'Exponential'
    addOptional(p, 'Growth', true); % Default is true, meaning the changes are considered as growth
    parse(p, varargin{:});

    if(strcmp(p.Results.Type, 'Exponential'))
        PercentVector = Exponential(MileStoneVector, Years, S, p.Results.Growth);
    elseif(strcmp(p.Results.Type, 'Linear'))
        PercentVector = Linear(MileStoneVector, Years, S, p.Results.Growth);
    elseif(strcmp(p.Results.Type, 'Step'))
        PercentVector = Step(MileStoneVector, Years, S, p.Results.Growth);
    else
        PercentVector = zeros(1, Years); % Return zeros if an invalid type is provided
    end
end

% Exponential: This function calculates the exponential growth or decay over the years.
% It adjusts the growth rate between the start and end values, creating a smooth curve of change.
% If 'Growth' is true, it performs an increase; otherwise, it performs a decrease.
function [PercentVector] = Exponential(MileStoneVector, Years, S, Growth)
    PercentVector = ones(1, Years);
    if Growth == 1
        PercentVector(Years) = 1 + S;
        MileStoneVector(Years) = S;
    else
        PercentVector(Years) = 1 - S;
        MileStoneVector(Years) = -1 * S;
    end
    StartYear = 1;
    for i = 1:length(MileStoneVector)
        if(MileStoneVector(i) ~= 0)
            EndYear = i;
            GrowthVector = GrowthVectorCalc(StartYear, EndYear, MileStoneVector(i), MileStoneVector(StartYear));
            for j = 1:length(GrowthVector)
                PercentVector(StartYear + j - 1) = GrowthVector(j);
            end
            StartYear = i;
        end
    end
end

% GrowthVectorCalc: This function calculates the growth rate between the start and end years.
% It takes the start and end year values and uses the nth root to determine the growth rate over the period.
% The function then generates a growth vector using this rate to calculate the change for each year in the period.
function GrowthVector = GrowthVectorCalc(StartYear, EndYear, EndYearVal, StartYearVal)
    Period = EndYear - StartYear + 1; % The total number of years
    GrowthVector = ones(1, Period);
    GrowthVector(1) = 1 + StartYearVal;
    GrowthVector(Period) = 1 + EndYearVal;
    
    FutureValue = GrowthVector(Period);
    Rate = nthroot(FutureValue / GrowthVector(1), Period - 1);
    
    for i = 1:Period
        GrowthVector(i) = GrowthVector(1) * ((Rate)^(i - 1)); % Calculate growth for each year
    end
end

% Step: This function calculates a step change, meaning the change happens suddenly at a certain point and remains constant.
% It applies the change at the milestone and keeps it fixed for the rest of the years.
function [PercentVector] = Step(MileStoneVector, Years, S, Growth)
    PercentVector = ones(1, Years);
    if Growth == 1
        PercentVector(Years) = 1 + S;
        MileStoneVector(Years) = S;
    else
        PercentVector(Years) = 1 - S;
        MileStoneVector(Years) = -1 * S;
    end
    StartYear = 1;
    for i = 1:length(MileStoneVector)
        if(MileStoneVector(i) ~= 0)
            EndYear = i;
            GrowthVector = StepCalc(StartYear, EndYear, MileStoneVector(i));
            for j = 1:length(GrowthVector)
                PercentVector(StartYear + j - 1) = GrowthVector(j);
            end
            StartYear = i;
        end
    end
end

% StepCalc: This function generates a vector with a step change that applies the final value to all years starting from the milestone.
function GrowthVector = StepCalc(StartYear, EndYear, EndYearVal)
    Period = EndYear - StartYear + 1;
    GrowthVector = ones(1, Period) + EndYearVal; % Apply the final value to all years
end

% Linear: This function calculates a linear change between two values over a given period.
% The values increase or decrease steadily between the start and end years.
% The function computes the slope between the start and end values and applies it across the years.
function [PercentVector] = Linear(MileStoneVector, Years, S, Growth)
    PercentVector = ones(1, Years);
    if Growth == 1
        PercentVector(Years) = 1 + S;
        MileStoneVector(Years) = S;
    else
        PercentVector(Years) = 1 - S;
        MileStoneVector(Years) = -1 * S;
    end
    MileStoneVector(Years) = S;
    StartYear = 1;
    for i = 1:length(MileStoneVector)
        if(MileStoneVector(i) ~= 0)
            EndYear = i;
            GrowthVector = LinearCalc(StartYear, EndYear, MileStoneVector(i), MileStoneVector(StartYear));
            for j = 1:length(GrowthVector)
                PercentVector(StartYear + j - 1) = GrowthVector(j);
            end
            StartYear = i;
        end
    end
end

% LinearCalc: This function calculates the linear change between two points (start and end values) over a specified period.
% It calculates the rate of change and applies it uniformly to each year in the period.
function GrowthVector = LinearCalc(StartYear, EndYear, EndYearVal, StartYearVal)
    Period = EndYear - StartYear + 1;
    GrowthVector = ones(1, Period);
    GrowthVector(1) = 1 + StartYearVal;
    GrowthVector(Period) = 1 + EndYearVal;
    if (EndYearVal > StartYearVal)
        Rate = (EndYearVal - StartYearVal) / (Period - 1); % Increase rate
    else
        Rate = -1 * (StartYearVal - EndYearVal) / Period; % Decrease rate
    end
    for i = 1:Period
        GrowthVector(i) = GrowthVector(1) + Rate * (i - 1); % Apply the rate to each year
    end
end
