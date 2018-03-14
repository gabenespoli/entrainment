%GETFFT3  Single-sided FFT for 3D EEGLAB data matrix.
%
% USAGE
%   [data,freqs,featureTitle,units] = getfft3(data,srate)
%   [...] = getfft3(...,'Param1',Value1,etc.)
% 
% INPUT
%   data          = [numeric] A channels-by-time-by-trials array of data.
% 
%   srate         = [numeric] Sampling frequency of the data.
% 
%   'spectrum'    = ['amplitude'|'power'|'phase'|'complex'] Specifies the
%                   type of spectrum to calculate. Default 'amplitude'.
% 
%   'nfft'        = [numeric] Number of points in the FFT. Default is the
%                   next power of two after the length of the epoch.
%
%   'wintype'     = ['hanning'|'none'] Type of windowing to apply to the
%                   epoch. Default 'hanning'.
% 
%   'ramp'        = [numeric] Only apply hanning window to onset and
%                   offset of the signal. This number should be a length
%                   of time in milliseconds. A hanning window will be
%                   created that is twice this length; the first half will
%                   be applied to the onset, and the second half will be
%                   applied to the offset. This option is only used when
%                   'wintype' is 'hanning'.
%
%   'detrend'     = [true|false] Whether or not to remove the mean from the
%                   signal before calculating the FFT. This is done twice:
%                   before and after applying the window. Default true.
%
%   'units'       = [string] The units of the data, to be adjusted if
%                   power spectrum.
%
% OUTPUT
%   data          = [numeric] Matrix where each row is the spectrum of the
%                   corresponding row in the input matrix.
% 
%   freqs         = [numeric] Vector of frequencies corresponding to each
%                   column of the output data.
% 
%   featureTitle  = [string] Formatted title of type of spectrum
%                   (for plotting).
% 
%   units         = [string] If power spectrum is used, '^2' is appended
%                   to the units string.

function [data,f,featureTitle,units] = getfft3(data,srate,varargin)

if nargout == 0 && nargin == 0, help phzUtil_fft, return, end

% defaults
spectrum = 'amplitude';
nfft = 1;
winType = 'hanning';
ramp = [];
do_detrend = true;
units = '';

% user-defined
% if empty, the default is used
for i = 1:2:length(varargin)
    val = varargin{i+1};
    switch lower(varargin{i})
        case 'spectrum',    if ~isempty(val), spectrum = val; end
        case 'nfft',        if ~isempty(val), nfft = val; end
        case 'wintype',     if ~isempty(val), winType = val; end
        case 'ramp',        if ~isempty(val), ramp = val; end
        case 'detrend',     if ~isempty(val), do_detrend = val; end
        case 'units',       if ~isempty(val), units = val; end
    end
end

% cleanup user-defined
switch nfft
    case 0,     nfft = size(data,2);
    case 1,     nfft = 2^nextpow2(size(data,2));
end

if do_detrend
    data = detrend(data, 'constant');
end

% windowing
% make hanning row vector
switch lower(winType)
    case {'hanning','hann'}
        if isempty(ramp)
            win = transpose(hann(size(data,2))); % make hanning row vector

        else
            % this part adapted from the bt_fft2.m function from the
            %   Auditory Neuroscience Lab's Brainstem Toolbox:
            %   http://www.brainvolts.northwestern.edu
            ramp = round(ramp / 1000 * srate); % length of ramp in samples
            ramp2 = ramp * 2; % length of both ramps
            if ramp2 > size(data, 2)
                error('Ramp size is too long for the length of trials.')
            end
            hanramp = transpose(hann(ramp2)); % make hanning row vector
            win = [hanramp(1:ramp) ...
                   ones(1, size(data, 2) - ramp2) ...
                   hanramp(ramp + 1:end)];
        end

    case {'nowindow','none'}

    otherwise
        error('Unknown window type.')
end

% apply the window to all trials
win = repmat(win, [size(data, 1), 1, size(data, 3)]);
data = data .* win;

if do_detrend
    data = detrend(data, 'constant');
end

% do fft
data = fft(data, nfft, 2);
data = data / nfft;
data = data(:, 1:floor(nfft / 2) + 1, :); % make single-sided

% create frequency vector
f = srate / 2 * linspace(0, 1, floor(nfft / 2) + 1);

% convert spectrum
switch lower(spectrum)
    case {'amplitude','amp','abs'}
        featureTitle = 'Amplitude';
        data = abs(data);

    case {'power','pwr','conj'}
        featureTitle = 'Power';
        data = data .* conj(data);
        % make units squared for power spectrum
        units = [units,'^2'];

    case {'phase','angle'}
        featureTitle = 'Phase';
        data = angle(data); 

    otherwise
        featureTitle = 'Complex';
end

end
