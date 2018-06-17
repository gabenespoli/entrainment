function en_tapping(ids, numMarkersPrompt)
%   numMarkersPrompt: 0 to cancel, 1 to prompt, 2 to continue, default 0
if nargin < 1 || isempty(ids)
    d = en_load('diary', 'incl');
    ids = d.id;
end
if nargin < 2 || isempty(numMarkersPrompt)
    numMarkersPrompt = 0;
end

stims = {'sync', 'mir'};
matchwarn = false;

for i = 1:length(ids)
    id = ids(i);
    for j = 1:length(stims)
        stim = stims{j};
        en_preprocess_tapping(id, stim, [], numMarkersPrompt);
        en_entrainment_tapping(id, stim, [], matchwarn);
    end
end
end
