%% en_select_comps
%   Get component numbers filtered by region, residual variance, and
%   dipolarity (manaually indicated in en_diary.csv).
%
% Usage:
%   comps = en_select_comps(EEG)
%   comps = en_select_comps(EEG, region, rv)
%
% Input:
%   EEG = [struct|numeric] Either a preprocessed EEGLAB structure with ICA
%       weights and dipole information, or a participant ID so that
%       en_load can be used to load the EEG struct.
%
%   region = [numeric] Input for region2comps. Usually a vector of
%       Broadmann areas. Default 6 (premotor).
%
%   rv = [numeric between 0 and 1] Residual variance threshold.
%       Default 0.15.

function comps = en_select_comps(EEG, region, rv)

% defaults
if nargin < 2 || isempty(region), region = 6; end
if nargin < 3 || isempty(rv),     rv = 0.15;  end

% get preprocessed EEG struct
if isnumeric(EEG)
    EEG = en_load('eeg', EEG);
elseif ~isstruct(EEG)
    error('Input must be an EEG struct or an ID number.')
end

% filter comps by region (Broadmann area)
ind_region = transpose(region2comps(EEG, region));

% filter comps by residual variance
ind_rv = find([EEG.dipfit.model.rv] < rv);

% filter comps by dipolarity
d = en_load('diary', str2num(EEG.setname)); % EEG.setname should be the ID
ind_dipolar = d.dipolar_comps{1};

% get comps that are the same across all three filters
comps = intersect(ind_region, ind_dipolar);
comps = intersect(comps, ind_rv);

end
