function new_project(rootdir)

folderNames = {'eeg_bdf','eeg_pre','eeg_table','eeg_topoplots','logfiles',...
    'tap_midi','tap_wav','tap_pre','tap_table'};

for i = 1:size(folderNames,2)
    mkdir(fullfile(rootdir,folderNames{i}));

end

if isempty(dir(fullfile(rootdir,'eeglab*')))
    fprintf('Please place the eeglab toolbox folder in the %s\n',rootdir)
    
end

if ~isempty(dir(fullfile(rootdir,'miditoolbox*')))
    fprintf('Please place the midi toolbox folder in the %s\n',rootdir)
end
