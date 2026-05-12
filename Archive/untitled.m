% 1. תוודאי ש-AllCities המקורי ב-Workspace
% 2. צרי עותק שלו בשם החדש
AllCities_Biger = AllCities;

% 3. שמרי רק את המשתנה החדש לקובץ החדש
save('AllCities_Biger.mat', 'AllCities_Biger');

% עכשיו כשתעשי load('AllCities_Biger.mat'), יופיע לך משתנה בשם YYYY