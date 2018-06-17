function df = en_writetable_tapping(ids, varargin)

ids_with_no_tapping = 42;

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
do_save = true;

for i = 1:2:length(varargin)
    param = varargin{i};
    val = varargin{i+1};
    if isempty(val), continue, end
    switch lower(param)
        case 'stim',                stim = val;
        case {'do_save', 'save'},   do_save = val;
    end
end

% loop ids and collect data
for i = 1:length(ids)
    id = ids(i);
    if ismember(id, ids_with_no_tapping)
        fprintf('  Skipping id %i\n', id)
        continue
    end
    idStr = num2str(id);
    fprintf('  Collecting id %i\n', id)

    fname = fullfile(getpath('taptrainment'), stim, [idStr, '.csv']);
    tmp = readtable(fname);

    % add current id to master table
    if i == 1
        df = tmp;
    else
        df = [df; tmp]; %#ok<AGROW>
    end
end

% make some fields categorical
if strcmp(stim, 'sync')
    cats = {'stim', 'task', 'syncopation_degree', 'excerpt'};
    for i = 1:length(cats)
        df.(cats{i}) = categorical(df.(cats{i}));
    end
    df.syncopation_degree = reordercats(df.syncopation_degree, {'low', 'moderate', 'high'});

elseif strcmp(stim, 'mir')
    df.syncopation_degree = [];
    df.syncopation_index = [];
    df.excerpt = [];
    cats = {'stim', 'task'};
    for i = 1:length(cats)
        df.(cats{i}) = categorical(df.(cats{i}));
    end
end

% save a csv
if do_save
    fname = ['~/projects/en/tables/ent_', stim, '_', ...
        datestr(now, 'yyyy-mm-dd_HH-MM-SS'), '.csv'];
    writetable(df, fname)
    fprintf('Save file to %s\n', fname)
end

end
