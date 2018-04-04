function TAP = en_preprocess_tapping(id, stim, do_save)

if nargin < 2 || isempty(stim)
    stim = 'sync';
end
if nargin < 3 || isempty(do_save)
    do_save = true;
end

%% load midi data
[M, y, Fs] = en_load('midi', id);

%% get parameters from diary
D = en_load('diary', id);
if isempty(D.extra_midi_event{1})
    numMarkers = 60;
else
    numMarkers = 60 + length(D.extra_midi_event{1});
end
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

%% get marker times
times = findAudioMarkers( ...
    transpose(y), ...       % waveform
    threshold, ...          % threshold
    timeBetween, ...        % timeBetween
    'plotMarkers',          false, ...
    'numMarkers',           numMarkers, ... 
    'numMarkersPrompt',     0);
times = times / Fs; % convert from samples to seconds
if ~iscolumn(times), times = transpose(times); end % make column vector
if length(times) ~= numMarkers, error('There are an incorrect number of trials.'), end
if ~isempty(D.extra_midi_event{1})
    fprintf('Removing %i MIDI events...\n', length(D.extra_midi_event{1}))
    times(D.extra_midi_event{1}) = [];
end

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
    TMP = table(i, 'VariableNames', {'trial'});
    if ismember(i, 1:30)
        TMP.stim = {'sync'};
    elseif ismember(i, 31:60)
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

TAP = join(L, M, 'Keys', 'trial');

if do_save
    filename = fullfile(getpath('tapping'), stim, [num2str(id), '.mat']);
    fprintf('Saving tapping data to file...\n')
    fprintf('''%s''\n', filename)
    save(filename, 'TAP')
    fprintf('Done.\n')
end

end
