%% en_eeg_entrainment
% input can be a preprocessed EEG struct (with ICA and dipfit)
%   or a numeric ID number

function [T, fftdata, freqs] = en_eeg_entrainment(EEG, region)
if nargin < 2 || isempty(region), region = 6; end % BA6 (premotor)

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
comps = select_comps(EEG, region, 0.15, d.dipolar_comps{1});

[fftdata, freqs] = en_fft(EEG.data(comps, :, :), ...
    EEG.srate, ...
    'spectrum',     'amplitude', ...
    'nfft',         2^16, ...
    'detrend',      false, ...
    'wintype',      'hanning', ...
    'ramp',         [], ...
    'dim',          2); % should the the time dimension

[fftdata, freqs] = en_rmnoisefloor(fftdata, [2 2], freqs);

% get tempos
L = en_load('logfile', EEG.setname); % setname should be id
portcodes = L{L.stimType==stimType & L.trigType==trigType, 'portcode'};
S = en_load('stiminfo', portcodes);

% get values of each bin
en = nan(size(fftdata, 1), length(S.tempo));
for i = 1:length(en) % loop trials
    en(:, i) = getbins(fftdata(:, :, i), freqs, S.tempo(i), ...
    'width', 0, ... % num bins on either side to look for max peak
    'func',  'max'); % find max bin val within width
end
[en, comps_ind] = max(en); % take max of all comps
comp = comps(comps_ind);

% make them column vectors
en = transpose(en);
comp = transpose(comp);

T = table(en, comp);
T = [S, T];

end
