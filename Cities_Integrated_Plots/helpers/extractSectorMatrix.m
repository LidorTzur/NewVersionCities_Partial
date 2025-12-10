function y = extractSectorMatrix(tbl, sectorOrder, baseCol, selCol)
    have = ismember(sectorOrder, string(tbl.Properties.RowNames));

    if ~all(have)
        missing = sectorOrder(~have);
        Z = array2table(zeros(numel(missing), width(tbl)), ...
            'RowNames', cellstr(missing), ...
            'VariableNames', tbl.Properties.VariableNames);
        tbl = [tbl; Z];
    end

    tbl = tbl(cellstr(sectorOrder), :);
    y = [tbl{:, baseCol}, tbl{:, selCol}];
end
