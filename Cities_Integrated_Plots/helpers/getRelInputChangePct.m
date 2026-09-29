function relPct = getRelInputChangePct(SR, scenName)
    % מחזיר את אחוז השינוי היחסי האמיתי שהוזן לפרמטר scenName,
    % בהתבסס על ה-Dev וה-OrigVal השמורים בפועל בזמן ה-sensitivity run.
    if isfield(SR, 'OrigParamValue') && isKey(SR.OrigParamValue, scenName) ...
            && SR.OrigParamValue(scenName) ~= 0
        origVal = SR.OrigParamValue(scenName);
        relPct = (SR.DeviationUsed / origVal) * 100;
    else
        % נפילה לאחור לערים/תרחישים ישנים שעדיין לא רצו עם השמירה החדשה
        relPct = SR.DeviationUsed * 100; % = 10, ההתנהגות הישנה
    end
end