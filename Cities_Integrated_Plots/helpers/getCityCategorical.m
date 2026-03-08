% function cats = getCityCategorical(AllCities)
%     % Extracts field names and sorts them alphabetically
%     rawNames = fieldnames(AllCities);
%     sortedNames = sort(rawNames);
% 
%     % Returns a categorical object with fixed ordinal order
%     cats = categorical(sortedNames, sortedNames, 'Ordinal', true);
% end

function cats = getCityCategorical(AllCities, manualOrder)
    % 1. Extract the actual field names from the data structure
    existingCities = fieldnames(AllCities);

    % 2. Define the default logical order if no list was provided
    if nargin < 2 || isempty(manualOrder)
        manualOrder = { ...
            'Tlv', 'RishonLeZion', 'BeerSheva', ...    % Metropolises
            'Raanana', 'Modiin', ...                   % Established/Suburbs
            'Hadera', 'Afula', 'KiryatGat', ...        % Growth/Periphery
            'BeitShemesh', 'MazkeretBatya' ...         % Sectoral/Small
        };
    end

    % 3. Check for mismatches between the list and the actual data
    missingInManual = setdiff(existingCities, manualOrder); % In data, but not in list
    extraInManual   = setdiff(manualOrder, existingCities); % In list, but not in data

    % 4. Logic: If the manual list is incomplete or has typos, use Alphabetical
    if ~isempty(missingInManual) || ~isempty(extraInManual)
        finalOrder = sort(existingCities);
        
        % Print a helpful notice for debugging
        fprintf('\n--- [Notice] Reverting to Alphabetical Order ---\n');
        if ~isempty(missingInManual)
            fprintf('Missing from list: %s\n', strjoin(missingInManual, ', '));
        end
        if ~isempty(extraInManual)
            fprintf('Extra in list (Check spelling): %s\n', strjoin(extraInManual, ', '));
        end
        fprintf('----------------------------------------------\n\n');
    else
        % Everything matches, use the custom order
        finalOrder = manualOrder;
    end

    % 5. Create the categorical object with the chosen order
    cats = categorical(finalOrder, finalOrder, 'Ordinal', true);
end