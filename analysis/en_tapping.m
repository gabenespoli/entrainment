function en_tapping(ids, numMarkersPrompt)
% Function for looping files and doing tapping preprocessing and entrainment analysis
%
%   numMarkersPrompt: 0 to cancel, 1 to prompt, 2 to continue, default 0
%       This is mainly used for debugging. This is what to do if the
%       wrong number of audio markers are found. 0 cancels and doesn't do
%       the epoching, 2 will continue with the epoching anyway, and 1
%       will pause execution and prompt for what to do. See the 
%       findAudioMarkers.m function for more detail.

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
