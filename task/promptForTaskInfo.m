function [id, stimType, trigType] = promptForTaskInfo
id = input('Enter participant ID: ', 's');
stimType = '';
trigType = '';
while ~ismember(lower(stimType), {'mir', 'sync'})
    stimType = input('Stimuli [m]ir or [s]ync: ', 's');
    switch lower(stimType)
        case 'm', stimType = 'mir';
        case 's', stimType = 'sync';
    end
end
while ~ismember(lower(trigType), {'eeg', 'tapping'})
    trigType = input('Task [e]eg or [t]apping: ', 's');
    switch lower(trigType)
        case 'e', trigType = 'eeg';
        case 't', trigType = 'tapping';
    end
end
end
