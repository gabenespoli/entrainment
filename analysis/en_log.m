function [d,T] = en_log(ids)
if nargin < 1, ids = []; end

fname = fullfile('~','projects','archive','2017','en','en_log.csv');
T = readtable(fname, 'Delimiter', ',');

d               = table(T.id, 'VariableNames', {'id'});
d.file_ids      = convertToCells(T.file_ids);
d.order         = T.order;
d.rmchans       = convertToCells(T.rmchans);
d.experimenters = T.experimenters;

% restrict to specified ids
if ~isempty(ids)
    d = d(ismember(d.id, ids),:);
end

end

function C = convertToCells(T, suffix, delim)
% convert delimiter-separated lists into cells so we can loop through them
if nargin < 2, suffix = ''; end
if nargin < 3, delim = ','; end
C = cellfun(@(x) strtrim(regexp(x, delim, 'split')), cellstr(T), 'UniformOutput', false);
if ~isempty(suffix)
    for i = 1:length(C)
        C{i} = cellfun(@(x) strtrim(cat(2, x, suffix)), C{i}, 'UniformOutput', false);
    end
end
end
