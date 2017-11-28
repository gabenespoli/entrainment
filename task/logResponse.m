function logResponse(logfile_fid, id, stimType, trigType, trial, fname, ...
                     move, pleasure)
[pathstr, name, ext] = fileparts(fname);
name = [name, ext];
timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
data = {id, stimType, trigType, trial, name, ...
        move, pleasure, pathstr, timestamp};
formatSpec = '%s,%s,%s,%i,%s,%i,%i,%s,%s\n';
fprintf(logfile_fid, formatSpec, data{:});
end
