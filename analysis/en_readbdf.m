%% en_readbdf
%   Load bdf files into EEGLAB and add channel locations. 
%
% Usage:
%   EEG = en_readbdf(id)
%
% Input:
%   id = [numeric] ID number of participant as indicated in 
%       en_getpath('diary'). All bdf files associated with this id will
%       be loaded and merged.
%   
% Output:
%   EEG = [struct] EEGLAB structure with 1005 electrode labels and
%       channel locations from en_getpath('chanfile').

function EEG = en_readbdf(id)

% get diary info for this id
d = en_load('diary', id);
bdffiles = d.bdffile{1};
eventchans = d.eventchans;

% load .bdf files into EEGLAB .set files
% merge all .bdf files for this id if there are multiple
for i = length(bdffiles)
    bdffile = fullfile(en_getpath('bdf'), [bdffiles{i}, '.bdf']);
    TMP = pop_readbdf( ...
        bdffile, ...        % filename
        [], ...             % range
        eventchans, ...     % event channel
        []);                % reference

    if i == 1
        EEG = TMP;
    else
        EEG = pop_mergeset(EEG, TMP);
    end

end

% make setname the id as a string
EEG.setname = num2str(id);

% add channel locations
EEG = pop_select(EEG, 'nochannel', 135:136); % remove EXG7 and EXG8
EEG = alpha2fivepct(EEG, false); % relabel as 5% (1005) system
EEG = pop_chanedit(EEG, 'lookup', en_getpath('chanfile')); % chan locs

end
