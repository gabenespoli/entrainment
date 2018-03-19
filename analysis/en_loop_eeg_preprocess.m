%% en_loop_eeg_preprocess
% Loop many participants and run en_preprocess_eeg. Saves text files with
% all command window output to the folder en_getpath('eeg'). Files
% are named by the starting date and time of the loop.
%
% Usage:
%   en_eeg_loop(ids, stim, task)

function en_loop_eeg_preprocess(ids, stims, tasks)
if nargin < 1 || isempty(ids)
    d = en_load('diary', 'incl');
    ids = d.id;
end
if nargin < 2 || isempty(stims), stims = 'sync'; end
if nargin < 3 || isempty(tasks), tasks = 'eeg'; end

% make them cells so we can loop them
stims = cellstr(stims);
tasks = cellstr(tasks);

startTime = clock;
startTimeStr = datestr(startTime, 'yyyy-mm-dd_HH-MM-SS');
timeLog = cell(0);

for i = 1:length(ids)
    id = ids(i);

    for currentStim = 1:length(stims)
        stim = stim{currentStim};

        for currentTask = 1:length(tasks)
            task = task{currentTask};
            timeLogInd = length(timeLog) + 1;

                % start diary file to save command window output
                diary(fullfile(en_getpath('eeg'), ...
                    [num2str(id), '_', stim '_', task, '_log_', startTimeStr, '.txt']))

                fprintf('Participant ID: %i\n', id)
                fprintf('Stimulus set: %s\n', stim)
                fprintf('Task: %s\n', task)
                fprintf('Loop started: %s\n', startTimeStr)
                fprintf('This ID started: %s\n', datestr(now, 'yyyy-mm-dd_HH-MM-SS'));
                startTimeID = clock;

                try
                    en_eeg_preprocess(id, stim, task);

                catch err
                    % save error message
                    timeLog{timeLogInd} = [' ** Error **\n', getReport(err)];

                end

                % save and print the elapsed time for this id
                timeLog{timeLogInd} = [getElapsedTime(startTimeID), timeLog{timeLogInd}];
                fprintf('%s\n', timeLog{timeLogInd})

                diary off
        end
    end
end

% save elapsed time and errors for all ids to file
fid = fopen(fullfile(en_getpath('eeg'), ...
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
    case 1, units = 'years';    x = nan;
    case 2, units = 'months';   x = 12;
    case 3, units = 'days';     x = 30.436875;
    case 4, units = 'hours';    x = 24;
    case 5, units = 'minutes';  x = 60;
    case 6, units = 'seconds';  x = 60;
end
% approximate time to make it readable
t = startTime(ind) + startTime(ind + 1) / x;
str = [num2str(t), ' ', units];
end
