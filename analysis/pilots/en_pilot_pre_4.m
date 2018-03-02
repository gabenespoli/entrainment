function EEG = en_pilot_pre_4
% preprocessing for the tempo pilot
% played sync stim at 90:114 bpm
% see if there is an entrainment advantage for a certain tempo

% addpath('~/local/matlab/eeglab')
% eeglab

%% get filenames and recording info
id = 5;
d = en_log(id);
rawdir  = fullfile('~','local','en','data','raw');
logdir  = fullfile('~','local','en','data','logfiles');
procdir = fullfile('~','local','en','data','preproc');

%% load and merge logfile(s)
for i = 1:2
    logfile = fullfile(logdir, [num2str(id), '_tempo_eeg_',num2str(i),'.csv']);
    tmp = en_loadLogfile(logfile);
    tmp.id = repmat(id, height(tmp), 1);
    tmp.block = ones(height(tmp), 1) * i;
    if i == 1
        LOG = tmp;
    else
        LOG = cat(1, LOG, tmp);
    end
end
LOG = LOG(:, [1 end 4 end-1 6 2:3 5 7:end-2]);

%% load and merge bdf file(s)
file_ids = d.file_ids{1}(1);
eventchans = d.eventchans{1}(1);
for i = 1:length(file_ids)
    bdffile = fullfile(rawdir, [file_ids{i}, '.bdf']);
    TMPEEG = pop_readbdf(bdffile, [], eventchans(i), []);
    if i == 1
        EEG = TMPEEG;
    else
        EEG = pop_mergeset(EEG, TMPEEG);
    end
end
EEG.setname = num2str(id);

%% channel locations
EEG = pop_select(EEG, 'nochannel', 135:136);
EEG = eeg_ABCDto5percent(EEG, false);
EEG = pop_chanedit(EEG, 'changefield', {129 'labels' 'M1'});
EEG = pop_chanedit(EEG, 'changefield', {130 'labels' 'M2'});
EEG = pop_chanedit(EEG, 'changefield', {131 'labels' 'LO1'});
EEG = pop_chanedit(EEG, 'changefield', {132 'labels' 'LO2'});
EEG = pop_chanedit(EEG, 'changefield', {133 'labels' 'IO1'});
EEG = pop_chanedit(EEG, 'changefield', {134 'labels' 'IO2'});
EEG = pop_chanedit(EEG, 'lookup', 'chanlocs/sphere_1005_and_exg_besa_fivepct.sfp');
% chanfile = fullfile('chanlocs', 'sphere_1005_and_exg_besa_fivepct.sfp');
% chanfile = fullfile('~','local','matlab','eeglab','plugins','dipfit2.3','standard_BESA','standard-10-5-cap385.elp');
chanfile = fullfile('~','local','matlab','eeglab','functions','resources','Standard-10-5-Cap385_witheog.elp');
EEG = pop_chanedit(EEG, 'lookup', chanfile);

%% save
EEG = pop_saveset(EEG, 'filename', [EEG.setname,'.set'], 'filepath', procdir);

%% preprocessing
rmchans = eeg_ABCDto5percent(d.rmchans{1}, false);
EEG = pop_select(EEG, 'nochannel', rmchans); % remove bad channels before changing to 5pct
EEG = pop_select(EEG, 'nochannel', {'PPO5h', 'P03'}); % looked to be flatlined
EEG.data = averageReference(EEG.data); % TODO try removing this

%% run two pipelines
% pipeline 1 tmp (get ICA weights, higher HP)
% pipeline 2 EEG
tmp = EEG;

% filtering
tmp = pop_eegfiltnew(tmp, 2);
EEG = pop_eegfiltnew(EEG, 1);

% find bad channels and remove
tmp = clean_artifacts(tmp, 'Highpass','off', 'BurstCriterion','off', 'WindowCriterion','off');
% tmp = clean_artifacts(tmp, 'Highpass', 'off');
EEG = pop_select(EEG, 'channel', find(tmp.etc.clean_channel_mask));

% average reference
tmp.data = averageReference(tmp.data);
EEG.data = averageReference(EEG.data);

% epoching
portcodes = unique(LOG.portcode);
tmp = doEpoching(tmp, portcodes);
EEG = doEpoching(EEG, portcodes);

% ICA
tmp             = pop_runica(tmp, 'extended', 1);
EEG.icaweights  = tmp.icaweights; % import ICA from pipeline 1
EEG.icasphere   = tmp.icasphere;

% save
EEG = pop_saveset(EEG, 'filename', [EEG.setname,'_ICA.set'], 'filepath', procdir);

end

function data = averageReference(data)
% data should be chan x time x epochs
data = bsxfun(@minus, data, sum(data,1) / (size(data,1) + 1));
end

function EEG = doEpoching(EEG, portcodes)
epochlim = [5 26]; % 1 second of silence after portcode, then 4 seconds to start entraining; shortest stim is 25 seconds
EEG = pop_epoch(EEG, portcodes, epochlim, 'newname', EEG.setname); 
end
