function cats = getCityCategorical(AllCities)
    % Extracts field names and sorts them alphabetically
    rawNames = fieldnames(AllCities);
    sortedNames = sort(rawNames);
    
    % Returns a categorical object with fixed ordinal order
    cats = categorical(sortedNames, sortedNames, 'Ordinal', true);
end