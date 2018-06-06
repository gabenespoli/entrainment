function EN = en_entrainment_tapping(TAP, stim, do_save, matchwarn)
% Usage:
%   EN = en_entrainment_tapping(TAP, stim, do_save, matchwarn)
%
% Input:
%   TAP: TAP table or numeric id
%   stim: 'sync' or 'mir', default 'sync'
%   do_save: save a csv. default true
%   matchwarn: warn if multiple taps are matched to the same beat
%
% Output:
%   EN = [table]
%

stimLength = 40; % in seconds; make longer than stim to capture all beats

if nargin < 2 || isempty(stim)
    stim = 'sync';
end
if nargin < 3 || isempty(do_save)
    do_save = true;
end
if nargin < 4 || isempty(matchwarn)
    matchwarn = false;
end

% get preprocessed TAP table
if isnumeric(TAP)
    % id = TAP; % unneeded
    idStr = num2str(TAP);
    TAP = en_load('tapping', [idStr, '_', stim]);
elseif istable(TAP)
    id = TAP.id(1);
    if ~all(TAP.id == id)
        error('All rows in TAP must be from the same id.')
    end
    idStr = num2str(id);
else
    error('Input must be an TAP struct or an ID number.')
end
% make output table and remove unneeded columns
EN = TAP;
EN(:, {'start', 'onset', 'duration', 'velocity'}) = [];

% generate stimulus beat onset times
S = en_load('stiminfo');
S.allbeats = cell(height(S), 1);
for i = 1:height(S)
    numBeats = S.tempo(i) * stimLength;
    S.allbeats{i} = (1 / S.tempo(i)) * transpose(0:numBeats - 1);
end

% add allbeats to TAP table, taking start times into account
TAP.allbeats = cell(height(TAP), 1);
for i = 1:height(TAP)
    TAP.allbeats{i} = S.allbeats{S.portcode==TAP.portcode(i)} + TAP.start(i);
end

%% extract tapping features
% make containers
TAP.beats = cell(height(TAP), 1);
EN.asynchrony = nan(height(TAP), 1);
EN.variability = nan(height(TAP), 1);
EN.coeffofvar = nan(height(TAP), 1);
EN.duration = nan(height(TAP), 1);
EN.velocity = nan(height(TAP), 1);

% loop trials
for i = 1:height(TAP)

    % align taps with the closest beat
    taps = TAP.onset{i};
    allbeats = TAP.allbeats{i};
    beats = nan(size(taps));
    ind = nan(size(taps));
    for j = 1:length(taps)
        [~, ind(j)] = min(abs(taps(j) - allbeats));
        % check if ind is different than the previous
        if matchwarn && (j > 1 && ind(j) <= ind(j-1))
            warning('Two taps might be matched to the same beat.')
        end
        beats(j) = allbeats(ind(j));
    end
    TAP.beats{i} = beats;

    % extract features
    asynchrony = beats - taps;
    EN.asynchrony(i) = mean(asynchrony);
    EN.variability(i) = std(asynchrony);
    EN.coeffofvar(i) = std(asynchrony) / abs(mean(asynchrony));
    EN.duration(i) = mean(TAP.duration{i});
    EN.velocity(i) = mean(TAP.velocity{i});
end

if do_save
    EN.Properties.UserData.filename = fullfile(getpath('taptrainment'), ...
        stim, [idStr, '.csv']);
    writetable(EN, EN.Properties.UserData.filename)
end

end

%% meeting with paolo

% - use center of duration? no
% - look at peter keller's work for methods
% - if tapping heavy, get multiple taps for one
%   - discard taps with ITI out of range?
%   - double tap threshold of 100 ms 
%       - 200 ms pecenka 2011
%       - what percentage of IOI?
%       - take closest value (maybe first one?)
%   - if someone is bad at the task, taps too far away from a beat 
        %- (25% of IOI; keller and repp 2004)
%   - patel and iverson, 
% - if want analysis of rate or IOI, need to deal with missed taps
% - circstats
%   - raleighs test, if sig, taps are equally distributed
%   - mean relative phase
%   - circular variance
%   - convert onset times to relative phase
% * variability of asynchrony
%   - std of each trial
%   - coeff of var (good if different tempo condidionts)
%   - there are well-estabsilshed tempo effects
%   - then look at really bad ones, cater preproc to them
% - reject if too few or too many taps
% - lag 4 autocorrelation to look at meter

% Fitch & Rosenfeld (2007)
%   - align each tap with the closest beat
%   - add nans for missing values
%   - calculate [mean] asynchrony

% from @Fitch2007
% The experimental program generated a file with two columns of times for each trial: the “correct” time as predicted by the computer, and the actual time at which the subject tapped. Each tap occupied a single row. The times of participants’ taps were first aligned with the temporally closest computer generated pulse by the analysis software. The algorithm shifted the two data columns relative to each other by adding empty rows until each tap was in the same row as the nearest com- puter pulse. An empty row was left in the column of computer pulses if the subject added an extra pulse, while an empty row was left in the column of subject taps if the subject missed a pulse. Because our interest is in participants’ temporal accuracies for correct notes, these missed and extraneous taps were ignored in the subsequent temporal error analysis. For each tap, the error was calculated by comparing the time of the sub- ject’s tap and the time of the computer generated pulse (see Figure 4), and then took the absolute value of the difference between these two times. This error was normalized across tempos by dividing the observed interpulse interval by the correct interval between pulses, generating an error proportional to the correct local interpulse interval. The errors were then sub- tracted from 1 to convert to normalized accuracy per tap (with 1.0 signifying perfect accuracy). The accuracy per tap was then averaged over the entire trial to gener- ate a mean accuracy per trial for the pulse-tracking task, that was independent across tempos.
% The number of “reset” events in each trial was also tallied as a measure of accuracy. A reset event was scored when a subject’s tap occurred closer in time to the syncopated pulse (the “offbeat”) than to the correct, unsyncopated pulse (the “onbeat”), where the synco- pated pulse falls exactly midway between unsyncopated pulses (Figure 5). After the data had been optimally aligned, the number of reset events as so defined was summed for each trial.
