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
%     region      = Numeric vector specifying the Brodmann area(s) of
%                   interest, or cell array of strings specifying the cell
%                   types of interest (a list of available cell types can
%                   be found at http://www.talairach.org/labels.html under
%                   "Level 5: Cell Type".
%
%     cubesize    = [0:5] See tal2region.m. Default 0.
%
% Output:
%     comps = Numeric vector list of component numbers (indices).
%
%     cubesizes = Numeric vector list of smallest cubsize for each comp.
%
% Written by Gabriel A. Nespoli 2016-04-25. Revised 2018-06-13.

function [comps, cubesizes, coords] = region2comps(EEG, region, cubesize, bkwdcmp)

if nargin == 0 && nargout == 0, help region2comps, return, end
if nargin < 3 || isempty(cubesize), cubesize = 0; end

% backwards-compatibility with parameter-value pairs
% i.e., comps = region2comps(EEG, region, 'cubesize', cubesize)
if ischar(cubesize) && strcmpi(cubesize, 'cubesize')
    cubesize = bkwdcmp;
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

if ~isnumeric(cubesize) || ~all(ismember(cubesize, 0:5))
    error('Problem with CUBESIZE input.')
end

% get coords for all comps
coords = {EEG.dipfit.model.posxyz}';
compsGood = find(~cellfun(@isempty, coords)); % non-empty coords
coords = cat(1, coords{:});

% make sure coords are talairach
switch EEG.dipfit.coordformat
    case 'MNI'
        coords = mni2tal(coords);
    case 'Spherical'
    otherwise
        error('Unknown coordinate format specified in EEG.dipfit.coordformat.')
end

% loop all cubesizes
for j = 1:length(cubesize)
    % ------------ this needs attention since tal2region was changed ---------
    % get regions for each comp with specified cubesize (tal2region)
    locs = tal2region(coords, cubesize(j));
    names = locs.cellType;

    % ------------------------------------------------------------------------

    % find comps localized to specified Brodmann area(s)
    indComps = [];
    for i = 1:length(region)
        ind = find(cellfun(@(x) ismember(region{i}, x), names));
        indComps = unique([indComps; ind]);
    end
    comps = compsGood(indComps);

    cubesizes = repmat(cubesize(j), size(comps));

    if j == 1
        allComps = comps;
        allCubesizes = cubesizes;
    else
        allComps = [allComps; comps]; %#okAGROW
        allCubesizes = [allCubesizes; cubesizes]; %#okAGROW
    end

end
comps = unique(allComps);

% return smallest cubesize for each comp
cubesizes = nan(size(comps));
for i = 1:length(comps)
    cubesizes(i) = min(allCubesizes(allComps == comps(i)));
end

end
