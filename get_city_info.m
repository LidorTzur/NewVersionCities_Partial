function [OutDir] = get_city_info(cityCode)
% get_city_info - מחזיר שם עיר ותיקיית פלט לפי קוד

    switch cityCode
        case "RishonLeZion"
            OutDir   = fullfile('C:\Users','צור','Documents','תואר שני','תזה','קיימות ערים','ראשלצ','פלטים');

        case "BeerSheva"
            OutDir   = fullfile('C:\Users','צור','Documents','תואר שני','תזה','קיימות ערים','באר שבע','השוואה למודל הארצי');

        case "BeitShemesh"
            OutDir   = fullfile('C:\Users','צור','Documents','תואר שני','תזה','קיימות ערים','בית שמש','פלטים');

        otherwise
            error('Unknown city code: %s', cityCode);
    end
end
