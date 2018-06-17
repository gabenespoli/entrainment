%% en_preprocess
% Loop many participants and run en_preprocess_eeg and
%   en_preprocess_tapping. Saves text files with all command window output
%   to getpath('eeg'). Also reads from and/or updates the processing log
%   (getpath('proclog')).
%
% Usage:
%   en_preprocess
%   en_preprocess(ids, stim, task, check_log)
%
% Input:
%   ids = [numeric] id numbers to run preprocessing on. Default is empty 
%       ([]) which will include all participants marked as 'incl' in the
%       diary file.
%
%       If the function is called with no inputs at all, it will run all
%       ids which are a) marked as 'incl' in the diary file and b) not
%       marked with a 1 in the preprocessing log (i.e., all preprocessing
%       that hasn't been completed yet).
%
%   stim = ['sync' or 'mir']
%
%   task = ['eeg' or 'tapping']
%
%   check_log = [boolean] Check en_log.csv and only preprocessed files that
%       haven't been done yet. If zero input args are given, default true.
%       If input args are given, default false.
%
%   en_load('proclog') = [string] CSV file to save a summary of what has
%       been completed. This file marks 1 for completed without errors, 0
%       if there were errors, and NaN if the file id hasn't been touched
%       yet. Put this file in your Dropbox (or similar) to easily keep
%       track of long batch processing jobs.

function varargout = en_preprocess(ids, stims, tasks, check_log)
if nargin == 0
    check_log = true; % only process files that haven't already be done
elseif nargin < 4
    check_log = false; % force re-preprocess all ids
end
if nargin < 1 || isempty(ids)
    % get ids marked as included
    d = en_load('diary', 'incl');
    ids = d.id;
end
if nargin < 2 || isempty(stims), stims = {'sync', 'mir'}; end
if nargin < 3 || isempty(tasks), tasks = {'eeg'}; end

% make them cells so we can loop them
stims = cellstr(stims);
tasks = cellstr(tasks);

% make sure toolboxes are loaded
en_load('eeglab')
en_load('miditoolbox')

startTime = clock;
startTimeStr = datestr(startTime, 'yyyy-mm-dd_HH-MM-SS');
timeLog = cell(0);

for i = 1:length(ids)
    id = ids(i);

    for currentStim = 1:length(stims)
        stim = stims{currentStim};

        for currentTask = 1:length(tasks)
            task = tasks{currentTask};
            timeLogInd = length(timeLog) + 1;

            if check_log && already_been_done(id, stim, task)
                % skip this file if it has already been done
                continue
            end

                % start diary file to save command window output
                diaryFilename = fullfile( ...
                    getpath('eeg'), ...
                    [stim, '_', task], ...
                    [num2str(id), '.log']);
                diary(diaryFilename)

                fprintf('Diary filename:    %s\n', diaryFilename)
                fprintf('Participant ID:    %i\n', id)
                fprintf('Stimulus set:      %s\n', stim)
                fprintf('Task:              %s\n', task)
                fprintf('Loop started:      %s\n', startTimeStr)
                fprintf('This ID started:   %s\n', datestr(now, 'yyyy-mm-dd_HH-MM-SS'));
                startTimeID = clock;

                err = []; % reset the error container
                try
                    en_preprocess_eeg(id, stim, task);
                    timeLog{timeLogInd} = '  ';
                    write_proclog(id, stim, task, 1)

                catch err
                    timeLog{timeLogInd} = '! ';
                    write_proclog(id, stim, task, 0)

                    % display the error without terminating the loop
                    disp(err)
                    for j = 1:length(err.stack)
                        disp(err.stack(j))
                    end

                    % return err if output arg requested
                    if nargout > 0
                        varargout{1} = err;
                    end

                end

                % save and print the elapsed time for this id
                timeLog{timeLogInd} = [timeLog{timeLogInd}, getElapsedTime(startTimeID)];
                fprintf('%s\n\n', timeLog{timeLogInd})

                diary off

                % adjust diary filename to indicate errors
                [pathstr, name, ext] = fileparts(diaryFilename);
                errorFilename = fullfile(pathstr, [name, '_ERROR', ext]);
                if ~isempty(err)
                    % if there were errors, use the error filename instead
                    movefile(diaryFilename, errorFilename)
                elseif exist(errorFilename, 'file')
                    % if there were no errors, delete previous diary that had errors
                    delete(errorFilename)
                end

        end
    end
end

end

function str = getElapsedTime(startTime)
% startTime is the output of the clock function
startTime = datevec(datenum(clock - startTime));
ind = find(startTime == 0, 1, 'last') + 1;
if isempty(ind), ind = 1; end
switch ind
    case 1, str = 'years'; return
    case 2, units = 'months';   x = 12;
    case 3, units = 'days';     x = 30.436875;
    case 4, units = 'hours';    x = 24;
    case 5, units = 'minutes';  x = 60;
    case 6, str = [num2str(startTime(ind)), ' seconds']; return
end
% approximate time to make it readable
t = startTime(ind) + startTime(ind + 1) / x;
str = [num2str(t), ' ', units];
end
 
function write_proclog(id, stim, task, val)
filename = getpath('proclog');
T = readtable(filename);
T{T.id==id,['pre_',stim,'_',task]} = val;
writetable(T, filename)
end

function val = already_been_done(id, stim, task)
filename = getpath('proclog');
T = readtable(filename);
val = false;
if T{T.id==id,['pre_',stim,'_',task]} == 1
    val = true;
end
end
