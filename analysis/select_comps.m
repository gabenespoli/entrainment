%% select_comps
%   Get component numbers filtered by region and residual variance.
%
% Usage:
%   comps = select_comps(EEG, rv, region, ind)
%
% Input:
%   EEG = [struct] A preprocessed EEGLAB structure with ICA weights and
%       dipole information.
%
%   rv = [numeric between 0 and 1] Residual variance threshold.
%       Default [] (empty; don't filter by residual variance).
%
%   region = [numeric] Input for region2comps. Usually a vector of
%       Broadmann areas. This option requires the region2comps.m and
%       tal2region.m functions. Default [] (empty; don't filter by region).
%
%   ind = [numeric] List of indices to use when filtering by region and
%       residual variance. Default [] (empty; don't filter by indices).
%
%   cubesize = [0:5] See tal2region.m. Default 1:5.
%
% Output:
%   comps = See region2comps.m.
%   cubesizes = See region2comps.m
%   coords = See region2comps.m

function [comps, cubesizes, coords] = select_comps(EEG, rv, region, ind, cubesize)

% defaults
if nargin < 2 || isempty(rv), rv = []; end
if nargin < 3 || isempty(region), region = []; end
if nargin < 4 || isempty(ind), ind = []; end
if nargin < 5 || isempty(cubesize), cubesize = 1:5; end
% TODO: catch if dipole fitting hasn't been done yet
allinds = 1:length(EEG.dipfit.model);

% filter comps by residual variance
if ~isempty(rv)
    ind_rv = find([EEG.dipfit.model.rv] < rv);
else
    ind_rv = allinds;
end

% filter comps by region (Broadmann area)
% TODO: add SMA as possible region, use tal coords from Mayka2006
% Mayka2006: Three-dimensional locations and boundaries of motor and premotor cortices as defined by functional brain imaging: A meta-analysis
if ~isempty(region)
    [ind_region, cubesizes, coords] = region2comps(EEG, region, cubesize);
    ind_region = transpose(ind_region);
    cubesizes = transpose(cubesizes);
else
    ind_region = allinds;
    cubesizes = [];
    coords = [];
end

% apply rv and region filters 
[comps, iA] = intersect(ind_region, ind_rv);
cubesizes = cubesizes(iA);
coords = coords(iA,:);

% apply manual indices filter
if ~isempty(ind) && ~isnan(ind)
    [comps, iA] = intersect(comps, ind);
    cubesizes = cubesizes(iA);
    coords = coords(iA,:);
end

end
