%% en_eeg_loop
% Loop many participants and run en_preprocess_eeg. Saves text files with
% all command window output to the folder en_getpath('eeg'). Files
% are named by the starting date and time of the loop.
%
% Usage:
%   en_eeg_loop(id, stim, task)

function en_eeg_loop(id, stim, task)
if nargin < 2 || isempty(stim), stim = 'sync'; end
if nargin < 3 || isempty(task), task = 'eeg'; end

startTime = clock;
startTimeStr = datestr(startTime, 'yyyy-mm-dd_HH-MM-SS');
timeLog = cell(1, length(id));

for i = 1:length(id)

    % start diary file to save command window output
    diary(fullfile(en_getpath('eeg'), ...
        [num2str(id(i)), '_en_eeg_preprocess_', startTimeStr, '.txt']))

    fprintf('Participant ID: %i\n', id(i))
    fprintf('This ID started: %s\n', datestr(now, 'yyyy-mm-dd_HH-MM-SS'));
    fprintf('Loop started: %s\n', startTimeStr)
    startTimeID = clock;

    try
        en_preprocess_eeg(id(i), stim, task);

    catch err
        % save error message
        timeLog{i} = [' ** Error **\n', getReport(err)];

    end

    % save and print the elapsed time for this id
    timeLog{i} = [getElapsedTime(startTimeID), timeLog{i}];
    fprintf('%s\n', timeLog{i})

    diary off
end

% save elapsed time and errors for all ids to file
fid = fopen(fullfile(en_getpath('eeg'), ...
    ['loop_log_', startTimeStr, '.txt']), 'w');
fprintf(fid, 'Loop summary\n');
for i = 1:length(id)
    fprintf(fid, '%i: %s\n\n', id(i), timeLog{i});
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
