function varargout = phd_pre(id,do_stop)
if nargin < 2, do_stop = false; end
eeglab nogui

% defaults
rawFolder = '~/local/data/raw';
procFolder = '~/local/data/proc';
trim = 1; % in seconds
% ref = []; % channel inds, [] for avg, 'none' for no rereferencing, 'avg' for 
ref = 'avg'; % proc 2 = 'avg'; proc1 = [];

d = gv_recordinginfo; % load excel file with recording info

for i = 1:length(id)
    
    ind = d.id == id(i);
    
    % get filename
    filename = [d.filename{ind},'.bdf'];
    
    % get exceptions
    if ~isnan(d.rmChans{ind})
        rmchans = regexp(d.rmChans{ind},' ','split');
    else                       
        rmchans = {'EXG7' 'EXG8'};
    end
    
    % basic (load bdf, rename chans, add chan locs)
    EEG = gv_readbdf(filename,...
        'raw',rawFolder,...
        'rmchans',rmchans,... % remove unused chans
        'trim',trim,...       % trim beginning and end of recording
        'ref',ref);           % rereference
    
    if do_stop, varargout{i} = EEG; continue, end
    
    % Pipeline for bad chans & ICA weights
    % ------------------------------------
    % 1. 1 Hz HP (for ICA; Winkler, Debener, Müller, & Tangermann, 2015)
    % 2. remove bad channels (use ASR to find them)
    % 3. reref to average
    % 4. remove line noise
    % 5. epoch (remove parts where they're responding on keyboard)
    % 6. ICA
    tmp = EEG;
    tmp = pop_eegfiltnew(tmp,1);

    tmp = clean_artifacts(tmp,... % find bad channels and remove
        'Highpass','off',...
        'BurstCriterion','off',...
        'WindowCriterion','off');    
%     tmp = clean_rawdata(tmp,... % find bad channels and remove
%         [],...    % max tolerated flatline on any channel (in s) (5)
%         'off',... % transition band for high-pass filter ([0.25 0.75])
%         [],...    % min channel correlation to be considered normal (0.8)
%         [],...    % max line noise to be considered normal (4 stdev)
%         'off',... % min variance before repairing bursts w/ASR (5 stdev)
%         'off');   % max proportion of repaired channels tolerated to keep a given window (0.3)

    % ********** DIFFERENCE BETWEEN PROC1 AND PROC2 **********
    % tmp = pop_reref(tmp,[]); % proc1
    tmp.data = bsxfun(@minus,tmp.data,sum(tmp.data,1) / (tmp.nbchan + 1)); % proc2
    % ********** DIFFERENCE BETWEEN PROC1 AND PROC2 **********

    % BioSemi data must be referenced for cleanline
    tmp = pop_cleanline(tmp,'LineFrequencies',[60 120],'PlotFigures',false); close all;
    tmp = pop_epoch(tmp,regexp(num2str(101:130),'  ','split'),[0 30]); 
    tmp = pop_runica(tmp,'extended',1);
    
    % Pipeline for actual data
    % ------------------------
    % 1. 0.1 Hz HP (want to access freqs below 1 Hz)
    % 2. remove bad channels (as found in above pipeline)
    % 3. reref to average
    % 4. epoch
    % 5. import ICA weights (as found in above pipeline)
    % 6. fit dipoles
    EEG = pop_eegfiltnew(EEG,0.1);
    EEG = pop_select(EEG,'channel',find(tmp.etc.clean_channel_mask));
    
    % ********** DIFFERENCE BETWEEN PROC1 AND PROC2 **********
    % EEG = pop_reref(EEG,[]); % proc1
    EEG.data = bsxfun(@minus,EEG.data,sum(EEG.data,1) / (EEG.nbchan + 1)); % proc2
    % ********** DIFFERENCE BETWEEN PROC1 AND PROC2 **********

    EEG = pop_epoch(EEG,regexp(num2str(101:130),'  ','split'),[0 30],'newname',EEG.setname);
    EEG.icaweights = tmp.icaweights;
    EEG.icasphere = tmp.icasphere;
    %     EEG = eg_dip(EEG,'coarse');
    
    % add participant responses
    try
        EEG.etc.resp = gv_resp(id(i));
        err = '';
    catch
        err = ['Couldn''t get participant responses for id ',num2str(id(i)),'.'];
    end
    
%     EEG2 = saveset(EEG,'folder',procFolder,'suffix','-HP0.1-rmASRchansHP1-avgRef-epochs-ICA_HP1');
    
    EEG.setname = [EEG.setname,'-HP0.1-rmASRchansHP1-avgRef_rank+1-epochs-ICA_HP1'];
    EEG = pop_saveset(EEG,'filename',[num2str(id(i)),'-proc2.set'],'filepath',procFolder);
    
    varargout{i} = EEG;
    disp(err)
end
end
