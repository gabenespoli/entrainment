function en_tapping(ids)
if nargin < 1 || isempty(ids)
    d = en_load('diary', 'incl');
    ids = d.id;
end

stims = {'sync', 'mir'};
matchwarn = false;

for i = 1:length(ids)
    id = ids(i);
    for j = 1:length(stims)
        stim = stims{j};
        en_preprocess_tapping(id, stim);
        en_entrainment_tapping(id, stim, [], matchwarn);
    end
end
end
