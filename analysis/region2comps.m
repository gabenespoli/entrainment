%REGION2COMPS  Return the numbers of components whose dipoles fall within
%   a certain distance of a specified Brodmann area or cell type.
%
% Usage:
%     comps = region2comps(EEG, region)
%     [comps, cubesizes] = region2comps(EEG, region, cubesize)
%
% Input:
%     EEG         = EEGLAB data structure.
%
%     region = Numeric vector specifying the Brodmann area(s) of interest,
%       or cell array of strings specifying the cell types of interest
%       (a list of available cell types can be found at
%       http://www.talairach.org/labels.html under "Level 5: Cell Type".
%
%     cubesize = [0:5] See tal2region.m. While the cubesize input for
%       tal2region.m must be a single number, this value can be multiple
%       numbers. In this case, all specified cubesizes are searched, and
%       the smallest corresponding cubsize is returned. Note that
%       a cubesize of 0 should always be used on its own, since it will
%       return the closest grey matter, even if this grey matter is
%       further away than the largest cubesize. Default 1:5.
%
% Output:
%   comps = Numeric vector list of component numbers (indices).
%
%   cubesizes = Numeric vector list of smallest cubsize for each comp.
%
%   coords = Numeric comps-by-3 matrix of Talairach coordinates for each
%       comp. coords(:,1) is the x coordinate, coords(:,2) is y,
%       coords(:,3) is z.
%
% Written by Gabriel A. Nespoli 2016-04-25. Revised 2018-06-13.

function [comps, cubesizes, coords] = region2comps(EEG, region, cubesize, bkwdcmp)

if nargin == 0 && nargout == 0, help region2comps, return, end
if nargin < 3 || isempty(cubesize), cubesize = 1:5; end

% backwards-compatibility with parameter-value pairs
% i.e., comps = region2comps(EEG, region, 'cubesize', cubesize)
if ischar(cubesize) && strcmpi(cubesize, 'cubesize')
    cubesize = bkwdcmp;
end
if length(cubesize) > 1 && ismember(0, cubesize)
    error('Cubesize of zero should only be used on its own.')
end

% check input
if ~isstruct(EEG)
    error('EEG should be an EEGLAB data structure.')
end
if ~ismember('dipfit', fieldnames(EEG))
    error('Dipoles must be fitted first.')
end

if ischar(region)
    region = cellstr(region);
    
elseif isnumeric(region) && isvector(region)
    temp = cell(size(region));
    for i = 1:length(region)
        temp{i} = ['Brodmann area ', num2str(region(i))];
    end
    region = temp;
    
else
    error('Problem with REGION input.')
end

if ~isnumeric(cubesize) || ...
    ~all(ismember(cubesize, 0:5)) || ...
    (length(cubesize) > 1 && ismember(0, cubesize))
    error('Problem with CUBESIZE input.')
end

% remove comps with empty coords
% we can't submit empty rows to tal2region.m
allCoords = {EEG.dipfit.model.posxyz}';
compsCoordsInd = find(~cellfun(@isempty, allCoords));
coords = cat(1, allCoords{:}); % make comps-by-3 array, remove empty rows

% make sure coords are talairach
switch EEG.dipfit.coordformat
    case 'MNI'
        coords = mni2tal(coords);
    case 'Spherical'
    otherwise
        error('Unknown coordinate format specified in EEG.dipfit.coordformat.')
end

% loop all cubesizes
for c = 1:length(cubesize)
    % ------------ this needs attention since tal2region was changed -----
    % get regions for each comp with specified cubesize (tal2region)
    locs = tal2region(coords, cubesize(c));
    names = locs.cellType; % same length as coords and compsCoordsInd

    % --------------------------------------------------------------------

    % find comps localized to specified Brodmann area(s)
    ind = [];
    for r = 1:length(region)
        tmp = find(cellfun(@(x) ismember(region{r}, x), names));
        ind = unique([ind; tmp]);
    end
    % comps (and allComps) is same size as allCoords, not coords
    comps = compsCoordsInd(ind);

    cubesizes = repmat(cubesize(c), size(comps));

    if c == 1
        allComps = comps;
        allCubesizes = cubesizes;
    else
        allComps = [allComps; comps]; %#ok<AGROW>
        allCubesizes = [allCubesizes; cubesizes]; %#ok<AGROW>
    end

end
comps = unique(allComps);

% return smallest cubesize for each comp
cubesizes = nan(size(comps));
for i = 1:length(comps)
    cubesizes(i) = min(allCubesizes(allComps == comps(i)));
end

% get coords for chosen comps
coords = allCoords(comps);
coords = cat(1, coords{:});

end
