function TAP = en_preprocess_tapping(id, stim, do_save, numMarkersPrompt)

if nargin < 2 || isempty(stim)
    stim = 'sync';
end
if nargin < 3 || isempty(do_save)
    do_save = true;
end
if nargin < 4 || isempty(numMarkersPrompt)
    numMarkersPrompt = false;
end
numEvents = 60;

%% load midi and diary data
[M, y, Fs] = en_load('midi', id);
D = en_load('diary', id);

%% get marker times
% first find out how many midi events were sent
numActualEvents = numEvents;
if ~isempty(D.missed_midi_event{1})
    numActualEvents = numActualEvents - length(D.missed_midi_event{1});
end
if ~isempty(D.extra_midi_event{1})
    numActualEvents = numActualEvents + length(D.extra_midi_event{1});
end

% findAudioMarkers settings
if isnan(D.midi_audio_marker_threshold)
    threshold = 0.001;
else
    threshold = D.midi_audio_marker_threshold;
end
if isnan(D.midi_timeBetween_secs)
    timeBetween = 2 * Fs;
else
    timeBetween = D.midi_timeBetween_secs * Fs;
end

times = findAudioMarkers( ...
    transpose(y), ...       % waveform
    threshold, ...          % threshold
    timeBetween, ...        % timeBetween
    'plotMarkers',          false, ...
    'numMarkers',           numActualEvents, ... 
    'numMarkersPrompt',     numMarkersPrompt);
times = times / Fs; % convert from samples to seconds
if ~iscolumn(times), times = transpose(times); end % make column vector

%% account for extra and missed events
expectedEvent = nan(1, numEvents); % a position for each expected event
    % each position contains the index of the corresponding event
    %   in actualEvent
missedEvent = D.missed_midi_event{1}; % expected events that were missed
expectedInd = 1; % eventindices

actualEvent = 1:length(times); % actual events that were sent, we don't know this yet
extraEvent = D.extra_midi_event{1}; % extra events that were sent
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

% if length(times) ~= numEvents, error('There are an incorrect number of trials.'), end
% if ~isempty(D.extra_midi_event{1})
%     fprintf('Removing %i MIDI events...\n', length(D.extra_midi_event{1}))
%     times(D.extra_midi_event{1}) = [];
% end

% make a vector the same length as times, where each position is the
%   corresponding trial number
trial = 1:numEvents;
trial(isnan(expectedEvent)) = [];

%% epoching
% make one row per trial instead of one row per tap
% add columns for stim and trial number
for i = 1:length(times)
    % get inds of M that match the current time
    if i < length(times)
        ind = M.onset >= times(i) & M.onset < times(i+1);
    else
        ind = M.onset >= times(i);
    end

    % start this row of the table and add stim and trial columns
    % remember that sync and mir are always in the same order
    %   so sync = 1:30 and mir = 31:60
    TMP = table(trial(i), 'VariableNames', {'trial'});
    if ismember(trial(i), 1:30)
        TMP.stim = {'sync'};
    elseif ismember(trial(i), 31:60)
        TMP.stim = {'mir'};
        TMP.trial(1) = TMP.trial(1) - 30;
    else
        error('Too many trials.')
    end

    % add the rest of M by trials (mutiple taps into one table row)
    names = M.Properties.VariableNames;
    for j = 1:length(names)
        TMP.(names{j}) = {M.(names{j})(ind)};
    end

    if i == 1
        OUT = TMP;
    else
        OUT = [OUT; TMP]; %#ok<AGROW>
    end
end
M = OUT;
M.stim = categorical(M.stim);

% reorder and restrict to a few needed columns only
M = M(:, {'stim', 'trial', 'onset', 'duration', 'velocity'});

M = M(M.stim==stim, :);
M(:, 'stim') = [];

%% join data with logfile
L = en_load('logstim', id);
L = L(L.stim==stim & L.task=='tapping', :);

% join with M first, in case there are missing events
TAP = join(M, L, 'Keys', 'trial');

% reorder columns
Lcols = L.Properties.VariableNames;
Mcols = M.Properties.VariableNames;
Mcols(ismember(Mcols, 'trial')) = [];
TAP = TAP(:, [Lcols, Mcols]);

if do_save
    filename = fullfile(getpath('tapping'), stim, [num2str(id), '.mat']);
    fprintf('Saving tapping data to file...\n')
    fprintf('''%s''\n', filename)
    save(filename, 'TAP')
    fprintf('Done.\n')
end

end
