function en_eeg_loop(id)

d = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
tstart = tic;
tid = cell(1, length(id));

for i = 1:length(id)

    % prepare for id id
    diary(fullfile(en_getFolder('looplogs'), [d, '_id-', num2str(id(i)), '.txt']))
    fprintf('Participant ID: %i\n', id(i))
    fprintf('Loop started: %s\n', d)
    fprintf('This ID started: %s\n', datestr(now, 'yyyy-mm-dd_HH-MM-SS'));
    tstart_id = toc;

    try
        en_preprocess_eeg(id(i), 'sync', 'eeg');

    catch err
        tid{i} = ['Error: ' getReport(err), '\n']; % save error message too
        fprintf('%s\n', getReport(err)); % print error in command window

    end

    % save and print the elapsed time for this id
    tend_id = toc;
    ttime_id = (tend_id - tstart_id) / 60; % in minutes
    tid{i} = [tid{i}, num2str(ttime_id), ' minutes'];
    fprintf('%s\n', tid{i})
    diary off
end

% save summary of elapsed time for all ids
fname = fullfile(en_getFolder('looplogs'), [d, '.txt']);
fid = fopen(fname, 'w');
fprintf(fid, 'Loop summary\n');
for i = 1:length(id)
    fprintf('%i: %s\n', id(i), tid{i});
end
fprintf('Total time: %g hours\n', (toc - tstart) / 60 / 60);
fclose(fid);

end
