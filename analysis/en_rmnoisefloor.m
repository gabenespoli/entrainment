%NOISEFLOOR  Removes the mean of neighbouring bins. Usually used for 
%   normalizing FFT data. This function is for eeglab data, i.e. the
%   shape of the data matrix should be channels x time x trials.
%
%   Y = NOISEFLOOR(X,BINS) takes each value in X and subracts the mean
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
%   [Y,F] = NOISEFLOOR(X,BINS,F) takes an additional vector F and shortens
%       it the same amount as X. This is usually used when X is fft data
%       and F is the corresponding frequency vector.

% Written by Gabe Nespoli 2014-02-27. Revised 2018-03-13.
% Adapted from Nozaradan et al., 2011, Journal of Neuroscience.

function [y, f] = en_rmnoisefloor(x, bins, f)

if length(f) ~= size(x, 2)
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

do_waitbar = 0;
tic
for comp = 1:size(x, 1)

    for trial = 1:size(x, 3) % loop trials
        for i = 1+a+b:size(x, 2)-a-b % samples in current trial
            y(comp, i, trial) = x(comp, i, trial) - ...
                mean(x(comp, [i-a-b:i-a-1, i+a+1:i+a+b], trial));
        end

        % start waitbar if this is taking longer than 2 seconds
        switch do_waitbar
            case 0
                if toc > 2
                    textprogressbar('Removing spectral noise floor...');
                    textprogressbar( (trial + (size(x, 3) * (comp - 1))) / (size(x, 3) * size(x, 1)) );
                    do_waitbar = 1;
                end
            case 1
                textprogressbar( (trial + (size(x, 3) * (comp - 1))) / (size(x, 3) * size(x, 1)) );
        end
    end
end

if do_waitbar
    textprogressbar('done')
end

% set negative values to zero
y(y < 0) = 0;

% remove unaffected bins
y(:, [1:a+b, end-a-b+1:end], :)=[];

% remove unaffected bins from freq vector
if ~isempty(f)
    f([1:a+b, end-a-b+1:end])=[];
end
end

function textprogressbar(c)
% This function creates a text progress bar. It should be called with a
% STRING argument to initialize and terminate. Otherwise the number correspoding
% to progress in % should be supplied.
% INPUTS:   C   Either: Text string to initialize or terminate
%                       Proportion number to show progress
% OUTPUTS:  N/A
% Example:  Please refer to demo_textprogressbar.m

% Author: Paul Proteus (e-mail: proteus.paul (at) yahoo (dot) com)
% Version: 1.0
% Changes tracker:  29.06.2010  - First version

% Inspired by: http://blogs.mathworks.com/loren/2007/08/01/monitoring-progress-of-a-calculation/

% Modified by Gabe Nespoli 2016-05-13

% defaults
persistent strCR;           %   Carriage return pesistent variable
strPercentageLength = 6;    %   Length of percentage string (must be >5)
strDotsMaximum      = 20;   %   The total number of dots in a progress bar
progressCharacter   = '=';

if isempty(strCR) && ~ischar(c)
    % Progress bar must be initialized with a string
    error('The text progress must be initialized with a string');
    
elseif isempty(strCR) && ischar(c)
    % Progress bar - initialization
    fprintf('%s ',c);
    strCR = -1;
    
elseif ~isempty(strCR) && ischar(c)
    % Progress bar  - termination
    strCR = [];
    fprintf([c '\n']);
    
elseif isnumeric(c)
    % Progress bar - normal progress
    c = floor(c * 100);
    percentageOut = [num2str(c) '%%'];
    percentageOut = [percentageOut repmat(' ',1,strPercentageLength-length(percentageOut)-1)];
    nDots = floor(c/100*strDotsMaximum);
    dotOut = [' [' repmat(progressCharacter,1,nDots) repmat(' ',1,strDotsMaximum-nDots) '] '];
    strOut = [percentageOut dotOut];
    
    % Print it on the screen
    if strCR == -1
        % Don't do carriage return during first run
        fprintf(strOut);
    else
        % Do it during all the other runs
        fprintf([strCR strOut]);
    end
    
    % Update carriage return
    strCR = repmat('\b',1,length(strOut)-1);
    
else
    % Any other unexpected input
    error('Unsupported argument type');
end
end


