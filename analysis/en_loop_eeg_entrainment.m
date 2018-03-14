%% en_loop_eeg_entrainment
%   Loop many participants through en_eeg_entrainment.
%
% Usage:
%   en_loop_eeg_entrainment(id, stim, task)
%
% Input:
%   id = [numeric] List of IDs whose data will be loaded from
%       en_getpath('eeg').

function en_loop_eeg_entrainment(id, stim, task)
if nargin < 2 || isempty(stim), stim = 'sync'; end
if nargin < 3 || isempty(task), task = 'eeg'; end

for i = 1:length(id)

    fprintf('\n')
    fprintf('Calculating neural entrainment for id %i...\n', id(i))

    en_eeg_entrainment(id(i), ...
        'stim',     stim, ...
        'trig',     task, ...
        'region',   'pmc');

    en_eeg_entrainment(id(i), ...
        'stim',     stim, ...
        'trig',     task, ...
        'region',   'aud');

end

end
