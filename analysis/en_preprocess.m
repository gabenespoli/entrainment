%% en_preprocess
% Loop many participants and run en_preprocess_eeg. Saves hidden text files
%   with all command window output to getpath('eeg'). Also marks up a
%
% Usage:
%   en_eeg_loop(ids, stim, task, master_log_filename)
%
% Input:
%   ids = [numeric] id numbers to run preprocessing on. Default is all
%       participants marked as 'incl' in the diary file. Enter 0 to run
%       all participants marked as 'incl' as well as not marked with a 0
%       in the master log file.
%
%   stim = ['sync' or 'mir']
%
%   task = ['eeg' or 'tapping']
%
%   master_log_filename = [string] CSV file to save a summary of what has
%       been completed. This file marks 1 for completed without errors, 0
%       if there were errors, and NaN if the file id hasn't been touched
%       yet. Put this file in your Dropbox (or similar) to easily keep
%       track of long batch processing jobs.

function varargout = en_preprocess(ids, stims, tasks)
if nargin < 1 || isempty(ids)
    % get ids marked as included
    d = en_load('diary', 'incl');
    ids = d.id;
end
if nargin < 2 || isempty(stims), stims = {'sync', 'mir'}; end
if nargin < 3 || isempty(tasks), tasks = {'eeg', 'tapping'}; end

master_log_filename = fullfile(getpath('analysis'), 'en_preprocess_log.csv');

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

                % start diary file to save command window output
                % make diary a hidden file
                if ismac || isunix
                    hidechar = '.';
                elseif ispc
                    hidechar = '_';
                else
                    hidechar = '';
                end
                diaryFilename = fullfile( ...
                    getpath('eeg'), ...
                    [stim, '_', task], ...
                    [hidechar, num2str(id), '.log']);
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
                    en_preprocess_tapping(id, stim);
                    timeLog{timeLogInd} = '  ';
                    write_to_master_log(master_log_filename, id, stim, task, 1)

                catch err
                    timeLog{timeLogInd} = '! ';
                    write_to_master_log(master_log_filename, id, stim, task, 0)

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

% save elapsed time and errors for all ids to file
fid = fopen(fullfile(getpath('analysis'), 'looplogs', ...
    ['loop_log_', startTimeStr, '.txt']), 'w');
fprintf(fid, 'Loop summary\n');
for i = 1:length(ids)
    fprintf(fid, '%i: %s\n\n', ids(i), timeLog{i});
end
fprintf(fid, 'Total time: %s\n', getElapsedTime(startTime));
fclose(fid);

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
 
function write_to_master_log(filename, id, stim, task, val)
T = readtable(filename);
T{T.id==id,['pre_',stim,'_',task]} = val;
writetable(T, filename)
end
