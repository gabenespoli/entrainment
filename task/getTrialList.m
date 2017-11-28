function [trialList, startTrial, logfile_fid] = getTrialList(logFolder, ...
    logfileHeaders, stimFolder, stimType, trigType, currentTime)
% trialList:        Cell array of filenames in randomized order. If certain 
%                   files are to be repeated, they are present multiple times.
%                   If 'currentTime' is given, this list is written to a
%                   trialListFile in the current directory.
% startTrial:       Number of the trial to start on. Will be 1 if a new
%                   logfile is created.
% logfile_fid:      File id of logfile.
%                   
% logFolder:        String 
% logFileHeaders:   Cell of strings with headers for a new logfile.
% stimFolder:       String 
% stimType:         'mir' or 'sync'
% trigType:         'eeg' or 'tapping'
% currentTime:      String with a date string for appending to an old file.

% filenames
%   mir         tempo       sync
%   101-130      90         11-16
%   131-160      96         21-26
%   161-190      102        31-36
%   191-220      108        41-46
%   221-250      114        51-56

% sync order
%   LR3     11,21,31,41,51
%   LR6     12,22,32,42,52
%   MR1     13,23,33,43,53
%   MR2     14,24,34,44,54
%   HR1     15,25,35,45,55
%   HR3     16,26,36,46,56

% if nargin < 3 || isempty(trialListFile)
    % trialListFile = ['trialList_', datestr(now, 'yyyy-mm-dd_HH-MM-SS')];
% end

% make filenames
idStr         = [id,'_',stimType,'_',trigType];
logfile       = fullfile(logFolder, [idStr,'.txt']);
trialListFile = fullfile(logFolder, [idStr,'_trialList','.txt']);

% deal with the case where a logfile already exists
continuePreviousLogfile = checkIfLogfileExists(logfile, trialListFile, ...
                                               currentTime);

if continuePreviousLogfile
    % get trial list from before as a cell array
    temp = readtable(trialListFile, ...
                     'Delimiter','\n', ...
                     'ReadVariableNames',false);
    trialList = temp{:,1};

    % use logfile to figure out what trial we're on, then append to the file
    temp = readtable(logfile);
    if isempty(temp)
        startTrial = 1;
    else
        startTrial = temp.trial(end) + 1;
    end

    logfile_fid = fopen(logfile, 'a');


else % make new logfile and trial list
    % add tempo jitter
    switch lower(stimType)
        case 'mir'
            jitter = randi(5, 30, 1);
            jitter = jitter * 30 + 70;
            trialList = transpose(1:30);
            trialList = trialList + jitter;

        case 'sync'
            jitter = randi(5, 30, 1);
            jitter = jitter * 10;
            trialList = repmat([1 2 3 4 5 6]', 5, 1);
            trialList = trialList + jitter;
    end

    % make filenames
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
    logfile_fid = fopen(logfile, 'w');
    formatSpec = [repmat('%s,',[1,nHeaders-1]),'%s\n'];
    fprintf(logfile_fid, formatSpec, logfileHeaders{:});
    startTrial = 1;

end
end

function continuePrevious = checkIfLogfileExists(logfile, trialListFile, ...
                                                 currentTime)
if exist(logfile, 'file')

    % prompt for whether to continue previous file
    fprintf('\nLogfile ''%s'' already exists.\n', logfile)

    % TODO check to see if the existing logfile has already been completed?
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
