%NOISEFLOOR3  Removes the mean of neighbouring bins. Usually used for 
%   normalizing FFT data. This version is for EEGLAB data, where the
%   shape of the data matrix should be channels x time x trials.
%
%   Y = NOISEFLOOR3(X,BINS) takes each value in X and subracts the mean
%       of surrounding values as specified in BINS. BINS is the number of 
%       bins values on either side to average and then subtract from the 
%       current value. BINS can also be a 1x2 vector [NUMBINS BINSAWAY], 
%       where NUMBINS is the number of values to average on either side of 
%       the current one and BINSAWAY is the number of values to ignore 
%       between the current one and the averaged values. Since this 
%       procedure leaves BINS number of values unaffected at each end of X,
%       Y will be 2 x BINS values shorter than X. If X is a matrix, this
%       procedure is carried out on the first non-singleton dimension.
%
%   [Y,F] = NOISEFLOOR3(X,BINS,F) takes an additional vector F and shortens
%       it the same amount as X. This is usually used when X is fft data
%       and F is the corresponding frequency vector.

% Written by Gabe Nespoli 2014-02-27. Revised 2018-03-13.
% Adapted from Nozaradan et al., 2011, Journal of Neuroscience.

function [y, f] = noisefloor3(x, bins, f)
if nargin < 3, f = []; end

if ~isempty(f) && (length(f) ~= size(x, 2))
    error('F must be the same length as size(EEG.data,2).')
end

switch length(bins)
    case 0
        disp('Empty BINS value. Returning input variables untouched.')
        y = x;
        return
        
    case 1
        b = bins; % number of bins to average        
        a = 0; % number of bins away from current bin, default 0 (adjacent)
        
    case 2
        b = bins(1); % number of bins to average        
        a = bins(2); % number of bins away from current bin
        
    otherwise
        error('BINS must be of length 1 or 2')
end

% create output container
y = nan(size(x));

fprintf('Removing spectral noise floor (this may take a while)... ')
for comp = 1:size(x, 1)

    for trial = 1:size(x, 3) % loop trials
        for i = 1+a+b:size(x, 2)-a-b % samples in current trial
            y(comp, i, trial) = x(comp, i, trial) - ...
                mean(x(comp, [i-a-b:i-a-1, i+a+1:i+a+b], trial));
        end
    end
end
fprintf('Done.\n')

% set negative values to zero
y(y < 0) = 0;

% remove unaffected bins
y(:, [1:a+b, end-a-b+1:end], :)=[];

% remove unaffected bins from freq vector
if ~isempty(f)
    f([1:a+b, end-a-b+1:end])=[];
end
end
