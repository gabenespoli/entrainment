function EEG = en_readbdf(id, do_save)
if nargin < 2, do_save = true; end
bdflog = en_load('bdflog', id);

% load the bdf file
bdffile = fullfile(en_getFolder('bdf'), [bdflog.bdffile{1}, '.bdf']);
range = [];
eventchans = bdflog.eventchans; % event channel, usually last channel in bdf file
ref = [];
EEG = pop_readbdf(bdffile, range, eventchans, ref);
EEG.setname = idStr;

% add channel locations
EEG = pop_select(EEG, 'nochannel', 135:136); % remove EXG7 and EXG8
EEG = en_alpha2fivepct(EEG, false); % convert to 5% system; also relabels EXG channels
chanfile = fullfile(en_getFolder('eeglab'), 'function', 'resources', 'Standard-10-5-Cap385_witheog.elp');
EEG = pop_chanedit(EEG, 'lookup', chanfile);

% save .set file
if do_save
    EEG = pop_saveset(EEG, ...
        'filename', [idStr,'.set'], ...
        'filepath', en_getFolder('eeg'));
end

end
