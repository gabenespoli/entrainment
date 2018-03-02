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
        eeglabdir = en_getFolder('eeglab');
        if ~isOnPath(eeglabdir)
            addpath(eeglabdir) % add path to eeglab root
            eeglab % start eeglab
            disp('Started eeglab.')
        end

    case 'bdflog' % loads the bdf log of recordings
        fname = fullfile(en_getFolder('analysis'), 'en_log.csv');
        bdflog = readtable(fname, 'Delimiter', ',');
        if ~isempty(id) % restrict to a specific id
            bdflog = bdflog(bdflog.id == id, :); % rows in corresponding to this id
            if height(bdflog) > 1
                error(['More than one row in the bdflog for id ', num2str(id), '.'])
            end
        end
        varout = bdflog;

    case 'bdf' % load .bdf as .set, relabel channels
        varout = en_readbdf(id);

    case 'eeg'
        varout = pop_loadset(fullfile(en_getFolder('eeg'), [idStr, '.set']));

    case 'ica'
        varout = pop_loadset(fullfile(en_getFolder('eeg'), [idStr, '_ICA.set']));

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
