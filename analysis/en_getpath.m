%% en_getpath
%   Get a project directory. This helper function is used throughout these
%   scripts to get filenames and paths for project and data files. Editing
%   the paths in this file will control which files the scripts act on.

function outpath = en_getpath(pathtype)

switch pathtype
    case 'project',     outpath = fullfile('~','local','en');

    % analysis scripts paths
    case 'analysis',    outpath = fullfile(en_getpath('project'), 'analysis');
    case 'diary',       outpath = fullfile(en_getpath('analysis'), 'en_diary.csv');
    case 'stiminfo',    outpath = fullfile(en_getpath('analysis'), 'en_stiminfo.csv');

    % data file paths
    case 'data',        outpath = fullfile(en_getpath('project'), 'data');
    case 'logfiles',    outpath = fullfile(en_getpath('data'), 'logfiles');
    case 'bdf',         outpath = fullfile(en_getpath('data'), 'bdf');
    case 'eeg',         outpath = fullfile(en_getpath('data'), 'eeg');
    case 'topoplots',   outpath = fullfile(en_getpath('data'), 'eeg_topoplots');
    case 'pmccomps',    outpath = fullfile(en_getpath('data'), 'eeg_comps_pmc');
    case 'audcomps',    outpath = fullfile(en_getpath('data'), 'eeg_comps_aud');
    case 'entrainment', outpath = fullfile(en_getpath('data'), 'eeg_entrainment');

    % paths from the EEGLAB toolbox
    case 'eeglab',      outpath = fullfile(en_getpath('project'), 'eeglab');
    case 'dipfit',      outpath = fullfile(en_getpath('eeglab'), 'plugins', 'dipfit2.3');
    case 'chanfile',    outpath = fullfile(en_getpath('eeglab'), 'functions', 'resources', 'Standard-10-5-Cap385_witheog.elp');
    case 'mrifile',     outpath = fullfile(en_getpath('dipfit'), 'standard_BEM', 'standard_mri.mat');
    case 'hdmfile',     outpath = fullfile(en_getpath('dipfit'), 'standard_BEM', 'standard_vol.mat');

end
end
