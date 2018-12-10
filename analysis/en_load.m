%% en_load
%
% Usage:
%   varout = en_load(filetype [, id])
%
% Input:
%   filetype = [string]
%
%   id = [numeric|string] Must be a single number, not a vector
%       Can also specify the stim/task like so: 6_stim_task
%       stim can be either 'sync' or 'mir'
%       task can be either 'eeg' or 'tapping'
%
% Examples:
%   D       = en_load('diary')
%   D       = en_load('diary', id)
%   M       = en_load('midi', id)
%   L       = en_load('log', id)
%   S       = en_load('stiminfo')
%   EEG     = en_load('eeg', id)
%   BDF     = en_load('bdf', id)

function varargout = en_load(filetype, id)
%% parse input
if nargin < 2, id = []; end
stim = '';
task = '';
if ischar(id) && ~strcmp(id, 'incl')
    % get stim and task from id
    C = regexp(id, '_', 'split');
    idStr = C{1};
    id = str2num(idStr);
    if length(C) > 1
        stim = C{2};
    end
    if length(C) > 2
        task = C{3};
    end
else
    idStr = num2str(id);
end

switch lower(filetype)

    %% data
    case 'midi'
        % use miditoolbox to load matrix of midi data
        en_load('miditoolbox', 1)
        MIDI = readmidi(fullfile(getpath('midi'), [idStr, '.mid']));

        % convert it to a table with headings
        MIDI = array2table(MIDI, ...
            'VariableNames', {'onsetBeats', 'durationBeats', ... % in beats
                              'channel', 'pitch', 'velocity', ...
                              'onset', 'duration'});           % in seconds

        varargout{1} = MIDI;

        % also return audio marker file if requested
        if nargout > 1
            [y, Fs] = audioread(fullfile(getpath('midi'), [idStr, '.wav']));
            if size(y, 2) > 1 % force mono
                fprintf('Loading stereo file as mono...\n')
                y = y(:, 1);
            end
            varargout{2} = y;
            varargout{3} = Fs;
        end

    case 'eeg'
        en_load('eeglab')
        if isempty(stim)
            disp('Using default: stim = ''sync''')
            stim = 'sync';
        end
        if isempty(task)
            disp('Using default: task = ''eeg''')
            task = 'eeg';
        end
        filename = fullfile(getpath('eeg'), [stim, '_', task], [idStr, '.set']);
        varargout{1} = pop_loadset(filename);

    case 'bdf'
        varargout{1} = en_readbdf(id);

    case {'tap', 'tapping'}
        if isempty(stim)
            disp('Using default stim=sync')
            stim = 'sync';
        end
        tmp = load(fullfile(getpath('tapping'), stim, [idStr, '.mat']));
        varargout{1} = tmp.TAP;

    %% logfiles
    case {'logfile','logfiles','log'}
        % loads all logfiles for the given ID as a table
        fnames = { ...
            fullfile(getpath('logfiles'), [idStr, '_sync_eeg.csv']), ...
            fullfile(getpath('logfiles'), [idStr, '_sync_tapping.csv']), ...
            fullfile(getpath('logfiles'), [idStr, '_mir_eeg.csv']), ...
            fullfile(getpath('logfiles'), [idStr, '_mir_tapping.csv']), ...
            };

        for i = 1:length(fnames)
            fname = fnames{i};
            if exist(fname, 'file')
                TMP = readtable(fname);
            else
                fprintf('! File ''%s'' doesn''t exist.\n', fname)
            end
            if i == 1
                T = TMP;
            else
                T = [T; TMP]; %#ok<AGROW>
            end
        end

        % change some variable names
        names = {'stimType', 'trigType', 'rhythmType'};
        newnames = {'stim', 'task', 'rhythm'};
        for i = 1:length(names)
            ind = cellfun(@(x) strcmp(x, names{i}), T.Properties.VariableNames);
            if any(ind)
                T.Properties.VariableNames{ind} = newnames{i};
            end
        end

        % make some columns categorical
        T.stim = categorical(T.stim);
        T.task = categorical(T.task);

        % add portcodes column from filename
        T.portcode = cellfun(@(x) str2num(strrep(x, '.wav', '')), T.filename, 'UniformOutput', false);
        T.portcode = cell2mat(T.portcode);

        % reorder columns
        T = T(:, {'id', 'stim', 'task', 'trial', 'portcode', 'move'});

        varargout{1} = T;

    case {'logfilestim', 'logstim'}
        % load logfile and stiminfo in the same table

        L = en_load('logfile', id); % setname should be id
        % L = L(L.stim==stim & L.task==task, :);
        S = en_load('stiminfo', L.portcode);
        if ~all(L.portcode == S.portcode)
            error('Portcodes in logfile and stiminfo don''t match.')
        end
        S.portcode = [];
        S.stim = [];
        L = [L, S];

        % restrict to certain block
        if ~isempty(stim)
            L = L(L.stim == stim, :);
        end
        if ~isempty(task)
            L = L(L.task == task, :);
        end

        varargout{1} = L;

    %% diary
    case 'diary' % loads the diary csv file as a table
        D = readtable(getpath('diary'), 'Delimiter', ',');
        D.recording_notes = []; % remove notes field for nicer display in command window
        D.incl(isnan(D.incl)) = 0; % make nans zeros instead

        % convert some fields from comma-delimited lists to cell arrays
        D.bdffile  = csv2cell(D.bdffile);
        D.badchans = csv2cell(D.badchans);

        % convert some fields from comma-delimited lists to numeric vectors
        D.extra_eeg_event  = csv2vec(D.extra_eeg_event);
        D.missed_eeg_event = csv2vec(D.missed_eeg_event);
        D.extra_midi_event = csv2vec(D.extra_midi_event);
        D.missed_midi_event = csv2vec(D.missed_midi_event);
        D.dipolar_comps    = csv2vec(D.dipolar_comps);

        if ~isempty(id)
            if isnumeric(id) % restrict to a specific id
                D = D(D.id == id, :); % rows in corresponding to this id
                if height(D) > 1
                    error(['More than one row in the d for id ', num2str(id), '.'])
                end
            elseif ischar(id) && strcmpi(id, 'incl')
                D = D(logical(D.incl), :);
            end
        end
        varargout{1} = D;

    %% stimulus info
    case {'stiminfo'}
        S = readtable(getpath('stiminfo'));

        % make some vars categorical
        S.stim = categorical(S.stim);
        if ~isempty(id)
            % restrict by portcodes
            ind = cell2mat(arrayfun(@(x) ...
                find(ismember(S.portcode, x)), ...
                id, 'UniformOutput', false));
            S = S(ind, :);
            S.excerpt = categorical(S.excerpt);
            S.syncopation_degree = categorical(S.syncopation_degree);
        end
        varargout{1} = S;

    %% toolboxes
    case 'eeglab' % add eeglab to path and start eeglab
        eeglabdir = getpath('eeglab');
        if ~isOnPath(eeglabdir)
            if exist(eeglabdir, 'dir')
                addpath(eeglabdir) % add path to eeglab root
                disp('Added EEGLAB to the MATLAB path.')
                % start eeglab normally because it will add other paths
                eeglab
            else
                fprintf('The folder ''%s'' doesn''t exist. You can\n', ...
                        'a) Download eeglab and put it''s folder there, or\n', ...
                        'b) Change the folder that is specified in\n', ...
                        '''getpath.m.''')
                error('getpath(''eeglab'') doesn''t exist')
            end
        elseif isempty(id) % be verbose if id arg is given
            disp('EEGLAB is already on the MATLAB path.')
            disp('Type `eeglab` or `eeglab redraw` in the command window to force restart it.')
        end

    case 'miditoolbox'
        miditoolboxdir = getpath('miditoolbox');
        if ~isOnPath(miditoolboxdir)
            addpath(miditoolboxdir)
            disp('Added MIDI Toolbox to the MATLAB path.')
        elseif isempty(id) % be verbose if id arg is given
            disp('MIDI Toolbox is already on the MATLAB path.')
        end

end
end

function onPath = isOnPath(Folder)
% https://www.mathworks.com/matlabcentral/answers/86740-how-can-i-determine-if-a-directory-is-on-the-matlab-path-programmatically
pathCell = regexp(path, pathsep, 'split');
if ispc  % Windows is not case-sensitive
  onPath = any(strcmpi(Folder, pathCell));
else
  onPath = any(strcmp(Folder, pathCell));
end
end

function C = csv2cell(C)
% loops through a cell array and splits items by comma and surrounding
%   whitespace
% e.g.
% if C = {'a', ...
%         'a, b', ...
%         'a  ,  b  '}
% then csv2cell(C) = {'a', ...
%                     {'a', 'b'}, ...
%                     {'a', 'b'}}
for i = 1:length(C)
    C{i} = regexp(C{i}, '\ *,\ *', 'split');
end
end

function C = csv2vec(C)
% takes a numeric vector or a cell array of strings that are
%   comma-separated numbers, and returns a cell array of numeric vectors
if isnumeric(C)
    tmp = cell(size(C));
    for i = 1:length(C)
        tmp{i} = C(i);
    end
    C = tmp;
else
    for i = 1:length(C)
        C{i} = regexp(C{i}, '\ *,\ *', 'split');
        C{i} = cellfun(@str2num, C{i}, 'UniformOutput', false);
        C{i} = cell2mat(C{i});
    end
end
end
