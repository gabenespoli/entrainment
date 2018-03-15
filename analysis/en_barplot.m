%% en_barplot
%
% Usage:
%   en_barplot(T, 'param', value, etc.)
%   en_barplot('param', value, etc.)

function en_barplot(varargin)

% some defaults
region = 'pmc';

% remove first arg if it's a table
if istable(varargin{1})
    T = varargin{1};
    varargin{1} = [];
else
    T = [];
end

% user-defined
barplot_params = {};
for i = 1:2:length(varargin)
    param = varargin{i};
    val = varargin{i+1};
    if isempty(val), continue, end
    switch lower(param)
        case 'region',      region = val;
        otherwise
            barplot_params = [barplot_params, varargin{i:i+1}]; %#ok<AGROW>
    end
end

% if no ids given, get all marked as incl in diary
if isempty(T)
    T = en_getdata([], region);
end

% get long title for region
switch lower(region)
    case 'mot', ytitle = 'Motor Cortex Beat Entrainment (\muV)';
    case 'pmc', ytitle = 'Premotor Cortex Beat Entrainment (\muV)';
    case 'pmm', ytitle = 'Pre- and Motor Cortex Beat Entrainment (\muV)';
    case 'aud', ytitle = 'Auditory Cortex Beat Entrainment (\muV)';
    otherwise, ytitle = region;
end

fig = figure;
barplot(T, 'rhythmType', region, ...
    'xtitle',   'Rhythm Type', ...
    'spec',     {'k--', 'k--', 'k--'}, ...
    'fig',      fig, ...
    'ytitle',   ytitle, ...
    barplot_params{:});

end
