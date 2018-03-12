function varout = en_load(filetype, id)
% usage:
%   varout = en_load(filetype [, id])
%
% input:
%   filetype = [string]
%   id = [numeric] Must be a single number, not a vector

if nargin < 2, id = []; end
idStr = num2str(id);

switch lower(filetype)
    case 'eeglab' % add eeglab to path
        eeglabdir = en_getpath('eeglab');
        if ~isOnPath(eeglabdir)
            addpath(eeglabdir) % add path to eeglab root
            eeglab % start eeglab
            disp('Started eeglab.')
        end

    case 'diary' % loads the diary csv file as a table
        d = readtable(en_getpath('diary'), 'Delimiter', ',');
        d.recording_notes = []; % remove notes field for nicer display in command window

        for i = 1:size(d, 1)
            % convert some fields from comma-delimited lists to cell arrays
            d.bdffile{i}            = csv2cell(d.bdffile{i});
            d.rmchans{i}            = csv2cell(d.rmchans{i});

            % convert some fields from comma-delimited lists to numeric vectors
            d.rmportcodes{i}        = csv2vec(d.rmportcodes{i});
            d.missedportcodes{i}    = csv2vec(d.missedportcodes{i});
            d.dipolar_comps{i}      = csv2vec(d.dipolar_comps{i});
        end

        if ~isempty(id) % restrict to a specific id
            d = d(d.id == id, :); % rows in corresponding to this id
            if height(d) > 1
                error(['More than one row in the d for id ', num2str(id), '.'])
            end
        end
        varout = d;

    case 'bdf' % load .bdf as .set, relabel channels
        varout = en_readbdf(id);

    case 'eeg'
        varout = pop_loadset(fullfile(en_getpath('eeg'), [idStr, '.set']));

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

        % make some columns categorical
        T.stimType = categorical(T.stimType);
        T.trigType = categorical(T.trigType);

        % add portcodes column from filename
        T.portcode = cellfun(@(x) str2num(strrep(x, '.wav', '')), T.filename, 'UniformOutput', false);
        T.portcode = cell2mat(T.portcode);

        varout = T;
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
