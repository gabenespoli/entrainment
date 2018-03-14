%% en_eeg_entrainment
% input can be a preprocessed EEG struct (with ICA and dipfit)
%   or a numeric ID number

function [T, fftdata, freqs] = en_eeg_entrainment(EEG, region, rv)
if nargin < 2 || isempty(region), region = 6; end % BA6 (premotor)
if nargin < 3 || isempty(rv), rv = 0.15; end % residual variance

stimType = 'sync';
trigType = 'eeg';

% get preprocessed EEG struct
if isnumeric(EEG)
    EEG = en_load('eeg', EEG);
elseif ~isstruct(EEG)
    error('Input must be an EEG struct or an ID number.')
end

% filter comps by region, rv, dipolarity
d = en_load('diary', str2num(EEG.setname)); % EEG.setname should be the ID
comps = select_comps(EEG, rv, region, d.dipolar_comps{1});

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
portcodes = L{L.stimType==stimType & L.trigType==trigType, 'portcode'};
S = en_load('stiminfo', portcodes);

% get values of each bin
en = nan(size(fftdata, 1), length(S.tempo));
for i = 1:length(en) % loop trials
    en(:, i) = getbins3(fftdata(:, :, i), freqs, S.tempo(i), ...
    'width', 0, ... % num bins on either side to look for max peak
    'func',  'max'); % find max bin val within width
end
[en, comps_ind] = max(en); % take max of all comps
comp = comps(comps_ind);

% make them column vectors
id = repmat(EEG.setname, length(en), 1);
en = transpose(en);
comp = transpose(comp);

T = table(id, en, comp);
T = [S, T];

end
