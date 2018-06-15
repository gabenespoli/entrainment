%REGION2COMPS  Return the numbers of components whose dipoles fall within
%   a certain distance of a specified Brodmann area or cell type.
%
% Usage:
%     comps = region2comps(EEG, region)
%     comps = region2comps(EEG, region, 'Param1', 'Value1', ...)
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
%     'rv'        = Only return components with a residual variance below
%                   this percentage. Enter 0 to return all components
%                   regardless of residual variance. Enter a number
%                   between 0 and 100. Default 0.
%
%     'cubesize'  = Number or numeric vector specifying cubsizes to pass
%                   to tal2region.m. Default [0:5]. If a vector, each
%                   cubsize is searched, and the smallest value is
%                   returned. This effectively gives the distance of
%                   each component to the region.
%
% Output:
%     comps = Numeric vector list of component numbers.
%
%     cubesizes = Numeric vector list of smallest cubsize for each comp.
%
% Written by Gabriel A. Nespoli 2016-04-25. Revised 2018-06-13.

function [comps, cubesizes] = region2comps(EEG, region, varargin)

if nargin == 0 && nargout == 0, help region2comps, return, end

% defaults
rv_threshold = 0;
cubesize = 0:5;

% user-defined
for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'rv',          rv_threshold = varargin{i+1};        
        case 'cubesize',    cubesize = varargin{i+1};
    end
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
    fprintf('Searching with a cubesize of %i...\n', cubesize(j))

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

    % restrict to comps below a certain residual variance
    if rv_threshold ~= 0
        rv = {EEG.dipfit.model(compsGood).rv}';
        rv = cat(1, rv{:});
        rv = rv(indComps);
        comps = comps(rv < rv_threshold / 100);
    end

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
