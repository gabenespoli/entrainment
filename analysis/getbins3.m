%% getbins3
%   Combines specified bins in a vector by mean, max, or min. A common use
%   is when y is fft data, x is the corresponding frequency vector, and
%   bins is the frequencies of interest, and you would like to find the
%   mean of the fft data over the specified frequency bins. This version
%   of the function is tailored to EEGLAB data, where the data matrix is
%   channels x time x trials.
%
% Usage:
%   s         = getbins3(y, x, bins)
%   s         = getbins3(y, x, bins, 'param', 'value', etc.)
%   [s, ind]  = getbins3(y, x, bins, ...)
%
% Input:
%   y         = [EEGLAB data matrix] Should be channels x time x trials or
%               channels x frequency x trials (for fft data).
%
%   x         = [numeric vector] A vector the same size as the second
%               dimension of y that contains "labels" for each column in y.
%               For fft data, this would be the frequency vector.
%
%   bins      = [vector] The labels in x that should be selected. A
%               separate "combination" (mean, max, or min) is returned for
%               each value in bins. That is, the output of this function is
%               the same size as bins.
%
%   'width'   = [numeric] The number of bins on either side of the middle
%               bin that should be included in the combination. Default is
%               0, which will simply return the value of specified bins
%               (i.e., no "combining" will be done). If the width is too
%               wide for the amount of data (in y) and a given bin, an
%               error occurs.
%
%   'cwidth'  = [numeric] Center width that should be excluded. Enter 0 to
%               exclude only the center bin and 1 or greater to also
%               exclude that many bins on either side of the center bin.
%               The value must be smaller than 'width'. Default [] (empty),
%               which includes the center bin.  
%
%   'func'    = ['mean','max','min'] Function to use if 'width' is
%               non-zero. Default 'mean'.
%
% Output:
%   s         = [numeric] The value calculated at each value of bins.
%
%   ind       = [numeric] The indices in x of the values in bins.
%
% Examples:
%   >> getbins3(yfft, f, [50 60])
%   If yfft is fft data and f is the corresponding frequency vector, find
%   the amount of energy at 50 and 60 Hz.
%
%   >> getbins3(yfft, f, 60, 'width', 5)
%   Find the average of 11 bins centered on 60 Hz. Note that the width in
%   Hz of the average will be dependent on the bin width of f. You can get
%   the mean bin width using mean(diff(f)).
%   
%   >> getbins3(yfft, f, 60, 'width', 5) - ...
%          getbins3(yfft, f, 60, 'width', 10, 'cwidth', 5)
%   Get the average of 11 bins centered on 60 Hz, and subtract the average
%   of 10 bins, 5 each on either side of 60 Hz and 5 bins away from 60 Hz.
%   If the bin width of f is 1 Hz, this is the equivalent of taking the
%   average of bins 55-65, and subtracting the mean of 50-54 and 66-70.
%
% Written by Gabe Nespoli 2015-03-10. Revised 2018-03-13.

function [s, ind] = getbins3(y, x, bins, varargin)

% defaults
width = 0;
cwidth = [];
func = 'mean';

% user-defined
for i = 1:2:length(varargin)
    val = varargin{i+1};
    switch lower(val)
        case 'width',   if ~isempty(val), width = val; end
        case 'cwidth',  if ~isempty(val), cwidth = val; end
        case 'func',    if ~isempty(val), func = val; end
    end
end

% check input
if length(x) ~= size(y, 2) % check X is same length as dim 2 of Y
    error('Length of X does not match the number of columns in Y.')
end

% create container variables
ind = nan(1, length(bins));
s = nan(size(y, 1), length(bins), size(y, 3));

% convert bin values to indices (find value of X closest to BIN value)
for i = 1:length(bins)
    [~, ind(i)] = min(abs(x - bins((i))));
end

% loop through bins and calculate using func
for i = 1:length(ind)

    if ind(i)-width < 1 || ind(i)+width > length(x)
        error('BIN exceeds dimensions of X when combined with WIDTH.')
    end

    % get indicies of desired mean
    if width == 0 % if width = 0, just return the value
        tempind = ind(i);

    elseif isempty(cwidth) % mean of target bin and surrounding
        tempind = ind(i)-width:ind(i)+width;

    elseif cwidth < width % mean of only surrounding bins
        farbound = width+cwidth-1;
        tempind = [ind(i)-farbound:ind(i)-cwidth, ...
            ind(i)+cwidth:ind(i)+farbound];

    else
        error('Problem with width and cwidth input.')

    end

    % apply function if there is a width
    if width > 0
        switch func
            case 'mean'
                s(:, i, :) = mean(y(:, tempind, :), 2);
            case 'max'
                s(:, i, :) = max(y(:, tempind, :), [], 2); 
            case 'min'
                s(:, i, :) = min(y(:, tempind, :), [], 2); 
            otherwise
                error('Invalid func.')
        end
    else
        s(:, i, :) = y(:, tempind, :);
    end
end
end


