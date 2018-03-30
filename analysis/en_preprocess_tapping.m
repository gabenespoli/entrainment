function TAP = en_tap_preprocess(id, stim)

if nargin < 2
    stim = 'sync';
end

L = en_load('logstim', id);
L = L(L.stim==stim & L.task=='tapping', :);

M = en_load('midi', id);
M = M(M.stim==stim, :);
M(:, 'stim') = [];

TAP = join(L, M, 'Keys', 'trial');

filename = fullfile(en_getpath('tapping'), stim, [num2str(id), '.mat']);
save(filename, 'TAP')

end
