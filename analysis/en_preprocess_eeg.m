%% en_preprocess_eeg
%   Preprocess EEG data. This script uses EEGLAB functions to preprocess
%   a BioSemi .bdf file:
%
%   1. en_readbdf:       Load raw data
%   2. en_diary.csv:     Remove channels that were manually marked as bad
%   3. averageReference: Average reference controlling for rank
%   4. pop_eegfiltnew:   High-pass filter at 1 Hz for ICA, 0.5 Hz for EEG
%   5. clean_artifacts:  Automatically find and remove bad channels
%   6. en_epoch:         Extract epochs
%   7. averageReference: Average reference again
%   8. pop_runica:       Run independent components analysis (ICA) on 1 Hz,
%                        HP data, import weights into 0.5 Hz HP data.
%   9. en_dipfit:        Fit dipoles
%  10. pop_saveset:      Save the EEG .set file to getpath('eeg')
%  11. pop_topoplot:     Save IC maps w/dipoles to getpath('topoplots')
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
%         getpath('eeg').

function EEG = en_preprocess_eeg(id, stim, task)

%% defaults
if nargin < 1 || isempty(id),   id = input('Enter id: '); end
if nargin < 2 || isempty(stim), stim = 'sync'; end % sync or mir
if nargin < 3 || isempty(task), task = 'eeg'; end % eeg or tapping
d = en_load('diary', id);

%% load bdf file
EEG = en_readbdf(id); % also adds channel locations

%% remove manually-marked bad channels
if ~isempty(d.badchans{1}{1})
    badchans = d.badchans{1};
    badchans = alpha2fivepct(badchans, false);
    EEG = pop_select(EEG, 'nochannel', badchans);
end

%% preprocess
% pipeline 1: ICA, higher HP filter, do ICA
% pipeline 2: EEG, import ICA weights from pipeline 1
% EEG = pop_resample(EEG, 128); % downsampling
EEG.data = averageReference(EEG.data);

% filter
ICA = pop_eegfiltnew(EEG, 1); % higher HP for better ICA
EEG = pop_eegfiltnew(EEG, 0.5); % slowest beat is 1.5, group by 2 = 0.75

% remove bad channels from ICA, remove those same channels from EEG
ICA = clean_artifacts(ICA, ...
    'Highpass',         'off', ...
    'BurstCriterion',   'off', ...
    'WindowCriterion',  'off');
EEG = pop_select(EEG, 'channel', find(ICA.etc.clean_channel_mask));

% extract epochs
ICA = en_epoch(ICA, stim, task);
EEG = en_epoch(EEG, stim, task);

% average reference before ICA
ICA.data = averageReference(ICA.data);
EEG.data = averageReference(EEG.data);

% run ICA on ICA, import weights into EEG
ICA = pop_runica(ICA, 'extended', 1);
EEG.icaweights = ICA.icaweights;
EEG.icasphere = ICA.icasphere;

% fit dipoles
EEG = en_dipfit(EEG, ...
    1:size(EEG.icaact, 1), ...  % channels to fit
    40);                        % residual variance threshold


%% save file
EEG.setname = num2str(id);
EEG = pop_saveset(EEG, ...
    'filepath', fullfile(getpath('eeg'), [stim, '_', task]), ...
    'filename', [EEG.setname,'.set']);

%% save topoplot of components & dipoles
pop_topoplot(EEG, ...
     0, ...                     % 0 for comps, 1 for chans
     1:size(EEG.icaact, 1), ... % comps/chans to plot
     ['id ', EEG.setname], ...  % plot title
     0, ...                     % rows/cols per page (0 = near square)
     0, ...                     % 1 to plot dipoles too
     'electrodes', 'off');

set(gcf, 'color', [1 1 1] * 0.5) % make background grey instead of white

savefig(fullfile(getpath('topoplots'), [stim, '_', task], [EEG.setname, '_topoplot.fig']))
print(  fullfile(getpath('topoplots'), [stim, '_', task], [EEG.setname, '_topoplot.png']), '-dpng')
close(gcf)

end
