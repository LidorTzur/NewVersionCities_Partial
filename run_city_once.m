% run_city_once - Executes the model for a single city and saves outputs
% Inputs:
%   excelFile  - Excel file containing city data
%   orderIndex - (From choiceList) 1 for Standard, 2 for Sensitivity
% ==========================================

% 1. Configuration & Path Setup
% ==========================================
% Output directory for thesis results
outDir = fullfile('C:\Users','צור','Documents','תואר שני','תזה','קיימות ערים','פלטים מהמודל');

% Reset local sensitivity variable to ensure fresh data
if exist('SensitivityResults', 'var')
    clear SensitivityResults;
end

createPath;      % Initialize paths
preparation;     % Load city data and initialize ResultsDataBase struct
runningSteps;    % User chooses orderIndex here and model executes

% ==========================================
% 2. Data Organization (Switch by User Choice)
% ==========================================
% Link the results from the global/caller workspace
RDB = ResultsDataBase; 
fnames = {}; % Initialize list of files to be exported

switch orderIndex
    case 1 % All the steps together (Standard Scenarios)
        % Ensure data was actually generated before adding to export list
        if isfield(RDB, 'BAU_RDB') && isfield(RDB.BAU_RDB, 'TotalEmission1')
            fnames = { ...
                {'TotalResults'           , RDB.TotalResults} ;
                {'TotalEmission_BAU'      , RDB.BAU_RDB.TotalEmission1} ;
                {'TotalEmission_Moderate' , RDB.Moderate_RDB.TotalEmission2} ;
                {'TotalEmission_Advanced' , RDB.Advanced_RDB.TotalEmission3} ;
            };
        end

    case 2 % Sensitivity Analysis +- 10%
        % SensitivityResults is created in case 2 of runningSteps
        if exist('SensitivityResults', 'var') && ~isempty(SensitivityResults)
            RDB.Sensitivity_RDB = SensitivityResults;
            SR = RDB.Sensitivity_RDB;
            fnames = { ...
                {'Sensitivity_Emissions', SR.EmissionByScenario};
                {'Sensitivity_Area'     , SR.AreaByScenario};
                {'Sensitivity_Water'    , SR.WaterByScenario}
            };
        end

    otherwise
        fprintf('Warning: Unrecognized orderIndex (%d) for city: %s\n', orderIndex, cityCode);
end

% ==========================================
% 3. Writing Outputs to Excel
% ==========================================
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

if ~isempty(fnames)
    for k = 1:numel(fnames)
        baseName = fnames{k}{1};
        dataT    = fnames{k}{2};
        
        % A. Save in the local project sub-folder
        localFile = sprintf('Results_Plots\\%s_%s.xlsx', baseName, cityCode);
        writetable(dataT, localFile, 'WriteRowNames', true);
        
        % B. Save in the centralized Thesis folder
        centralFile = fullfile(outDir, sprintf('%s_%s.xlsx', baseName, cityCode));
        writetable(dataT, centralFile, 'WriteRowNames', true);
    end
    fprintf('Success: Saved %d files (Mode %d) for city: %s\n', numel(fnames), orderIndex, cityCode);
else
    fprintf('Notice: No files were exported for city: %s (Check if data exists for Mode %d)\n', cityCode, orderIndex);
end

% ==========================================
% 4. Cleanup
% ==========================================
clear centralFile localFile baseName dataT k fnames SR SensitivityResults