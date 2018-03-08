function EEG = en_dipfit(EEG, varargin)

dipType = 'multi'; % coarse or multi
hc = []; % head circumference in cm
chans = 1:size(EEG.data,1);
rv = 15; % residual variance threshold
 
for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case {'diptype', 'type'},   dipType = varargin{i+1};
        case 'hc',                  hc = varargin{i+1};
        case 'rv',                  rv = varargin{i+1};
        case 'chans',               chans = varargin{i+1};
        otherwise, fprintf('Unknown param: ''%s''\n', varargin{i})
    end
end

% get head radius in mm
if isempty(hc)
    hr = 85;
else
    hr = hc/pi/2*10;
end

% get files
hdmfile  = fullfile(en_getFolder('dipfit'), 'standard_BESA', 'standard_BESA.mat');
mrifile  = fullfile(en_getfolder('dipfit'), 'standard_BESA', 'avg152t1.mat');
chanfile = fullfile(en_getfolder('dipfit'), 'standard_BESA', 'standard-10-5-cap285.elp');
% coord_transform = [0.628547 -15.8455 2.29126 0.0859382 0.00361671 -1.57308 1.17301 1.06471 1.15137];

% create head model
EEG = pop_dipfit_settings(EEG, ...
    'coordformat',      'Spherical', ... % MNI or Spherical
    'chansel',          chans, ...
    'hdmfile',          hdmfile, ...
    'mrifile',          mrifile, ...
    'chanfile',         chanfile);

switch lower(dipType)
    case 'coarse'
        % coarse fit
        EEG = pop_dipfit_gridsearch(EEG, ...
            1:EEG.nbchan, ...
            linspace(-hr,hr,11), ...
            linspace(-hr,hr,11), ...
            linspace(0,hr,6), ...
            0.4);

    case 'multi'
        EEG = pop_multifit(EEG, ...
            chans, ...
            'threshold', rv, ...
            'plotopt', {'normlen' 'on'}); % auto fit

end

EEG = eeg_checkset(EEG);

end
