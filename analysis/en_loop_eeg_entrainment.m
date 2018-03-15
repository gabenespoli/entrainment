%% en_loop_eeg_entrainment
%   Loop many participants through en_eeg_entrainment.
%
% Usage:
%   en_loop_eeg_entrainment(id, stim, task)
%
% Input:
%   id = [numeric] List of IDs whose data will be loaded from
%       en_getpath('eeg').

function en_loop_eeg_entrainment(ids, stim, task)
if nargin < 1 || isempty(ids)
    d = en_load('diary', 'incl');
    ids = d.id;
end
if nargin < 2 || isempty(stim), stim = 'sync'; end
if nargin < 3 || isempty(task), task = 'eeg'; end

for i = 1:length(ids)
    id = ids(i);

    fprintf('\n')
    fprintf('Calculating neural entrainment for id %i...\n', id)

    en_eeg_entrainment(id, ...
        'stim',     stim, ...
        'trig',     task, ...
        'region',   'pmc');

    en_eeg_entrainment(id, ...
        'stim',     stim, ...
        'trig',     task, ...
        'region',   'aud');

end

end
