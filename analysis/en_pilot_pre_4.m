function EEG = en_pilot_pre_4
% preprocessing for the tempo pilot
% played sync stim at 90:114 bpm
% see if there is an entrainment advantage for a certain tempo

% addpath('~/bin/matlab/eeglab13_5_4b')
% eeglab

%% get filenames and recording info
id = 4;
d = en_log(id);
rawdir  = fullfile('~','local','en','data','raw');
procdir = fullfile('~','local','en','data','preproc');

%% load and merge bdf files
file_ids = d.file_ids{1}(2);
eventchans = d.eventchans{1}(2);
for i = 1:length(file_ids)
    bdffile = fullfile(rawdir, [file_ids{i}, '.bdf']);
    logfile = fullfile(rawdir, [file_ids{i}, '_tempo_eeg.csv']);
    TMPEEG = pop_readbdf(bdffile, [], eventchans(i), []);
    TMPLOG = en_loadLogfile(logfile);
    TMPLOG.id = repmat(id, height(TMPLOG), 1);
    TMPLOG.block = ones(height(TMPLOG), 1) * i;
    if i == 1
        EEG = TMPEEG;
        LOG = TMPLOG;
    else
        EEG = pop_mergeset(EEG, TMPEEG);
        LOG = cat(1, LOG, TMPLOG);
    end
end
LOG = LOG(:, [1 end 4 end-1 6 2:3 5 7:end-2]);
EEG.setname = num2str(id);

%% channel locations
EEG = eeg_ABCDto5percent(EEG, false);
EEG = pop_chanedit(EEG, 'changefield', {129 'labels' 'M1'});
EEG = pop_chanedit(EEG, 'changefield', {130 'labels' 'M2'});
EEG = pop_chanedit(EEG, 'changefield', {131 'labels' 'LO1'});
EEG = pop_chanedit(EEG, 'changefield', {132 'labels' 'LO2'});
EEG = pop_chanedit(EEG, 'changefield', {133 'labels' 'IO1'});
EEG = pop_chanedit(EEG, 'changefield', {134 'labels' 'IO2'});
EEG = pop_select(EEG, 'nochannel', 135:136);
EEG = pop_chanedit(EEG, 'lookup', 'chanlocs/sphere_1005_and_exg_besa.sfp');

%% save
EEG = pop_saveset(EEG, 'filename', [setname,'.set'], 'filepath', procdir);

%% load raw data
logA = en_loadLogfile(logA);
logB = en_loadLogfile(logB);
L = [logA; logB];
portcodes = unique(L.portcode);
I = readtable(infofile);
rmchans = unique(I.rmchans(I.id==3 | I.id==4));

EEGA = pop_readbdf(bdffileA, [], 272, []);
EEGB = pop_readbdf(bdffileB, [], 272, []);
EEG = pop_mergeset(EEGA, EEGB);
EEG.setname = setname;

EEG = pop_chanedit(EEG, 'changefield', {257 'labels' 'M1'});
EEG = pop_chanedit(EEG, 'changefield', {258 'labels' 'M2'});
EEG = pop_chanedit(EEG, 'changefield', {259 'labels' 'LO1'});
EEG = pop_chanedit(EEG, 'changefield', {260 'labels' 'LO2'});
EEG = pop_chanedit(EEG, 'changefield', {261 'labels' 'IO1'});
EEG = pop_chanedit(EEG, 'changefield', {262 'labels' 'IO2'});
EEG = pop_select(EEG, 'nochannel', 263:271);
EEG = pop_select(EEG, 'nochannel', 129:256);
% remove spurious portcodes (this was done manually, eegh code copied below)
EEG = pop_editeventvals(EEG,...
                        'delete',1,'delete',1,'delete',3,'delete',5,...
                        'delete',6,'delete',9,'delete',10,'delete',11,...
                        'delete',14,'delete',16,'delete',17,'delete',18,...
                        'delete',20,'delete',21,'delete',21,'delete',23,...
                        'delete',24,'delete',27,'delete',31,'delete',33,...
                        'delete',36,'delete',37,'delete',38,'delete',39,...
                        'delete',40,'delete',42,'delete',43,'delete',44,...
                        'delete',46,'delete',47,'delete',49,'delete',50);
EEG = pop_chanedit(EEG, 'lookup', chanlocsfile);
EEG = pop_select(EEG, 'nochannel', rmchans); % remove bad channels
EEG.data = bsxfun(@minus, EEG.data, sum(EEG.data,1) / (EEG.nbchan + 1)); % avg ref
EEG = pop_saveset(EEG, 'filename',[setname,'.set'], 'filepath',procfolder);

%% pipeline 1
tmp = EEG;
tmp = pop_eegfiltnew(tmp,1);
% find bad channels and remove
tmp = clean_artifacts(tmp, 'Highpass','off', 'BurstCriterion','off', 'WindowCriterion','off');    
% tmp = clean_rawdata(tmp,... % find bad channels and remove
%     [],...    % max tolerated flatline on any channel (in s) (5)
%     'off',... % transition band for high-pass filter ([0.25 0.75])
%     [],...    % min channel correlation to be considered normal (0.8)
%     [],...    % max line noise to be considered normal (4 stdev)
%     'off',... % min variance before repairing bursts w/ASR (5 stdev)
%     'off');   % max proportion of repaired channels tolerated to keep a given window (0.3)
tmp.data = bsxfun(@minus, tmp.data, sum(tmp.data,1) / (tmp.nbchan + 1));
% tmp = pop_cleanline(tmp,'LineFrequencies',[60 120],'PlotFigures',false); close all;
tmp = pop_epoch(tmp, portcodes, epochlim); 
tmp = pop_runica(tmp, 'extended', 1);
EEG = pop_saveset(EEG, 'filename',[setname,'_ICAweights.set'], 'filepath',procfolder);

%% pipeline 2
EEG = pop_eegfiltnew(EEG, 0.1);
EEG = pop_select(EEG, 'channel', find(tmp.etc.clean_channel_mask));
EEG.data = bsxfun(@minus, EEG.data, sum(EEG.data,1) / (EEG.nbchan + 1));
EEG = pop_epoch(EEG, portcodes, epochlim);
EEG.icaweights = tmp.icaweights;
EEG.icasphere = tmp.icasphere;
EEG = pop_saveset(EEG, 'filename',[setname,'_ICA.set'], 'filepath',procfolder);

% TODO: upload to server

end
