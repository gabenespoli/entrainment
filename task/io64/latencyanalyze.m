function [diffs,latency,type] = latencyanalyze(event)

% event is from EEG.event; it should have event.latency and event.type
latency = [event.latency];
type = [event.type];
if length(latency) ~= length(type)
    error('latency and type should be the same length')
end

% loop through types and get indicies of codes in ascending order
% (the codes that were sent were 0 to 255, but there were a bunch of spurious ones)
ind = false(1,length(type));
counter = 1; % (for some reason the first 0 wasn't sent...)
for i = 1:length(ind)
    if type(i) == counter
        ind(i) = true;
        counter = counter + 1;
    end
end

type = type(ind);
latency = latency(ind);
diffs = diff(latency);

end
