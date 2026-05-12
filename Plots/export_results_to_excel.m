% 
% switch DataBase.City_Case
%     case "R"
%         ResultsDataBase_Rashlaz = RDB;
%     case "BS"
%         ResultsDataBase_BeerSheva = RDB;
% end
% writetable(ResultsDataBase.TotalResults, 'TotalResults_BeerSheva.xlsx', 'WriteRowNames', true)
% writetable(ResultsDataBase.BAU_RDB.TotalEmission1, 'TotalEmission_BAU_BeerSheva.xlsx', 'WriteRowNames', true)
% writetable(ResultsDataBase.Moderate_RDB.TotalEmission2, 'TotalEmission_Moderate_BeerSheva.xlsx', 'WriteRowNames', true)
% writetable(ResultsDataBase.Advanced_RDB.TotalEmission3, 'TotalEmission_Advanced_BeerSheva.xlsx', 'WriteRowNames', true)
% 
% 
% writetable(ResultsDataBase.BAU_RDB.TotalEmission1, 'C:\Users\צור\Documents\תואר שני\תזה\קיימות ערים\באר שבע\השוואה למודל הארצי\TotalEmission_BAU_BeerSheva.xlsx', ...
%      'WriteRowNames', true)
% writetable(ResultsDataBase.Moderate_RDB.TotalEmission2, 'C:\Users\צור\Documents\תואר שני\תזה\קיימות ערים\באר שבע\השוואה למודל הארצי\TotalEmission_Moderate_BeerSheva.xlsx', ...
%      'WriteRowNames', true)
% writetable(ResultsDataBase.Advanced_RDB.TotalEmission3  , 'C:\Users\צור\Documents\תואר שני\תזה\קיימות ערים\באר שבע\השוואה למודל הארצי\TotalEmission_Advanced_BeerSheva.xlsx', ...
%      'WriteRowNames', true)
% writetable(ResultsDataBase.TotalResults  , 'C:\Users\צור\Documents\תואר שני\תזה\קיימות ערים\באר שבע\השוואה למודל הארצי\TotalResults_BeerSheva.xlsx', ...
%      'WriteRowNames', true)
% 
% 
% 
% 
% writetable(ResultsDataBase.TotalResults, 'TotalResults_Rashlaz.xlsx', 'WriteRowNames', true)
% writetable(ResultsDataBase.BAU_RDB.TotalEmission1, 'TotalEmission_BAU_Rashlaz.xlsx', 'WriteRowNames', true)
% writetable(ResultsDataBase.Moderate_RDB.TotalEmission2, 'TotalEmission_Moderate_Rashlaz.xlsx', 'WriteRowNames', true)
% writetable(ResultsDataBase.Advanced_RDB.TotalEmission3, 'TotalEmission_Advanced_Rashlaz.xlsx', 'WriteRowNames', true)
% 
% 
% writetable(ResultsDataBase.BAU_RDB.TotalEmission1, 'C:\Users\צור\Documents\תואר שני\תזה\קיימות ערים\ראשלצ\פלטים\TotalEmission_BAU_Rashlaz.xlsx', ...
%      'WriteRowNames', true)
% writetable(ResultsDataBase.Moderate_RDB.TotalEmission2, 'C:\Users\צור\Documents\תואר שני\תזה\קיימות ערים\ראשלצ\פלטים\TotalEmission_Moderate_Rashlaz.xlsx', ...
%      'WriteRowNames', true)
% writetable(ResultsDataBase.Advanced_RDB.TotalEmission3  , 'C:\Users\צור\Documents\תואר שני\תזה\קיימות ערים\ראשלצ\פלטים\TotalEmission_Advanced_Rashlaz.xlsx', ...
%      'WriteRowNames', true)
% writetable(ResultsDataBase.TotalResults  , 'C:\Users\צור\Documents\תואר שני\תזה\קיימות ערים\ראשלצ\פלטים\TotalResults_Rashlaz.xlsx', ...
%      'WriteRowNames', true)








% 
% switch DataBase.City_Case
%     case "R"
%         City_Tag   = "Rashlaz";
%         OutDir     = fullfile('C:\Users','צור','Documents','תואר שני','תזה','קיימות ערים','ראשלצ','פלטים');
%         RDB = ResultsDataBase_Rashlaz;
% 
%     case "BS"
%         City_Tag   = "BeerSheva";
%         OutDir     = fullfile('C:\Users','צור','Documents','תואר שני','תזה','קיימות ערים','באר שבע','השוואה למודל הארצי');
%         RDB = ResultsDataBase_BeerSheva;
% 
%     case "BeitS"
%         City_Tag   = "BeitShemesh";
%         OutDir = fullfile('C:\Users','צור','Documents','תואר שני','תזה','קיימות ערים','בית שמש','פלטים');
%         RDB = ResultsDataBase_BeitShemesh;
% 
% end
% 
% if ~exist(OutDir,'dir')
%     mkdir(OutDir);
% end
% 
% % שמות קבצים לפי תבנית
% fnames = { ...
%     {'TotalResults'               , RDB.TotalResults} ;
%     {'TotalEmission_BAU'          , RDB.BAU_RDB.TotalEmission1} ;
%     {'TotalEmission_Moderate'     , RDB.Moderate_RDB.TotalEmission2} ;
%     {'TotalEmission_Advanced'     , RDB.Advanced_RDB.TotalEmission3} ;
% };
% 
% % לולאה לכתיבה גם בתיקייה הנוכחית וגם בתיקייה הייעודית
% for k = 1:numel(fnames)
%     baseName = fnames{k}{1};
%     T        = fnames{k}{2};
% 
%     % קובץ בתיקייה הנוכחית
%     file1 = sprintf('%s_%s.xlsx', baseName, City_Tag);
%     writetable(T, file1, 'WriteRowNames', true);
% 
%     % קובץ בתיקייה הייעודית
%     file2 = fullfile(OutDir, sprintf('%s_%s.xlsx', baseName, City_Tag));
%     writetable(T, file2, 'WriteRowNames', true);
% end
% 
% switch DataBase.City_Case
%     case "R"
%         ResultsDataBase_Rashlaz = RDB;
%     case "BS"
%         ResultsDataBase_BeerSheva = RDB;
%     case "BeitS"
%         ResultsDataBase_BeitShemesh = RDB;
% end
