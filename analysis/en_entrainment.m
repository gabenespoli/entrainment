%% en_entrainment
% Loop many participants and run en_entrainment_eeg and
%    Saves text files with all command window output
%   to getpath('entrainment'). Also reads from and/or updates the
%   processing log (getpath('proclog')).
%
% Usage:
%   en_entrainment(ids, stim, task)
%
% Input:
%   ids = [numeric] id numbers to calculate entrainment on. Default is
%       empty ([]) which will include all participants marked as 'incl' in
%       the diary file.
%
%       If the function is called with no inputs at all, it will run all
%       ids which are a) marked as 'incl' in the diary file and b) not
%       marked with a 1 in the log (i.e., all that hasn't been completed
%       yet).
%
%   stim = ['sync' or 'mir']
%
%   task = ['eeg' or 'tapping']
%
%   en_load('proclog') = [string] CSV file to save a summary of what has
%       been completed. This file marks 1 for completed without errors, 0
%       if there were errors, and NaN if the file id hasn't been touched
%       yet. Put this file in your Dropbox (or similar) to easily keep
%       track of long batch processing jobs.

function varargout = en_entrainment(ids, stims, tasks, regions)
if nargin == 0
    check_log = true; % only process files that haven't already be done
else
    check_log = false; % force re-preprocess all ids
end
if nargin < 1 || isempty(ids)
    % get ids marked as included
    d = en_load('diary', 'incl');
    ids = d.id;
end
if nargin < 2 || isempty(stims), stims = {'sync', 'mir'}; end
if nargin < 3 || isempty(tasks), tasks = {'eeg'}; end
if nargin < 4 || isempty(regions), regions = {'aud', 'pmc'}; end

% make them cells so we can loop them
stims = cellstr(stims);
tasks = cellstr(tasks);
regions = cellstr(regions);

% make sure toolboxes are loaded
en_load('eeglab')

startTime = clock;
startTimeStr = datestr(startTime, 'yyyy-mm-dd_HH-MM-SS');
timeLog = cell(0);

for i = 1:length(ids)
    id = ids(i);
    idStr = num2str(id);

    for currentStim = 1:length(stims)
        stim = stims{currentStim};

        for currentTask = 1:length(tasks)
            task = tasks{currentTask};
            timeLogInd = length(timeLog) + 1;
            err = []; % reset the error container

            if check_log && already_been_done(id, stim, task)
                % skip this file if it has already been done
                continue
            end

            % start diary file to save command window output
            fprintf('\n')
            diaryFilename = fullfile( ...
                getpath('entrainment'), ...
                [stim, '_', task], ...
                [idStr, '.log']);
            diary(diaryFilename)

            fprintf('Diary filename:    %s\n', diaryFilename)
            fprintf('Participant ID:    %i\n', id)
            fprintf('Stimulus set:      %s\n', stim)
            fprintf('Task:              %s\n', task)
            fprintf('Loop started:      %s\n', startTimeStr)
            fprintf('This ID started:   %s\n', datestr(now, 'yyyy-mm-dd_HH-MM-SS'));
            startTimeID = clock;

            % actually calculate entrainment
            try
                name = [idStr, '_', stim, '_', task];

                % make sure list of tempos is same length as number of trials
                % TODO: this is a slow hack, becuase it has reload the original bdf
                % en_epoch probably needs to save logfile_ind to a file for this to work smoothly
                L = en_load('logstim', name);
                BDF = en_load('bdf', id);
                [~, logfile_ind] = en_epoch(BDF, stim, task);
                L = L(logfile_ind, :);

                EEG = en_load('eeg', name);
                EN = eeg_entrainment(EEG, L.tempo, 'region', regions);
                EN.trial = L.trial(EN.trial); % relabel EN trials to match logfile_ind
                EN = join(EN, L, 'Keys', 'trial');
                % TODO: reorder columns of EN to be more human-readable

                filename = fullfile(getpath('entrainment'), ...
                    [stim, '_', task], [idStr, '.csv']);
                writetable(EN, filename);

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
T{T.id==id,['en_',stim,'_',task]} = val;
writetable(T, filename)
end

function val = already_been_done(id, stim, task)
filename = getpath('proclog');
T = readtable(filename);
val = false;
if T{T.id==id,['en_',stim,'_',task]} == 1
    val = true;
end
end
