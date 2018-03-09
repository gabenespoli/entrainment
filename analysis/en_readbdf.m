function EEG = en_readbdf(id)

% get diary for this id
d = en_load('diary', id);
bdffiles = d.bdffile{1};
eventchans = d.eventchans;

% read 1 bdf file, or read multiple and merge
ind = 1;
while ind < length(bdffiles)
    bdffile = fullfile(en_getFolder('bdf'), [bdffiles{ind}, '.bdf']);
    TMP = pop_readbdf( ...
        bdffile, ...        % filename
        [], ...             % range
        eventchans, ...   % event channel
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
EEG = pop_chanedit(EEG, 'lookup', en_getFolder('chanfile')); % chan locs

end
