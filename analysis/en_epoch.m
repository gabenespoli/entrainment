%% en_epoch
% EEG = en_epoch(EEG, stim, task [, timelim])

function [EEG, logfile_ind] = en_epoch(EEG, stim, task, timelim)

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

numEvents = 120;

D = en_load('diary', id);

%% get event indices
% 'eventindices' param/val pair in pop_epoch is the indices of EEG.event
%   from where you want ot extract all epochs that have the labels of the
%   events input
% so, to get all the sync trials from block 1 (of 4), you would have
% EEG = pop_epoch(EEG, syncPortcodes, [5 31], 'eventindices', 1:30)

% step through expected and actual events simultaneously
% note: it is possible to have the same event in extraEvent and
%   missedEvent; this would be in the case that a trial was repeated,
%   but the portcode that was sent is for the trial that you don't want to
%   keep

expectedEvent = nan(1, numEvents); % a position for each expected event
    % each position contains the index of the corresponding event
    %   in actualEvent
missedEvent = D.missed_eeg_event{1}; % expected events that were missed
expectedInd = 1; % eventindices

actualEvent = 1:length(EEG.event); % actual events that were sent
extraEvent = D.extra_eeg_event{1}; % extra events that were sent
actualInd = 1; % EEG.event event indices

while expectedInd <= numEvents
    % do the continuing with a variable, so we can check both extra and
    %   missed, and then continue if either (or both) of them were true
    do_continue = false;

    % skip over the actual event that was extra
    if ismember(actualInd, extraEvent)
        actualInd = actualInd + 1;
        do_continue = true;
    end
    % skip over the expected event that wasn't sent
    if ismember(expectedInd, missedEvent)
        expectedInd = expectedInd + 1;
        do_continue = true;
    end
    if do_continue
        continue
    end

    expectedEvent(expectedInd) = actualEvent(actualInd);
    expectedInd = expectedInd + 1;
    actualInd = actualInd + 1;
end

% get desired event indices and portcodes (event types)
if strcmpi(stim, 'sync')
    if strcmpi(task, 'eeg')
        if     D.order == 1,   eventindices = expectedEvent(1:30);
        elseif D.order == 2,   eventindices = expectedEvent(31:60);
        end
    elseif strcmpi(task, 'tapping')
        if     D.order == 1,   eventindices = expectedEvent(31:60);
        elseif D.order == 2,   eventindices = expectedEvent(1:30);
        end
    end
elseif strcmpi (stim, 'mir')
    if strcmpi(task, 'eeg')
        if     D.order == 1,   eventindices = expectedEvent(61:90);
        elseif D.order == 2,   eventindices = expectedEvent(91:120);
        end
    elseif strcmpi(task, 'tapping')
        if     D.order == 1,   eventindices = expectedEvent(91:120);
        elseif D.order == 2,   eventindices = expectedEvent(61:90);
        end
    end
end

% remove nans (probably due to some missed portcodes)
nanind = isnan(eventindices);
eventindices(nanind) = [];
logfile_ind = find(~nanind);

% get actual values of events
portcodes = transpose([EEG.event.type]);
portcodes = portcodes(eventindices);

% verify event values against the logfile
L = en_load('logfile', id);
logfile_portcodes = L(L.stim==stim & L.task==task, :).portcode;
if ~all(portcodes == logfile_portcodes(~nanind))
    error('The portcodes in EEG struct don''t match the portcodes in the logfile.')
end

%% do epoching
% we can just lock to all events (sync and mir) because we're restricting
%   by eventindices anyway
eventTypes = unique([EEG.event.type]);
% convert numeric to cell of strings
eventTypes = regexp(num2str(eventTypes), '\s*', 'split');

% do epoching
EEG = pop_epoch(EEG, ...
    eventTypes, ...
    timelim, ...
    'eventindices', eventindices, ...
    'newname',      EEG.setname); % keep same setname

end
