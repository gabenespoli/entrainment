%EN_PREPROCESS_EEG  Preprocess EEG data. This script uses EEGLAB functions
%   to preprocess a BioSemi .bdf file:
%
%   1. Load raw data (en_readbdf.m)
%   2. Remove channels that were marked as bad in en_log.csv
%   3. Average reference (averageReference.m)
%   4. High-pass filter at 1 Hz
%   5. Automatically find and remove bad channels (clean_artifacts.m)
%   6. Average reference again (averageReference.m)
%   7. Extract epochs (en_epoch.m)
%   8. Run ICA (pop_runica.m)
%   9. Fit dipoles (en_dipfit.m)
%  10. Save the EEG .set file to en_getFolder('eeg')
%  11. Save topoplot (incl. dipoles) to en_getFolder('eeg_plots')
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
%         en_getFolder('eeg').

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
    'filepath', en_getFolder('eeg'), ...
    'filename', [EEG.setname,'_ICA.set']);
fid = fopen(fullfile(en_getFolder('eeg'), [EEG.setname,'_portcodes.txt']), 'w');
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

savefig(fullfile(en_getFolder('eeg_plots'), [EEG.setname, '_ICA_topoplot.fig']))
print(fullfile(en_getFolder('eeg_plots'),   [EEG.setname, '_ICA_topoplot.png']), '-dpng')
close(gcf)

end
