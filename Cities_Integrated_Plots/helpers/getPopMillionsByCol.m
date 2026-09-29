function popM = getPopMillionsByCol(C, colIdx, scen, yearLabels)
% מחזיר את אוכלוסיית העיר (במיליונים) לשנה המבוקשת

    RDB = getScenarioRDB(C, scen);
    P   = RDB.population;

    yearsRow = P{2,:};
    popsRow  = P{3,:};

    if iscell(yearsRow)
        yearsRow = cellfun(@str2double, yearsRow);
    end
    if iscell(popsRow)
        popsRow = cellfun(@str2double, popsRow);
    end

    if colIdx <= numel(popsRow) && ~isnan(popsRow(colIdx))
        popM = popsRow(colIdx);
        return;
    end

    yr = str2double(yearLabels{colIdx});
    ix = find(yearsRow == yr, 1);

    if ~isempty(ix)
        popM = popsRow(ix);
    else
        error('Population for year %s not found.', yearLabels{colIdx});
    end
end

% function RDB = getScenarioRDB(C, scen)
%     switch scen
%         case 'BAU'
%             RDB = C.BAU_RDB;
%         case 'Moderate'
%             RDB = C.Moderate_RDB;
%         case 'Advanced'
%             RDB = C.Advanced_RDB;
%         otherwise
%             error('Unknown scenario');
%     end
% end
