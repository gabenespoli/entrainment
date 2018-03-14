%% select_comps
%   Get component numbers filtered by region and residual variance.
%
% Usage:
%   comps = en_select_comps(EEG, region, rv, ind)
%
% Input:
%   EEG = [struct|numeric] Either a preprocessed EEGLAB structure with ICA
%       weights and dipole information, or a participant ID so that
%       en_load can be used to load the EEG struct.
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
% Output:
%   comps = [numeric] List of component numbers that matched all criteria.
%

function comps = select_comps(EEG, rv, region, ind)

% defaults
if nargin < 2, rv = []; end
if nargin < 3, region = []; end
if nargin < 4, ind = []; end
allinds = 1:length(EEG.dipfit.model);

% filter comps by residual variance
if ~isempty(rv)
    ind_rv = find([EEG.dipfit.model.rv] < rv);
else
    ind_rv = allinds;
end

% filter comps by region (Broadmann area)
if ~isempty(region)
    ind_region = transpose(region2comps(EEG, region));
else
    ind_region = allinds;
end

% apply rv and region filters 
comps = intersect(ind_region, ind_rv);

% apply manual indices filter
if ~isempty(ind)
    comps = intersect(comps, ind);
end

end
