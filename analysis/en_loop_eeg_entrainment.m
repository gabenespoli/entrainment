%% en_loop_eeg_entrainment
%   Loop many participants through en_eeg_entrainment.
%
% Usage:
%   en_loop_eeg_entrainment(ids)
%   en_loop_eeg_entrainment(ids, 'param', value, etc.)
%
% Input:
%   ids = [numeric] List of IDs whose data will be loaded from
%       en_getpath('eeg'). If empty ([]), all ids with a 1 in the "incl"
%       column of en_getpath('diary') are used.
%
%   See `help en_eeg_entrainment` for descriptions of other params
%       'stim', 'task', and 'region'.
%
% Output:
%   Same as en_eeg_entrainment, but for each specified id.

function en_loop_eeg_entrainment(ids, varargin)

% if ids is actually a parameter (i.e., the ids var was left out entirely,
%   then add it to varargin; ids will have already been set below
if nargin > 0 && ischar(ids)
    varargin = [{ids} varargin];
    ids = [];
end

% if no ids given, use all marked as incl in diary
if nargin < 1 || isempty(ids) || ischar(ids)
    d = en_load('diary', 'incl');
    ids = d.id;
end

% defaults
stim = 'sync';
task = 'eeg';
regions = {'pmc', 'mot', 'pmm', 'aud'};

% user-defined
for i = 1:2:length(varargin)
    val = varargin{i+1};
    switch lower(varargin{i})
        case {'stim', 'stimtype'},                      if ~isempty(val), stim = val; end
        case {'task', 'tasktype', 'trig', 'trigtype'},  if ~isempty(val), task = val; end
        case {'regions', 'region'},                     if ~isempty(val), regions = val; end
    end
end

if ~iscell(regions)
    regions = cellstr(regions);
end

% loop ids
for i = 1:length(ids)
    id = ids(i);

    fprintf('\nCalculating neural entrainment for id %i...\n', id)

    % loop regions
    for j = 1:length(regions)
        region = regions{j};

        en_eeg_entrainment(id, ...
            'stim',     stim, ...
            'trig',     task, ...
            'region',   region);

    end
end

end
