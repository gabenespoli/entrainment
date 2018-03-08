function EEG = en_preprocess_eeg(id) 
% reads file id.set from en_getFolder('eeg')
% file must already have been loaded using en_readbdf.m
% id = [numeric]
stimType = 'sync'; % sync or mir
taskType = 'eeg'; % eeg or tapping

% load some things
bdflog = en_load('bdflog', id);
EEG = en_load('eeg', id);

% remove manually-marked bad channels
if ~isempty(bdflog.rmchans{1})
    rmchans = regexp(bdflog.rmchans{1}, ',', 'split'); % convert comma-delimited list to cell array
    rmchans = en_alpha2fivepct(rmchans, false);
    EEG = pop_select(EEG, 'nochannel', rmchans);
end

% downsampling
% setname = EEG.setname;
% EEG = pop_resample(EEG, 128);
% EEG.setname = setname;

%% run two pipelines
% pipeline 1 TMP (get ICA weights, higher HP)
% pipeline 2 EEG

% average reference
EEG.data = en_averageReference(EEG.data);
TMP = EEG;

% filtering
TMP = pop_eegfiltnew(TMP, 1);
EEG = pop_eegfiltnew(EEG, 0.5);

% find bad channels and remove
TMP = clean_artifacts(TMP, ...
    'Highpass',         'off', ...
    'BurstCriterion',   'off', ...
    'WindowCriterion',  'off');
EEG = pop_select(EEG, 'channel', find(TMP.etc.clean_channel_mask));

% average reference
TMP.data = en_averageReference(TMP.data);
EEG.data = en_averageReference(EEG.data);

% epoching
[EEG, portcodes] = en_epoch(EEG, stimType, taskType);
TMP = en_epoch(TMP, stimType, taskType);

% ICA
TMP             = pop_runica(TMP, 'extended', 1);
EEG.icaweights  = TMP.icaweights; % import ICA from pipeline 1
EEG.icasphere   = TMP.icasphere;

% save
EEG = pop_saveset(EEG, 'filepath', en_getFolder('eeg'), ...
                       'filename', [EEG.setname,'_ICA.set']);
fid = fopen(fullfile(en_getFolder('eeg'), [EEG.setname,'_portcodes.txt']), 'w');
fprintf(fid, '%i\n', portcodes);
fclose(fid);

% fit dipoles
EEG = en_dipfit(EEG);

% save topoplot of components & dipoles
pop_topoplot(EEG, ...
             0, ...                     % 0 for comps, 1 for chans
             1:size(EEG.icaact, 1), ... % comps/chans to plot
             EEG.setname, ...           % plot title
             0, ...                     % rows/cols per page (0 = near square)
             1, ...                     % plot dipoles too
             'electrodes', 'off');

savefig(fullfile(en_getFolder('eeg_plots'), [EEG.setname, '_ICA_topoplot.fig']))
print(fullfile(en_getFolder('eeg_plots'), [EEG.setname, '_ICA_topoplot.png']), '-dpng')
close(gcf)

end
