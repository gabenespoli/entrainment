%% en_entrainment_eeg
%   Calculate entrainment of comps in a brain region. Saves topo and dip
%   plots and writes data to a csv file.
%
% Usage:
%   EN = en_entrainment_eeg(EEG)
%   EN = en_entrainment_eeg(EEG, 'param', value, etc.)
%   [EN, fftdata, freqs] = en_entrainment_eeg(...)
%
% Input:
%   EEG = [struct|numeric] EEGLAB struct with ICA and dipole information,
%       or ID number to load from getpath('eeg').
%
%   'region' = [string|numeric] Usually this will be 'pmc' or 'aud' to
%       select Brodmann areas 6 or [22 41 42] respectively. Can also be
%       numeric to specify other Broadmann areas.
%
%   'stim' = ['sync'|'mir']
%
%   'task' = ['eeg'|'tapping']
%
%   'rv' = [numeric between 0 and 1] Residual variance threshold for
%       selecting components. This should probably be the same or smaller
%       than what was used for en_preprocess_eeg.
%
%   'width' = [numeric (int)] Number of bins on either side of center bin
%       to include when selecting the max peak for a given frequency.
%
%   'harms' = [numeric] Harmonics of the tempo to calculate entrainment.
%       One entrainment value is found for each harmonic. Default is
%       [0.5 1 2 3 4 5 6 7 8].
%
% Output:
%   EN = [table] Data from logfile, stiminfo, and the entrainment analysis
%       in a single MATLAB table. This table is also written as a csv to
%       getpath('entrainment'). Columns should be as follows:
%
%           id
%           stim
%           task
%           trial
%           timestamp
%           filepath
%           filename
%           portcode
%           excerpt
%           rhythm
%           tempo_bpm
%           tempo
%           harm
%           region
%           region_comp
%
%   fftdata = [numeric] The fft data matrix (comps x frequency x trial).
%
%   freqs = [numeric] The corresponding frequency vector.
%
%   topoplots and dipplots of selected components are saved to
%       getpath('goodcomps')

% input can be a preprocessed EEG struct (with ICA and dipfit)
%   or a numeric ID number

function [EN, fftdata, freqs] = en_entrainment_eeg(EEG, varargin)

% defaults
region = 'pmc'; % pmc = 6, aud = [22 41 42]
stim = 'sync';
task = 'eeg';
rv = 0.15;
nfft = 2^16; % 2^16 = bin width of 0.0078 Hz
binwidth = 1; % number of bins on either side of tempo bin
% tempos are 0.1 Hz apart, so half-width max is 0.05
% binwidth = 1 means 3 bins are 0.0078 * 3 = 0.0234 Hz wide
% binwidth = 2 means 5 bins are 0.0078 * 5 = 0.0391 Hz wide
% binwidth = 3 means 7 bins are 0.0078 * 7 = 0.0546 Hz wide -- this is too
%   wide; tempos will run into one another
harms = [0.5 1 2 3 4 5 6 7 8];

% user-defined
for i = 1:2:length(varargin)
    val = varargin{i+1};
    switch lower(varargin{i})
        case 'region',              if ~isempty(val), region = val; end
        case 'stim',                if ~isempty(val), stim = val; end
        case 'task',                if ~isempty(val), task = val; end
        case 'rv',                  if ~isempty(val), rv = val; end
        case {'width', 'binwidth'}, if ~isempty(val), binwidth = val; end
        case 'harms',               if ~isempty(val), harms = val; end
    end
end

% get region and regionStr
if ischar(region)
    regionStr = region;
    switch lower(regionStr)
        case 'mot', region = 4;
        case 'pmc', region = 6;
        case 'pmm', region = [4 6];
        case 'aud', region = [22 41 42];
        otherwise, error('Invalid string for region input.')
    end
elseif isnumeric(region)
    if region == 4,                             regionStr = 'mot';
    elseif region == 6,                         regionStr = 'pmc';
    elseif all(ismember(region, [4 6])),        regionStr = 'pmm'; 
    elseif all(ismember(region, [22 41 42])),   regionStr = 'aud';
    else,                                       regionStr = 'other';
    end
end

% get preprocessed EEG struct
if isnumeric(EEG)
    id = EEG;
    idStr = num2str(EEG);
    EEG = en_load('eeg', EEG);
elseif isstruct(EEG)
    idStr = EEG.setname;
    id = str2num(EEG.setname); % EEG.setname should be the ID
else
    error('Input must be an EEG struct or an ID number.')
end

%% load required files
D = en_load('diary', id); 
L = en_load('logstim', [idStr, '_', stim, '_', task]); % setname should be id

% make output table
EN = L;
EN.id = repmat(idStr, height(EN), 1);
EN.Properties.UserData.filename = fullfile(getpath('entrainment'), ...
    [stim, '_', task], [idStr, '_', regionStr, '.csv']);

%% filter comps by region, rv, dipolarity
comps = select_comps(EEG, rv, region, D.dipolar_comps{1});

%% if there are some good comps, plot and calculate entrainment 
if ~isempty(comps)

    % dtplot(EEG, comps, fullfile(getpath('goodcomps'), regionStr)); % save plots of good ICs

    [yfft, f] = getfft3( ...
        EEG.data(comps, :, :), ...
        EEG.srate, ...
        'spectrum',     'amplitude', ...
        'nfft',         nfft, ...
        'detrend',      false, ...
        'wintype',      'hanning', ...
        'ramp',         [], ...
        'dim',          2); % should the the time dimension

    [fftdata, freqs] = noisefloor3(yfft, [2 2], f);

    % loop trials
    % en is comps x harms x trials
    en = zeros(length(comps), length(harms), height(EN));

    for i = 1:height(EN)
        en(:, :, i) = getbins3( ...
            fftdata(:, :, i), ...
            freqs, ...
            harms * EN.tempo(i), ...
            'width', binwidth, ...
            'func',  'mean');
    end

    % take max of all comps, convert to harms x trials
    [en, comps_ind] = max(en, [], 1); 
    en = squeeze(en);
    comps_ind = squeeze(comps_ind);

else
    en = zeros(length(harms), height(EN));
    comps_ind = ones(size(en));
    comps = 0;

end

% put vals into EN table
EN_bak = EN; % save meta data
for i = 1:length(harms)
    EN_tmp = EN_bak;
    EN_tmp.(regionStr) = transpose(en(i, :));
    EN_tmp.([regionStr, '_comp']) = transpose(comps(comps_ind(i, :)));

    if i == 1
        EN = EN_tmp;
    else
        EN = [EN; EN_tmp];
    end
end

writetable(EN, EN.Properties.UserData.filename)

end
