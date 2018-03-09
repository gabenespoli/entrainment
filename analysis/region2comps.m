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
%                   regardless of residual variance. Default 15.
%
%     'cubesize'  = See tal2region.m. Default 5 (1.1 cm^3).
%
% Output:
%     comps = Numeric vector list of component numbers.
%
% Written by Gabriel A. Nespoli 2016-04-25. Revised 2016-04-26.

function comps = region2comps(EEG, region, varargin)

if nargin == 0 && nargout == 0, help region2comps, return, end

% defaults
rv_threshold = 15;
cubesize = 5;

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


% ------------ this needs attention since tal2region was changed ---------
% get regions for each comp with specified cubesize (tal2region)
names = tal2region(coords, cubesize);
names = names.cellType;

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

end
