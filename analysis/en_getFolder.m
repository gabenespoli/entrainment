function outdir = en_getFolder(dirtype)
%en_getFolder  Get a project directory. This helper function is used
%   by the 'load' functions to load data files. Use this function to
%   move the data directory.

projectdir = fullfile('~','local','en'); % for large files you won't keep in dropbox
switch dirtype
    case 'project'
        outdir = projectdir;

    case 'analysis'
        outdir = fullfile(projectdir, 'analysis');

    case 'looplogs'
        outdir = fullfile(projectdir, 'analysis', 'looplogs');

    case 'data'
        outdir = fullfile(projectdir, 'data');

    case 'bdf'
        outdir = fullfile(projectdir, 'data', 'bdf');

    case 'eeg'
        outdir = fullfile(projectdir, 'data', 'eeg');

    case 'eeg_plots'
        outdir = fullfile(projectdir, 'data', 'eeg_plots');

    case 'eeglab'
        outdir = fullfile(projectdir, 'eeglab');

    case 'dipfit'
        outdir = fullfile(projectdir, 'eeglab', 'plugins', 'dipfit2.3');

    case 'chanfile'
        outdir = fullfile(en_getFolder('eeglab'), 'functions', 'resources', 'Standard-10-5-Cap385_witheog.elp');

    case 'mrifile'
        outdir = fullfile(en_getFolder('dipfit'), 'standard_BEM', 'standard_mri.mat');

    case 'hdmfile'
        outdir = fullfile(en_getFolder('dipfit'), 'standard_BEM', 'standard_vol.mat');

end
end
