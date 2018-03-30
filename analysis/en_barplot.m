%% en_barplot
%
% Usage:
%   en_barplot(T, 'param', value, etc.)
%   en_barplot('param', value, etc.)
%
% Input:
%   T = [table] Output from en_getdata.
%
%   'var' = [string]

function en_barplot(varargin)

% some defaults
var = 'pmc';

% remove first arg if it's a table
if istable(varargin{1})
    T = varargin{1};
    varargin(1) = [];
else
    T = [];
end

% user-defined
getdata_params = {};
barplot_params = {};
for i = 1:2:length(varargin)
    param = varargin{i};
    val = varargin{i+1};
    if isempty(val), continue, end
    switch lower(param)
        case 'var'
            var = val;
        case {'sync', 'mir', 'eeg', 'tapping'}
            getdata_params = [getdata_params, varargin{i:i+1}]; %#ok<AGROW>
        otherwise
            barplot_params = [barplot_params, varargin{i:i+1}]; %#ok<AGROW>
    end
end

% if no ids given, get all marked as incl in diary
if isempty(T)
    T = en_getdata([], 'var', var, getdata_params{:});
end

% get long title for var
switch lower(var)
    case 'mot', ytitle = 'Motor Cortex Beat Entrainment (\muV)';
    case 'pmc', ytitle = 'Premotor Cortex Beat Entrainment (\muV)';
    case 'pmm', ytitle = 'Pre- and Motor Cortex Beat Entrainment (\muV)';
    case 'aud', ytitle = 'Auditory Cortex Beat Entrainment (\muV)';
    case 'move', ytitle = 'Rating of Wanting to Move (1-7)';
    otherwise, ytitle = var;
end

switch lower(var)
    case {'mot', 'pmc', 'pmm', 'aud'},  yl = [0 0.016];
    case {'move'},                      yl = [1 7];
    otherwise,                          yl = [];
end

fig = figure;
barplot(T, 'rhythm', var, ...
    'ytitle',   ytitle, ...
    'xtitle',   'Rhythm', ...
    'fig',      fig, ...
    'spec',     {'k--', 'k--', 'k--'}, ...
    'ylim',     yl, ...
    'save',     fullfile(getpath('plots'), ...
                         [datestr(clock, 'yyyy-mm-dd_HH-MM-SS'), ...
                         '_', var, '.png']), ...
    barplot_params{:});

end
