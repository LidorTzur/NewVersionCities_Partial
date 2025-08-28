function [SewegeTreatmentEmmissionsTable] = CalcSewegeEmissions(Data,WaterConsumption)

% עשיתי מה שנראה לי לנכון למודל של דור שזה פשוט לבטל את המודל הישן ולהשאיר
% את החישוב של החדש וזהו

%% Sewege

SewegeEmissionsCoefficients = Data.Water_DataBase.SewegeTreatmentEmissionsCoefficitns; % Kg/Ton

% % זה מהמודל הישן בסקריפט של קריאת הנתונים. שם לא הכנסתי אותם לדאטאבייס
% UrbanConsumptionPercentages = Data.Water_DataBase.UrbanConsumptionPercentages;
% RatioForBrackishWater = Data.Water_DataBase.RatioForBrackishWater;
% UrbanConsumption_FreshWater = WaterConsumption{1,1}; % Industrial and urban
% %%UrbanConsumption_FreshWater = WaterConsumption{4,1}+WaterConsumption{4,2}+WaterConsumption{4,3}; %% inculding diselinated water and brackish water
% 
% 
% % 0.16 זה התפלגות צריכה של מים שפירים לבנייה
% % 0.11 זה התפלגות צריכה של מים שפירים לגינון
% % לפי דעתי יש פה כפל של 0.16 וגם התא של - UrbanConsumptionPercentages
% % אני חושבת שהם אומרים את אותו הדבר
% WaterForConstruction = (WaterConsumption{1,1}*0.16)*UrbanConsumptionPercentages(6);
% %WaterForConstruction = (WaterConsumption{4,1}+WaterConsumption{4,2})*UrbanConsumptionPercentages(6);
% UrbanConsumption_NoConstruction = UrbanConsumption_FreshWater-WaterForConstruction; %% and no treated waste water
% Gardening = (WaterConsumption{1,1}*0.11)*UrbanConsumptionPercentages(4) ;
% %Gardening = (WaterConsumption{4,1}+WaterConsumption{4,2})*UrbanConsumptionPercentages(4) + WaterConsumption{4,3}*RatioForBrackishWater(1);
% Residential = (WaterConsumption{1,1})*UrbanConsumptionPercentages(1);
% %Residential = (WaterConsumption{4,1}+WaterConsumption{4,2})*UrbanConsumptionPercentages(1);
% %TotalSewege = UrbanConsumption_NoConstruction-Gardening-0.15*Residential;

%% Matches to the new water model
TotalSewege = WaterConsumption{1,6};
SewegeTreatmentEmmissionsTable = array2table(zeros(1,2));
SewegeTreatmentEmmissionsTable.Properties.VariableNames = {'Air Pollutants', 'GHG'};
SewegeTreatmentEmmissionsTable{1,1} = SewegeEmissionsCoefficients{1,1}*TotalSewege/1000; %% tons
SewegeTreatmentEmmissionsTable{1,2} = SewegeEmissionsCoefficients{1,2}*TotalSewege/1000; %% tons

end