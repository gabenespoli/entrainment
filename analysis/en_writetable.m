%% en_writetable.m
% concatenate csv files from many ids as a single table

function T = en_writetable(ids, varargin)
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
regions = {'mot', 'pmc', 'pmm', 'aud'};

for i = 1:2:length(varargin)
    param = varargin{i};
    val = varargin{i+1};
    if isempty(val), continue, end
    switch lower(param)
        case {'region', 'regions'}, regions = val;
        case 'stim',                stim = val;
        case {'task','trig'},       task = val;
    end
end
if ~iscell(regions), regions = cellstr(regions); end

for i = 1:length(ids)
    id = ids(i);
    idStr = num2str(id);

    for j = 1:length(regions)
        region = regions{j};
        fname = fullfile(getpath('entrainment'), ...
            [stim, '_', task], [idStr, '_', region, '.csv']);
        tmp = readtable(fname);
        if j == 1
            tmp_id = tmp;
        else
            if all(tmp.portcode == tmp_id.portcode)
                tmp_id = join(tmp_id, tmp);
            else
                error(['Portcodes don''t match for id ', num2str(id), '.'])
            end
        end
    end

    if i == 1
        T = tmp_id;
    else
        T = [T; tmp_id]; %#ok<AGROW>
    end

end

% make some fields categorical
cats = {'stim', 'task', 'rhythm', 'excerpt'};
for i = 1:length(cats)
    T.(cats{i}) = categorical(T.(cats{i}));
end
T.rhythm = reordercats(T.rhythm, {'simple', 'optimal', 'complex'});

% save a csv
writetable(T, ['~/projects/en/stats/en_', datestr(now, 'yyyy-mm-dd_HH-MM-SS'), '.csv'])

end
