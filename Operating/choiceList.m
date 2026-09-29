function idx = choiceList(titleStr, promptStr, options)
%CHOICELIST Show a single-selection list dialog and return the chosen index.
%   idx = choiceList(titleStr, promptStr, options)
%
%   titleStr  - dialog window title
%   promptStr - instruction text shown above the list
%   options   - cell array of option labels
%
%   Returns the 1-based index of the selected option, or [] if the user
%   cancelled or closed the dialog.
%
%   Example (as used in Operating/runningSteps.m):
%       orderIndex = choiceList('Select a scenario', ...
%           'Choose one of the scenarios and follow the instructions.', ...
%           {'All the steps together', 'Sensitivity Analysis +- 10%'});

[idx, ok] = listdlg( ...
    'Name',          titleStr, ...
    'PromptString',  promptStr, ...
    'ListString',    options, ...
    'SelectionMode', 'single', ...
    'ListSize',      [320 120]);

if ~ok
    idx = [];
end
end
