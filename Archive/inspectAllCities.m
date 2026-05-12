function inspectAllCities(data, indent)
    % פונקציה לסריקה היררכית של מבנה AllCities
    % שימוש: inspectAllCities(AllCities)
    
    if nargin < 2
        indent = ''; % הגדרת הזחה ראשונית
    end

    % אם מדובר במבנה (Struct) - נרוץ על השדות שלו
    if isstruct(data)
        fields = fieldnames(data);
        for i = 1:numel(fields)
            fprintf('%s|-- Field: **%s**\n', indent, fields{i});
            inspectAllCities(data.(fields{i}), [indent, '    ']);
        end
        
    % אם מדובר בטבלה (Table) - נציג את המדדים (שורות) והשנים (עמודות)
    elseif istable(data)
        rowNames = data.Properties.RowNames;
        colNames = data.Properties.VariableNames;
        
        if isempty(rowNames)
            % אם אין שמות לשורות, נציג רק את הגודל
            fprintf('%s    [Table %dx%d] (No row names defined)\n', indent, size(data,1), size(data,2));
        else
            % הדפסת המדדים (שורות) הקיימים בטבלה
            fprintf('%s    [Table %dx%d] Metrics: ', indent, size(data,1), size(data,2));
            metricsStr = strjoin(rowNames, ', ');
            % הגבלה של אורך ההדפסה כדי שלא יציף את המסך
            if length(metricsStr) > 100
                fprintf('%s...\n', metricsStr(1:100));
            else
                fprintf('%s\n', metricsStr);
            end
        end
        
        % הצגת טווח השנים (עמודות)
        if ~isempty(colNames)
            fprintf('%s    Years Range: %s to %s\n', indent, colNames{1}, colNames{end});
        end

    % אם מדובר ב-Cell array (כמו WaterFromFood1)
    elseif iscell(data)
        fprintf('%s    [Cell Array %dx%d]\n', indent, size(data,1), size(data,2));
        
    % אם מדובר בערך מספרי פשוט
    elseif isnumeric(data)
        fprintf('%s    [Numeric %dx%d]\n', indent, size(data,1), size(data,2));
    end
end