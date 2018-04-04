%% en_epoch
% EEG = en_epoch(EEG, stim, task [, timelim])

function EEG = en_epoch(EEG, stim, task, timelim)

if ~ismember(lower(stim), {'sync', 'mir'})
    error('Invalid stim.')
end
if ~ismember(lower(task), {'eeg', 'tapping'})
    error('Invalid task')
end
% default extraction window
% 1 second of silence after portcode, so stimulus plays from 1-31 seconds
% leave 3 seconds to start entraining, so should start analysis at 5 seconds
% 30 epochs x 27-seconds = 13.5 minutes
if nargin < 4 || isempty(timelim)
    timelim = [1 31];
end

% EEG.setname is assumed to be the id
try
    id = str2num(EEG.setname);
catch
    error('EEG.setname should be the id.')
end

D = en_load('diary', id);

%% get event indices
% 'eventindices' param/val pair in pop_epoch is the indices of EEG.event from where
%   you want ot extract all epochs that have the labels of the events input
% so, to get all the sync trials from block 1 (of 4), you would have
% EEG = pop_epoch(EEG, syncPortcodes, [5 31], 'eventindices', 1:30)

% start with all portcode indices
eventindices = 1:length(EEG.event);

% remove extra portcodes
extra_eeg_event = D.extra_eeg_event{1};
if ~isnan(extra_eeg_event)
    disp('Removing extra portcodes...')
    eventindices(extra_eeg_event) = [];
end

% add nans for missed portcodes
missed_eeg_event = D.missedportcodes{1};
if ~isnan(missed_eeg_event)
    disp('Adding NaNs for extra portcodes...')
    for i = 1:length(missed_eeg_event)
        if missed_eeg_event(i) == 1
            eventindices = [nan eventindices]; %#ok<AGROW>
        elseif missed_eeg_event(i) == 120
            eventindices = [eventindices nan]; %#ok<AGROW>
        else
            eventindices = [eventindices(1:missed_eeg_event(i) - 1), ...
                            nan, ...
                            eventindices(missed_eeg_event(i):end)];
        end
    end
end

% get desired event indices and portcodes (event types)
if strcmpi(stim, 'sync')
    if strcmpi(task, 'eeg')

        if     D.order == 1,   eventindices = eventindices(1:30);
        elseif D.order == 2,   eventindices = eventindices(31:60);
        end

    elseif strcmpi(task, 'tapping')
        if     D.order == 1,   eventindices = eventindices(31:60);
        elseif D.order == 2,   eventindices = eventindices(1:30);
        end
    end
elseif strcmpi (stim, 'mir')
    if strcmpi(task, 'eeg')
        if     D.order == 1,   eventindices = eventindices(61:90);
        elseif D.order == 2,   eventindices = eventindices(91:120);
        end
    elseif strcmpi(task, 'tapping')
        if     D.order == 1,   eventindices = eventindices(91:120);
        elseif D.order == 2,   eventindices = eventindices(61:90);
        end
    end
end

%% cleanup and do epoching

% remove nans (probably due to some missed portcodes)
eventindices(isnan(eventindices)) = [];

% we can just lock to all events (sync and mir) because we're restricting
%   by eventindices anyway
eventTypes = unique([EEG.event.type]);
% convert numeric to cell of strings
eventTypes = regexp(num2str(eventTypes), '\s*', 'split');

% verify portcodes against the logfile
portcodes = [EEG.event.type];
portcodes = transpose(portcodes(eventindices));
L = en_load('logfile', id);
logfile_portcodes = L(L.stim==stim & L.task==task, :).portcode;
if ~all(portcodes == logfile_portcodes)
    error('The portcodes in EEG struct don''t match the portcodes in the logfile.')
end

% do epoching
EEG = pop_epoch(EEG, ...
    eventTypes, ...
    timelim, ...
    'eventindices', eventindices, ...
    'newname',      EEG.setname); % keep same setname

end
