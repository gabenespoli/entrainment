function continuePrevious = checkIfLogfileExists(logfile, trialListFile, currentTime)
if exist(logfile, 'file')

    % prompt for whether to continue previous file
    fprintf('\nLogfile ''%s'' already exists.\n', logfile)

    % TODO check to see if the existing logfile has already been completed?
    goodResp = false;
    while ~goodResp

        resp = input('Start [n]ew logfile, [c]ontinue previous, or [q]uit? ', 's');
        switch lower(resp)
            case 'n'
                continuePrevious = false;
                addTimestampToFile(logfile, currentTime)
                addTimestampToFile(trialListFile, currentTime)
                goodResp = true;
                
            case 'c'
                continuePrevious = true;
                goodResp = true;
                
            case 'q'
                return
        end
    end

else
    continuePrevious = false;
end
end

function addTimestampToFile(fname,timestamp)
[pathstr,name,ext] = fileparts(fname);
newname = fullfile(pathstr, [name, '_', timestamp, ext]);
movefile(fname, newname);
end
