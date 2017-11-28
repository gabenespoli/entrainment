function main(test)

if nargin < 1, test = false; end

% this is used to tag logfiles and datafiles for matching later
currentTime = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
address = hex2dec('d050'); % for eeg port codes using io64.mexw64

% define files and folders
logFolder = 'logfiles';
stimFolder = '../stimuli';
makeSureFoldersExist(logFolder, stimFolder)
logfileHeaders = {'id', 'stimType', 'trigType', 'trial', 'filename', 'move', 'pleasure', 'filepath', 'timestamp'};

% clear screen before starting to ask user for input
clc

%% try/catch block around everything so we can exit graceful (i.e., close all files)
try

    %% get stuff needed to run the task
    if (ischar(test) && strcmp(test,'test')) || test
        id = '99';
        stimType = 'mir';
        trigType = 'tapping';
    else
        [id, stimType, trigType] = promptForTaskInfo; % id is a string
    end

    % if this is an eeg block, initalize port codes
    if strcmpi(trigType, 'eeg')
        ioObj = io64();
        ioObj_status = io64(ioObj);
        if ioObj_status ~= 0
            disp('inp/outp installation failed!')
        end
    else
        ioObj = [];
    end

    idStr = [id,'_',stimType,'_',trigType];
    logfile       = fullfile(logFolder, [idStr,'.txt']);
    trialListFile = fullfile(logFolder, [idStr,'_trialList','.txt']);

    % deal with the case where a logfile already exists
    continuePreviousLogfile = checkIfLogfileExists(logfile, trialListFile, currentTime);
    if continuePreviousLogfile
        % get trial list from before as a cell array
        temp = readtable(trialListFile, 'Delimiter','\n', 'ReadVariableNames',false);
        trialList = temp{:,1};

        % use logfile to figure out what trial we're on, then append to the file
        temp = readtable(logfile);
        if isempty(temp)
            startTrial = 1;
        else
            startTrial = temp.trial(end) + 1;
        end
        fprintf('Starting at trial %i\n', startTrial)

        fid = fopen(logfile, 'a');

    else
        trialList = getTrialList(stimFolder, stimType, trialListFile);
        nHeaders = length(logfileHeaders);
        fid = fopen(logfile, 'w');
        formatSpec = [repmat('%s,',[1,nHeaders-1]),'%s\n'];
        fprintf(fid, formatSpec, logfileHeaders{:});
        startTrial = 1;

    end

    %% loop trials
    nTrials = length(trialList);
    for trial = startTrial:length(trialList)
        stimfile = trialList{trial};

        clc
        fprintf('Trial %i / %i\n', trial, nTrials)
        [move, pleasure] = playTrial(stimfile, stimType, trigType, ioObj, address);

        logResponse(fid, id, stimType, trigType, trial, stimfile, move, pleasure);

    end

catch err
    fprintf('\n*** WARNING ***\n')
    fprintf('There was problem running the task (error below).\n')
    fprintf('Attempting to close files first... ')
    fclose('all');
    fprintf('Done.\n')
    rethrow(err)

end

end % end function

function logResponse(fid, id, stimType, trigType, trial, fname, move, pleasure)
[pathstr, name, ext] = fileparts(fname);
name = [name, ext];
timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');

data = {id, stimType, trigType, trial, name, move, pleasure, pathstr, timestamp};
formatSpec = '%s,%s,%s,%i,%s,%i,%i,%s,%s\n';

fprintf(fid, formatSpec, data{:});

end
