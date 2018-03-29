%% en_loop_eeg_preprocess
% Loop many participants and run en_preprocess_eeg. Saves text files with
% all command window output to the folder en_getpath('eeg'). Files
% are named by the starting date and time of the loop.
%
% Usage:
%   en_eeg_loop(ids, stim, task)

function en_loop_eeg_preprocess(ids, stims, tasks)
if nargin < 1 || isempty(ids)
    % get ids marked as included
    d = en_load('diary', 'incl');
    ids = d.id;
end
if nargin < 2 || isempty(stims), stims = {'sync', 'mir'}; end
if nargin < 3 || isempty(tasks), tasks = {'eeg', 'tapping'}; end

% make them cells so we can loop them
stims = cellstr(stims);
tasks = cellstr(tasks);

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
                diaryFilename = fullfile( ...
                    en_getpath('eeg'), ...
                    [stim, '_', task], ...
                    [num2str(id), '_log_', startTimeStr, '.txt']);
                diary(diaryFilename)

                fprintf('Diary filename:    %s\n', diaryFilename)
                fprintf('Participant ID:    %i\n', id)
                fprintf('Stimulus set:      %s\n', stim)
                fprintf('Task:              %s\n', task)
                fprintf('Loop started:      %s\n', startTimeStr)
                fprintf('This ID started:   %s\n', datestr(now, 'yyyy-mm-dd_HH-MM-SS'));
                startTimeID = clock;

                try
                    en_eeg_preprocess(id, stim, task);
                    timeLog{timeLogInd} = '  ';

                catch
                    timeLog{timeLogInd} = '! ';

                end

                % save and print the elapsed time for this id
                timeLog{timeLogInd} = [timeLog{timeLogInd}, getElapsedTime(startTimeID)];
                fprintf('%s\n\n', timeLog{timeLogInd})

                diary off
        end
    end
end

% save elapsed time and errors for all ids to file
fid = fopen(fullfile(en_getpath('analysis'), 'looplogs', ...
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
 
