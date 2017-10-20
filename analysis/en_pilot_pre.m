function EEG = em_pilot_pre

% filenames and set paths
fname = '20171009A';
bdffile = ['~/local/data/phd/raw/',fname,'.bdf'];
procfolder = '~/local/data/phd/proc';
chanlocsfile = 'biosemi128.elp';
addpath('~/bin/matlab/eeglab13_5_4b')
eeglab

% load raw data
EEG = pop_readbdf(bdffile, [], 272, []);
EEG = pop_select(EEG, 'nochannel', 131:size(EEG.data, 1));
EEG = pop_chanedit(EEG, 'changefield', {129 'labels' 'M1'});
EEG = pop_chanedit(EEG, 'changefield', {130 'labels' 'M2'});
EEG = pop_chanedit(EEG, 'lookup', chanlocsfile);
EEG = pop_select(EEG, 'nochannel', {'A10', 'D12'}); % remove bad channels
EEG.data = bsxfun(@minus,EEG.data,sum(EEG.data,1) / (EEG.nbchan + 1)); % avg ref
EEG = pop_saveset(EEG, 'filename',[fname,'.set'], 'filepath',procfolder);

% pipeline 1
tmp = EEG;
tmp = pop_eegfiltnew(tmp,1);
% find bad channels and remove
% tmp = clean_artifacts(tmp, 'Highpass','off', 'BurstCriterion','off', 'WindowCriterion','off');    
tmp.data = bsxfun(@minus,tmp.data,sum(tmp.data,1) / (tmp.nbchan + 1)); % proc2
% tmp = pop_cleanline(tmp,'LineFrequencies',[60 120],'PlotFigures',false); close all;
tmp = pop_epoch(tmp, {'266'}, [4 30]); 
tmp = pop_runica(tmp, 'extended', 1);
EEG = pop_saveset(EEG, 'filename',[fname,'_ICAweights.set'], 'filepath',procfolder);

% pipeline 2
EEG = pop_eegfiltnew(EEG, 0.1);
% EEG = pop_select(EEG, 'channel', find(tmp.etc.clean_channel_mask));
EEG.data = bsxfun(@minus,EEG.data,sum(EEG.data,1) / (EEG.nbchan + 1));
EEG = pop_epoch(EEG, {'266'}, [4 30], 'newname', [fname,'_pre']);
EEG.icaweights = tmp.icaweights;
EEG.icasphere = tmp.icasphere;

EEG = pop_saveset(EEG, 'filename',[fname,'_ICA.set'], 'filepath',procfolder);

end
