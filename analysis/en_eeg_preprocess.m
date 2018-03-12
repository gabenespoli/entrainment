%% en_eeg_preprocess
%   Preprocess EEG data. This script uses EEGLAB functions to preprocess
%   a BioSemi .bdf file:
%
%   1. en_readbdf:       Load raw data
%   2. en_diary.csv:     Remove channels that were manually marked as bad
%   3. averageReference: Average reference controlling for rank
%   4. pop_eegfiltnew:   High-pass filter at 1 Hz
%   5. clean_artifacts:  Automatically find and remove bad channels
%   6. averageReference: Average reference again
%   7. en_epoch:         Extract epochs
%   8. pop_runica:       Run independent components analysis (ICA)
%   9. en_dipfit:        Fit dipoles
%  10. pop_saveset:      Save the EEG .set file to en_getpath('eeg')
%  11. pop_topoplot:     Save IC maps w/dipoles to en_getpath('eeg_plots')
%
% Usage:
%   EEG = en_preprocess_eeg(id)
%   EEG = en_preprocess_eeg(id, stim, task)
%
% Input:
%   id = [numeric] ID of participant to preprocess.
%   stim = ['sync' or 'mir'] Passed to en_epoch.
%   task = ['eeg' or 'tapping'] Passed to en_epoch.
%
% Output:
%   EEG = [struct] EEGLAB structure variable. File is also saved to
%         en_getpath('eeg').

function EEG = en_preprocess_eeg(id, stim, task)

%% defaults
if nargin < 1 || isempty(id),   id = input('Enter id: '); end
if nargin < 2 || isempty(stim), stim = 'sync'; end % sync or mir
if nargin < 3 || isempty(task), task = 'eeg'; end % eeg or tapping
d = en_load('diary', id);

%% load bdf file
EEG = en_readbdf(id); % also adds channel locations

%% remove manually-marked bad channels
if ~isempty(d.rmchans{1}{1})
    rmchans = d.rmchans{1};
    rmchans = alpha2fivepct(rmchans, false);
    EEG = pop_select(EEG, 'nochannel', rmchans);
end

%% preprocess
% EEG = pop_resample(EEG, 128); % downsampling
EEG.data = averageReference(EEG.data);
EEG = pop_eegfiltnew(EEG, 1);
EEG = clean_artifacts(EEG, ...  % find bad channels and remove
    'Highpass',         'off', ...
    'BurstCriterion',   'off', ...
    'WindowCriterion',  'off');
EEG.data = averageReference(EEG.data);
[EEG, portcodes] = en_epoch(EEG, stim, task);
EEG = pop_runica(EEG, 'extended', 1);
EEG = en_dipfit(EEG);

%% save file
EEG.setname = num2str(id);
EEG = pop_saveset(EEG, ...
    'filepath', en_getpath('eeg'), ...
    'filename', [EEG.setname,'.set']);
fid = fopen(fullfile(en_getpath('eeg'), [EEG.setname,'_portcodes.txt']), 'w');
fprintf(fid, '%i\n', portcodes);
fclose(fid);

%% save topoplot of components & dipoles
pop_topoplot(EEG, ...
     0, ...                     % 0 for comps, 1 for chans
     1:size(EEG.icaact, 1), ... % comps/chans to plot
     ['id ', EEG.setname], ...  % plot title
     0, ...                     % rows/cols per page (0 = near square)
     1, ...                     % plot dipoles too
     'electrodes', 'off');

savefig(fullfile(en_getpath('eeg_plots'), [EEG.setname, '_topoplot.fig']))
print(fullfile(en_getpath('eeg_plots'),   [EEG.setname, '_topoplot.png']), '-dpng')
close(gcf)

end
