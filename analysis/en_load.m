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
            d.bdffile{i} = regexp(d.bdffile{i}, '\ *,\ *', 'split');
            d.rmchans{i} = regexp(d.rmchans{i}, '\ *,\ *', 'split');
            if iscell(d.rmportcodes)
                d.rmportcodes{i} = regexp(d.rmportcodes{i}, '\ *,\ *', 'split');
                d.rmportcodes{i} = cellfun(@str2num, d.rmportcodes{i}, 'UniformOutput', false);
                d.rmportcodes{i} = cell2mat(d.rmportcodes{i});
            end
            if iscell(d.missedportcodes)
                d.missedportcodes{i} = regexp(d.missedportcodes{i}, '\ *,\ *', 'split');
                d.missedportcodes{i} = cellfun(@str2num, d.missedportcodes{i}, 'UniformOutput', false);
                d.missedportcodes{i} = cell2mat(d.missedportcodes{i});
            end
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

    case 'ica'
        varout = pop_loadset(fullfile(en_getpath('eeg'), [idStr, '_ICA.set']));

    case {'logfile','log'}
        % loads the logfile as a table
        % converts some vars to categorical
        % adds a portcodes column
        T = readtable(fname);
        T.stimType = categorical(T.stimType);
        T.trigType = categorical(T.trigType);
        % add portcodes column from filename
        T.portcode = cellfun(@(x) strrep(x, '.wav', ''), T.filename, 'UniformOutput', false);
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
