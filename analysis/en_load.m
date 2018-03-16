%% en_load
%
% Usage:
%   varout = en_load(filetype [, id])
%
% Input:
%   filetype = [string]
%
%   id = [numeric|string] Must be a single number, not a vector
%
%
% Examples:
%   d       = en_load('diary')
%   d       = en_load('diary', id)
%   M       = en_load('midi', id)
%   L       = en_load('log', id)
%   S       = en_load('stiminfo')
%   EEG     = en_load('eeg', id)

function varout = en_load(filetype, id)

if nargin < 2, id = []; end
if ischar(id)
    idStr = id;
    if isempty(id), id = idStr; end
else
    idStr = num2str(id);
end

switch lower(filetype)

    %% data
    case 'midi'
        % find marker times in seconds
        disp('Loading marker wav file...')
        [y, Fs] = audioread(fullfile(en_getpath('midi'), [idStr, '.wav']));
        times = findAudioMarkers( ...
            transpose(y), ...   % waveform
            0.001, ...          % threshold
            2 * Fs, ...         % timeBetween
            'plotMarkers',      false, ...
            'numMarkers',       60);    % TODO this should be based on rm and missed portcodes
        times = times / Fs; % convert from samples to seconds
        if ~iscolumn(times), times = transpose(times); end % make column vector
        if length(times) ~= 60, error('There aren''t 60 trials.'), end


        % use miditoolbox to load matrix of midi data
        en_load('miditoolbox', 1)
        M = readmidi(fullfile(en_getpath('midi'), [idStr, '.mid']));

        % convert it to a table with headings
        M = array2table(M, ...
            'VariableNames', {'onsetBeats', 'durationBeats', ... % in beats
                              'channel', 'pitch', 'velocity', ...
                              'onset', 'duration'});           % in seconds

        % make one row per trial instead of one row per tap
        % add columns for stim and trial number
        for i = 1:length(times)
            % get inds of M that match the current time
            if i < length(times)
                ind = M.onset >= times(i) & M.onset < times(i+1);
            else
                ind = M.onset >= times(i);
            end

            % start this row of the table and add stim and trial columns
            TMP = table(i, 'VariableNames', {'trial'});
            if ismember(i, 1:30)
                TMP.stim = {'sync'};
            elseif ismember(i, 31:60)
                TMP.stim = {'mir'};
                TMP.trial(1) = TMP.trial(1) - 30;
            else
                error('Too many trials.')
            end

            % add the rest of M by trials (mutiple taps into one table row)
            names = M.Properties.VariableNames;
            for j = 1:length(names)
                TMP.(names{j}) = {M.(names{j})(ind)};
            end

            if i == 1
                OUT = TMP;
            else
                OUT = [OUT; TMP]; %#ok<AGROW>
            end
        end
        M = OUT;
        M.stim = categorical(M.stim);

        % reorder and restrict to a few needed columns only
        M = M(:, {'stim', 'trial', 'onset', 'duration', 'velocity'});
        

        varout = M;

    case 'eeg'
        varout = pop_loadset(fullfile(en_getpath('eeg'), [idStr, '.set']));

    %% logfiles
    case {'logfile','logfiles','log'}
        % loads all logfiles for the given ID as a table
        fnames = { ...
            fullfile(en_getpath('logfiles'), [idStr, '_sync_eeg.csv']), ...
            fullfile(en_getpath('logfiles'), [idStr, '_sync_tapping.csv']), ...
            fullfile(en_getpath('logfiles'), [idStr, '_mir_eeg.csv']), ...
            fullfile(en_getpath('logfiles'), [idStr, '_mir_tapping.csv']), ...
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

        varout = T;

    %% diary
    case 'diary' % loads the diary csv file as a table
        d = readtable(en_getpath('diary'), 'Delimiter', ',');
        d.recording_notes = []; % remove notes field for nicer display in command window
        d.incl(isnan(d.incl)) = 0; % make nans zeros instead

        for i = 1:size(d, 1)
            % convert some fields from comma-delimited lists to cell arrays
            d.bdffile{i}            = csv2cell(d.bdffile{i});
            d.rmchans{i}            = csv2cell(d.rmchans{i});

            % convert some fields from comma-delimited lists to numeric vectors
            d.rmportcodes{i}        = csv2vec(d.rmportcodes{i});
            d.missedportcodes{i}    = csv2vec(d.missedportcodes{i});
            d.dipolar_comps{i}      = csv2vec(d.dipolar_comps{i});
        end

        if ~isempty(id)
            if isnumeric(id) % restrict to a specific id
                d = d(d.id == id, :); % rows in corresponding to this id
                if height(d) > 1
                    error(['More than one row in the d for id ', num2str(id), '.'])
                end
            elseif ischar(id) && strcmpi(id, 'incl')
                d = d(logical(d.incl), :);
            end
        end
        varout = d;

    %% stimulus info
    case {'stiminfo'}
        S = readtable(en_getpath('stiminfo'));

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
        varout = S;

    %% toolboxes
    case 'eeglab' % add eeglab to path and start eeglab
        eeglabdir = en_getpath('eeglab');
        if ~isOnPath(eeglabdir)
            addpath(eeglabdir) % add path to eeglab root
            disp('Added EEGLAB to the MATLAB path.')
            % start eeglab normally because it will add other paths
            eeglab
        elseif isempty(id) % be verbose if id arg is given
            disp('EEGLAB is already on the MATLAB path.')
            disp('Try typing `eeglab` or `eeglab redraw` in the command window.')
        end

    case 'miditoolbox'
        miditoolboxdir = en_getpath('miditoolbox');
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
