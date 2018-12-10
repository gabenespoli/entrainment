%% getpath
%   Get a project directory. This helper function is used throughout these
%   scripts to get filenames and paths for project and data files. Editing
%   the paths in this file will control which files the scripts act on.
%
%   This function depends on getroot.m. See
%   getroot_example.m for instructions.

function outpath = getpath(pathtype)

% make sure project directory is set
if exist('getroot', 'file') ~= 2 % make sure getroot.m exists
    error('Don''t know what the project folder is. See getroot_example.m for instructions.')
end

switch pathtype
    case 'project',     outpath = getroot;

    % analysis scripts paths
    case 'analysis',    outpath = fullfile(getpath('project'), 'analysis');
    case 'diary',       outpath = fullfile(getpath('analysis'), 'en_diary.csv');
    case 'stiminfo',    outpath = fullfile(getpath('analysis'), 'en_stiminfo.csv');
    case 'proclog',     outpath = fullfile(getpath('analysis'), 'en_log.csv');

    % data folder
    case 'data',        outpath = fullfile(getpath('project'), 'data');
    case 'plots',       outpath = fullfile(getpath('project'), 'plots');

    % tapping data
    case 'tapping',     outpath = fullfile(getpath('data'), 'tap_preprocessed');
    case 'taptrainment',outpath = fullfile(getpath('data'), 'tap_entrainment');
    case 'midi',        outpath = fullfile(getpath('data'), 'midi');

    % eeg data
    case 'logfiles',    outpath = fullfile(getpath('data'), 'logfiles');
    case 'bdf',         outpath = fullfile(getpath('data'), 'bdf');
    case 'eeg',         outpath = fullfile(getpath('data'), 'eeg_preprocessed');
    case 'eegbl',       outpath = fullfile(getpath('data'), 'eeg_baseline');
    case 'topoplots',   outpath = fullfile(getpath('data'), 'eeg_topoplots');
    case 'goodcomps',   outpath = fullfile(getpath('data'), 'eeg_goodcomps');
    case 'entrainment', outpath = fullfile(getpath('data'), 'eeg_entrainment');

    % toolboxes
    case 'miditoolbox', outpath = fullfile(getpath('project'), 'miditoolbox1.1', 'miditoolbox');
    case 'eeglab',      outpath = fullfile(getpath('project'), 'eeglab');
    case 'dipfit',      outpath = fullfile(getpath('eeglab'), 'plugins', 'dipfit2.3');
    case 'chanfile',    outpath = fullfile(getpath('eeglab'), 'functions', 'resources', 'Standard-10-5-Cap385_witheog.elp');
    case 'mrifile',     outpath = fullfile(getpath('dipfit'), 'standard_BEM', 'standard_mri.mat');
    case 'hdmfile',     outpath = fullfile(getpath('dipfit'), 'standard_BEM', 'standard_vol.mat');

end
end
