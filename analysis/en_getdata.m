% concatenate csv files from many ids as a single table

function T = en_getdata(ids, regions)
if nargin < 1 || isempty(ids)
    d = en_load('diary', 'incl');
    ids = d.id;
end
if nargin < 2 || isempty(regions)
    regions = {'mot', 'pmc', 'pmm', 'aud'};
end
if ~iscell(regions), regions = cellstr(regions); end

for i = 1:length(ids)
    id = ids(i);
    idStr = num2str(id);

    for j = 1:length(regions)
        region = regions{j};
        fname = fullfile(en_getpath('entrainment'), ...
            [idStr, '_', region, '.csv']);
        tmp = readtable(fname);
        if j == 1
            tmp_id = tmp;
        else
            if all(tmp.portcode == tmp_id.portcode)
                tmp_id = [tmp_id, tmp(:, region)]; %#ok<AGROW>
            else
                error(['Portcodes don''t match for id ', num2str(id), '.'])
            end
        end
    end

    if i == 1
        T = tmp_id;
    else
        T = [T; tmp_id]; %#ok<AGROW>
    end

end

% make some fields categorical
T.rhythmType = categorical(T.rhythmType);
T.rhythmType = reordercats(T.rhythmType, {'simple', 'optimal', 'complex'});

end
