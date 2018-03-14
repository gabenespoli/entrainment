%% en_eeg_entrainment
% input can be a preprocessed EEG struct (with ICA and dipfit)
%   or a numeric ID number

function [T, fftdata, freqs] = en_eeg_entrainment(EEG, varargin)

% defaults
region = 'pmc'; % pmc = 6, aud = [22 41 42]
stimType = 'sync';
trigType = 'eeg';
rv = 0.15;
binwidth = 5;

% user-defined
for i = 1:2:length(varargin)
    val = varargin{i+1};
    switch lower(varargin)
        case 'region',              if ~isempty(val), region = val; end
        case {'stim', 'stimtype'},  if ~isempty(val), stimType = val; end
        case {'trig', 'trigtype'},  if ~isempty(val), trigType = val; end
        case 'rv',                  if ~isempty(val), rv = val; end
        case {'width', 'binwidth'}, if ~isempty(val), binwidth = val; end
    end
end

% get region and regionStr
if ischar(region)
    regionStr = region;
    switch lower(regionStr)
        case 'pmc', region = 6;
        case 'aud', region = [22 41 42];
        otherwise, error('Invalid string for region input.')
    end
elseif isnumeric(region)
    if region == 6,                             regionStr = 'pmc';
    elseif all(ismember(region, [22 41 42])),   regionStr = 'aud';
    else,                                       regionStr = 'other';
    end
end

% get preprocessed EEG struct
if isnumeric(EEG)
    EEG = en_load('eeg', EEG);
elseif ~isstruct(EEG)
    error('Input must be an EEG struct or an ID number.')
end

% filter comps by region, rv, dipolarity
d = en_load('diary', str2num(EEG.setname)); % EEG.setname should be the ID
comps = select_comps(EEG, rv, region, d.dipolar_comps{1});
dtplot(EEG, comps, en_getpath([regionStr, 'comps'])); % save plots of good ICs

[fftdata, freqs] = getfft3(EEG.data(comps, :, :), ...
    EEG.srate, ...
    'spectrum',     'amplitude', ...
    'nfft',         2^16, ...
    'detrend',      false, ...
    'wintype',      'hanning', ...
    'ramp',         [], ...
    'dim',          2); % should the the time dimension

[fftdata, freqs] = noisefloor3(fftdata, [2 2], freqs);

% get tempos
L = en_load('logfile', EEG.setname); % setname should be id
L = L(L.stimType==stimType & L.trigType==trigType, :);
S = en_load('stiminfo', L.portcode);
if all(L.portcode == S.portcode)
    S.portcode = [];
    S.stimType = [];
    T = [L, S];
end

% get values of each bin
en = nan(size(fftdata, 1), length(S.tempo));
for i = 1:length(en) % loop trials
    en(:, i) = getbins3(fftdata(:, :, i), freqs, S.tempo(i), ...
    'width', binwidth, ...
    'func',  'max');
end
[en, comps_ind] = max(en, [], 1); % take max of all comps
comp = comps(comps_ind);

% make them column vectors
T.id = repmat(EEG.setname, length(en), 1);
T.comp = transpose(comp);
T.en = transpose(en);
T.Properties.VariableNames{end} = regionStr;

writetable(T, fullfile(en_getpath('entrainment'), [EEG.setname, '_', regionStr, '.csv']))

end
