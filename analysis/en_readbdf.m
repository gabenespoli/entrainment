function EEG = en_readbdf(id)
% en_readbdf  Load a bdf file in EEGLAB and add channel locations.
% Loads en_diary.csv and uses id to get bdf filename and event channel.

% get diary info for this id
d = en_load('diary', id);
bdffiles = d.bdffile{1};
eventchans = d.eventchans;

% read 1 bdf file, or read multiple and merge
ind = 1;
while ind <= length(bdffiles)
    bdffile = fullfile(en_getpath('bdf'), [bdffiles{ind}, '.bdf']);
    TMP = pop_readbdf( ...
        bdffile, ...        % filename
        [], ...             % range
        eventchans, ...     % event channel
        []);                % reference

    if ind == 1
        EEG = TMP;
    else
        EEG = pop_mergeset(EEG, TMP);
    end

    ind = ind + 1;
end

% make setname the id as a string
EEG.setname = num2str(id);

% add channel locations
EEG = pop_select(EEG, 'nochannel', 135:136); % remove EXG7 and EXG8
EEG = alpha2fivepct(EEG, false); % relabel as 5% (1005) system
EEG = pop_chanedit(EEG, 'lookup', en_getpath('chanfile')); % chan locs

end
