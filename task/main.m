function main(test)

if nargin < 1, test = false; end

% this is used to tag logfiles and datafiles for matching later
currentTime = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
address = hex2dec('d050'); % for eeg port codes using io64.mexw64

% define files and folders
logFolder = 'logfiles';
stimFolder = '../stimuli/main';
makeSureFoldersExist(logFolder, stimFolder)
logfileHeaders = {'id', 'stimType', 'trigType', 'trial', 'filename', ...
                  'move', 'filepath', 'timestamp'};

% try block around everything so we can exit gracefully (i.e., close all files)
try

    % prepare
    ioObj = io64(); % initalize eeg port codes
    ioObj_status = io64(ioObj);
    if ioObj_status ~= 0
        error('io64 installation failed. Please try restarting the task.')
    end
    io64(ioObj, address, 0); % send a 0 portcode to make sure it's zeroed
    [id, stimType, trigType] = promptForTaskInfo(test); % id is a string
    [trialList, startTrial, logfileFid] = getTrialList(id, logFolder, ...
        logfileHeaders, stimFolder, stimType, trigType, currentTime);

    % loop trials
    nTrials = length(trialList);
    for trial = startTrial:length(trialList)
        stimfile = trialList{trial};
        clc
        fprintf('Trial %i / %i\n', trial, nTrials)
        try showProgress(trial, nTrials), catch, end
        move = playTrial(stimfile, stimType, ioObj, address);
        logResponse(logfileFid, id, stimType, trigType, trial, stimfile, move);
    end

catch err
    fprintf('\n*** WARNING ***\n')
    fprintf('There was problem running the task (error below).\n')
    fprintf('Attempting to close files first... ')
    fclose('all');
    fprintf('Done.\n')
    rethrow(err)

end

fclose('all');
end

function makeSureFoldersExist(varargin)
% loops through input args, checks if its a dir, creates it if it isn't
% and notifies the user
for i = 1:length(varargin)
    folder = varargin{i};
    if ~exist(folder, 'dir')
        fprintf('Creating folder ''%s''... ', folder)
        mkdir(folder)
        fprintf('Done.\n')
    end
end
end

function logResponse(logfileFid, id, stimType, trigType, trial, fname, move)
[pathstr, name, ext] = fileparts(fname);
name = [name, ext];
timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
data = {id, stimType, trigType, trial, name, ...
        move, pathstr, timestamp};
formatSpec = '%s,%s,%s,%i,%s,%i,%s,%s\n';
fprintf(logfileFid, formatSpec, data{:});
end
