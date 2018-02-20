function [trialList, startTrial, logfileFid] = getTrialList(id, logFolder, ...
    logfileHeaders, stimFolder, stimType, trigType, currentTime)
% INPUT
%   logFolder:      String 
%   logFileHeaders: Cell of strings with headers for a new logfile.
%   stimFolder:     String 
%   stimType:       'mir' or 'sync'
%   trigType:       'eeg' or 'tapping'
%   currentTime:    String with a date string for appending to an old file.
%
% OUTPUT
%   trialList:      Cell array of filenames in randomized order. If certain 
%                   files are to be repeated, they are present multiple times.
%                   If 'currentTime' is given, this list is written to a
%                   trialListFile in the current directory.
%   startTrial:     Number of the trial to start on. Will be 1 if a new
%                   logfile is created.
%   logfileFid:    File id of logfile.

% filenames
%   mir         tempo       sync
%   101-130      90         11,21,31,41,51,61 (1's)
%   131-160      96         12,22,32,42,52,62 (2's)
%   161-190      102        13,23,33,43,53,63 (3's)
%   191-220      108        14,24,34,44,54,64 (4's)
%   221-250      114        15,25,35,45,55,65 (5's)

% sync order
%   LR3     11,12,13,14,15 (10's)
%   LR6     21,22,23,24,25 (20's)
%   MR1     31,32,33,34,35 (30's)
%   MR2     41,42,43,44,45 (40's)
%   HR1     51,52,53,54,55 (50's)
%   HR3     61,62,63,64,65 (60's)

% if nargin < 3 || isempty(trialListFile)
    % trialListFile = ['trialList_', datestr(now, 'yyyy-mm-dd_HH-MM-SS')];
% end

stimExt = '.wav';

% make filenames
idStr         = [id,'_',stimType,'_',trigType];
logfile       = fullfile(logFolder, [idStr,'.csv']);
trialListFile = fullfile(logFolder, [idStr,'_trialList','.txt']);

% deal with the case where a logfile already exists
continuePreviousLogfile = checkIfLogfileExists(logfile, trialListFile, ...
                                               currentTime);

if continuePreviousLogfile
    % get trial list from before as a cell array
    tempTrialList = readtable(trialListFile, ...
                              'Delimiter','\n', ...
                              'ReadVariableNames',false);
    trialList = tempTrialList{:,1};

    % use logfile to figure out what trial we're on, then append to the file
    tempLogfile = readtable(logfile);
    if isempty(tempLogfile)
        startTrial = 1;
    else
        if ismember('trial', fieldnames(tempLogfile))
            startTrial = tempLogfile.trial(end) + 1;
        else
            error('Can''t find trial to continue from.')
        end
    end

    logfileFid = fopen(logfile, 'a');


else % make new logfile and trial list
    % add tempo jitter
    % trialList is a numeric vector of filenames/portcodes
    switch lower(stimType)
        case 'mir'
            jitter = randi(5, 30, 1);
            jitter = jitter * 30 + 70;
            trialList = transpose(1:30);
            trialList = trialList + jitter;

        case 'sync'
            jitter = randi(5, 30, 1);
            trialList = repmat([1 2 3 4 5 6]', 5, 1);
            trialList = (trialList * 10) + jitter;

        case 'tempo'
            trialList = 90:1:114;
    end

    % make filenames
    % turn list of numbers into a cell array of filepaths
    trialList = cellfun(@num2str, ...
                        num2cell(trialList), ...
                        'UniformOutput', false);
    trialList = cellfun(@(x) fullfile(stimFolder, [x, stimExt]), ...
                        trialList, ...
                        'UniformOutput', false);

    % randomize order
    trialList = trialList(randperm(length(trialList)));

    % write trial list to file
    trialList_fid = fopen(trialListFile, 'w');
    fprintf(trialList_fid, '%s\n', trialList{:});
    fclose(trialList_fid);

    % start logfile
    nHeaders = length(logfileHeaders);
    logfileFid = fopen(logfile, 'w');
    formatSpec = [repmat('%s,',[1,nHeaders-1]),'%s\n'];
    fprintf(logfileFid, formatSpec, logfileHeaders{:});
    startTrial = 1;

end
end

function continuePrevious = checkIfLogfileExists(logfile, trialListFile, ...
                                                 currentTime)
if exist(logfile, 'file')

    % prompt for whether to continue previous file
    fprintf('\nLogfile ''%s'' already exists.\n', logfile)

    % TODO: check to see if the existing logfile has already been completed?
    goodResp = false;
    while ~goodResp

        resp = input('Start [n]ew logfile, [c]ontinue previous, or [q]uit? ', 's');
        switch lower(resp)
            case 'n'
                continuePrevious = false;
                addTimestampToFile(logfile, currentTime)
                addTimestampToFile(trialListFile, currentTime)
                goodResp = true;
                
            case 'c'
                continuePrevious = true;
                goodResp = true;
                
            case 'q'
                return
        end
    end

else
    continuePrevious = false;
end
end

function addTimestampToFile(fname,timestamp)
[pathstr,name,ext] = fileparts(fname);
newname = fullfile(pathstr, [name, '_', timestamp, ext]);
movefile(fname, newname);
end
