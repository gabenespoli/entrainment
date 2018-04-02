function TAP = en_preprocess_tapping(id, stim)

if nargin < 2
    stim = 'sync';
end

L = en_load('logstim', id);
L = L(L.stim==stim & L.task=='tapping', :);


[M, y, Fs] = en_load('midi', id);

%% first get marker times
times = findAudioMarkers( ...
    transpose(y), ...   % waveform
    0.001, ...          % threshold
    2 * Fs, ...         % timeBetween
    'plotMarkers',      false, ...
    'numMarkers',       numMarkers, ... 
    'numMarkersPrompt', 0);    
times = times / Fs; % convert from samples to seconds
if ~iscolumn(times), times = transpose(times); end % make column vector
if length(times) ~= 60, error('There aren''t 60 trials.'), end

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


%% from before
M = M(M.stim==stim, :);
M(:, 'stim') = [];

TAP = join(L, M, 'Keys', 'trial');

filename = fullfile(getpath('tapping'), stim, [num2str(id), '.mat']);
save(filename, 'TAP')

end
