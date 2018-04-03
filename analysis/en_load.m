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

function varargout = en_load(filetype, id)
%% parse input
if nargin < 2, id = []; end
if ischar(id)
    % get stim and task from id
    C = regexp(id, '_', 'split');
    idStr = C{1};
    id = str2num(idStr);
    if length(C) == 3
        stim = C{2};
        task = C{3};
    else
        stim = '';
        task = '';
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
            varargout{2} = y;
            varargout{3} = Fs;
        end

    case 'eeg'
        if isempty(stim)
            disp('Using default stim=sync')
            stim = 'sync';
        end
        if isempty(task)
            disp('Using default task=eeg')
            stim = 'mir';
        end
        varargout{1} = pop_loadset(fullfile(getpath('eeg'), ...
            [stim, '_', task], ...
            [idStr, '.set']));

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
            TMP = readtable(fname);
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
        T = T(:, {'id', 'stim', 'task', 'trial', 'timestamp', ...
                  'filepath', 'filename', 'portcode'});

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
        varargout{1} = L;

    %% diary
    case 'diary' % loads the diary csv file as a table
        D = readtable(getpath('diary'), 'Delimiter', ',');
        D.recording_notes = []; % remove notes field for nicer display in command window
        D.incl(isnan(D.incl)) = 0; % make nans zeros instead

        for i = 1:size(D, 1)
            % convert some fields from comma-delimited lists to cell arrays
            D.bdffile{i}            = csv2cell(D.bdffile{i});
            D.rmchans{i}            = csv2cell(D.rmchans{i});

            % convert some fields from comma-delimited lists to numeric vectors
            D.rmportcodes{i}        = csv2vec(D.rmportcodes{i});
            D.rmevent_midi{i}       = csv2vec(D.rmevent_midi{i});
            D.missedportcodes{i}    = csv2vec(D.missedportcodes{i});
            D.dipolar_comps{i}      = csv2vec(D.dipolar_comps{i});
        end

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
            S.rhythm = categorical(S.rhythm);
        end
        varargout{1} = S;

    %% toolboxes
    case 'eeglab' % add eeglab to path and start eeglab
        eeglabdir = getpath('eeglab');
        if ~isOnPath(eeglabdir)
            addpath(eeglabdir) % add path to eeglab root
            disp('Added EEGLAB to the MATLAB path.')
            % start eeglab normally because it will add other paths
            eeglab
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

function C = csv2cell(csv)
C = regexp(csv, '\ *,\ *', 'split');
end

function vec = csv2vec(csv)
C = csv2cell(csv);
C = cellfun(@str2num, C, 'UniformOutput', false);
vec = cell2mat(C);
end
