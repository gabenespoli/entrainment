%% eeg_entrainment
%   Calculate entrainment of comps in a brain region.
%
% Usage:
%   EN = eeg_entrainment(EEG, tempo)
%   EN = eeg_entrainment(EEG, tempo, 'param', value, etc.)
%   [EN, fftdata, freqs] = eeg_entrainment(...)
%
% Input:
%   EEG = [struct|numeric] EEGLAB struct with ICA and dipole information,
%       or ID number to load from getpath('eeg').
%
%   tempo = [numeric] The frequency (in Hz) where we should look for 
%       entrainment. Use the 'harms' parameter to look at different
%       harmonics of this main tempo. Can also be a vector, the same
%       length as the number of trials (i.e., size(EEG.data, 3)), if each
%       trial has a different tempo of interest.
%
%   'region' or 'regions' = [numeric|string|cell] Vector of Broadmann
%       areas to select components. Can also be a string for the following
%       preset values. For additional custom presets, edit the
%       parse_region subfunction. Default is {'aud', 'pmc'}.
%
%       'aud' = [22 41 42]      primary auditory cortex
%       'pmc' = 6               premotor cortex
%       'mot' = 4               primary motor cortex
%       'som' = [1 2 3]         somatosensory cortex
%       'pfc' = [9 46]          dorsolateral prefrontal cortex
%
%       Can also be a cell of vectors and strings. In this case,
%       components are assigned to the area to which they are closest, and
%       are not allowed to be assigned to multiple regions. In the case
%       where a component is the same distance from multiple regions, see
%       the 'tieWarning' parameter.
%
%   'tieWarning' = [0|1|2] If a component is the same (closest) distance
%       from multiple regions, it will remain assigned to all of those
%       regions. The following values are allowed. Default is 2.
%       
%       0 = don't do anything (continue execution)
%       1 = throw an error (stop execution)
%       2 = show a warning (continue execution)
%
%   'rv' = [numeric between 0 and 1] Residual variance threshold for
%       selecting components. This should probably be the same or smaller
%       than what was used for en_preprocess_eeg. Default 0.15.
%
%   'cubesize' = [numeric between 0 and 5] Cubesize to use when searching 
%       for regions. See docs for tal2region.m. Default 1:5.
%
%   'nfft'  = [numeric] Number of points in the FFT. Default 2^16, which
%       gives each frequency bin a width of 0.0078 Hz.
%
%   'width' = [numeric (int)] Number of bins on either side of center bin
%       to include when selecting the max peak for a given frequency.
%       Default 1 (select 3 bins).
%
%   'harms' = [numeric] Harmonics of the tempo to calculate entrainment.
%       One entrainment value is found for each harmonic. Default is
%       [0.5 1 2 3 4 5 6 7 8].
%
%   'filename' = [string] Write the resulting table to a csv file.
%       Default is empty to not write a file.
%
% Output:
%   EN = [table] Columns should be as follows:
%
%           trial
%           harmonic
%           region1_comp
%           region1_x (Talairach coordinates)
%           region1_y
%           region1_z
%           region1_distance (i.e., smallest cubesize in mm)
%           region1
%           region2_comp
%           etc.
%
%   fftdata = [numeric] The fft data matrix (comps x frequency x trial).
%
%   freqs = [numeric] The corresponding frequency vector.

function [EN, fftdata, freqs] = eeg_entrainment(EEG, tempo, varargin)

%% settings
% defaults
region = {'aud', 'pmc'}; % pmc = 6, aud = [22 41 42]
tieWarning = 2;
rv = 0.15;
cubesize = 1:5;
nfft = 2^16; % 2^16 = bin width of 0.0078 Hz
binwidth = 1; % number of bins on either side of tempo bin
% tempos are 0.1 Hz apart, so half-width max is 0.05
% binwidth = 1 means 3 bins are 0.0078 * 3 = 0.0234 Hz wide
% binwidth = 2 means 5 bins are 0.0078 * 5 = 0.0391 Hz wide
% binwidth = 3 means 7 bins are 0.0078 * 7 = 0.0546 Hz wide -- this is too
%   wide; tempos will run into one another
harms = [0.5 1 2 3 4 5 6 7 8];
filename = '';

% user-defined
for i = 1:2:length(varargin)
    val = varargin{i+1};
    switch lower(varargin{i})
        case {'region', 'regions'}, if ~isempty(val), region = val; end
        case 'tiewarning',          if ~isempty(val), tieWarning = val; end
        case 'rv',                  if ~isempty(val), rv = val; end
        case 'cubesize',            if ~isempty(val), cubesize = val; end
        case 'nfft',                if ~isempty(val), nfft = val; end
        case {'width', 'binwidth'}, if ~isempty(val), binwidth = val; end
        case 'harms',               if ~isempty(val), harms = val; end
        case 'filename',            if ~isempty(val), filename = val; end
    end
end

% adjust tempo
if length(tempo) == 1
    tempo = repmat(tempo, 1, size(EEG.icaact, 3));
elseif length(tempo) ~= size(EEG.icaact, 3)
    error('Tempo input is not the same length as the number of trials.')
end

% get region and regionStr as cells
if iscell(region)
    regionStr = cell(size(region));
    for i = 1:length(region)
        [region{i}, regionStr{i}] = parse_region(region{i});
    end
else
    [region, regionStr] = parse_region(region);
    region = {region};
    regionStr = {regionStr};
end

%% get comps localized to regions
% loop regions and get all comps localized to each
comps = cell(size(region));
cubesizes = cell(size(region));
coords = cell(size(region));
for i = 1:length(region)
    fprintf('Searching in region %s...\n', regionStr{i})
    [comps{i}, cubesizes{i}, coords{i}] = select_comps(EEG, rv, region{i}, [], cubesize);
end

% remove comps that are closer to a different region
for r = 1:length(region)

    % get comps and cubesizes of all other regions
    other_comps = comps;
    other_comps(r) = [];
    other_comps = cell2mat(other_comps);
    other_cubesizes = cubesizes;
    other_cubesizes(r) = [];
    other_cubesizes = cell2mat(other_cubesizes);

    rmind = []; % indices of comps to remove from this region
    for c = 1:length(comps{r})

        % get inds of this comp in other regions
        ind = ismember(other_comps, comps{r}(c));

        if any(ind)
            % if other comps are closer, mark this one for removal
            if any(other_cubesizes(ind) < cubesizes{r}(c))
                % fprintf('Removing comp %i from region ''%s''...\n', ...
                    % comps{r}(c), region)
                rmind = [rmind c]; %#okAGROW
            end
        end
    end

    % remove comps from this region that are closer to other regions
    if rmind
        comps{r}(rmind) = [];
        cubesizes{r}(rmind) = [];
        coords{r}(rmind,:) = [];
    end
end

% warn if a single comp is assigned to multiple regions
if length(unique(cell2mat(comps))) < length(cell2mat(comps))
    if tieWarning == 1
        error(['A single component is being assigned ', ...
               'to multiple regions.'])
     elseif tieWarning == 2
        warning(['A single component is being assigned ', ...
                 'to multiple regions.'])
     end
end

% TODO: change any cubesize of 0 to a distance of NaN
% cubesize of 0 returns closest gray matter, we don't know the distance

%% calculate entrainment
% trials x harms x region
en_region = zeros(size(EEG.icaact, 3), length(harms), length(regionStr));
if ~all(cellfun(@isempty, comps))

    % make comps and cubesizes single vectors, and make a corresponding
    %   cell array with region strings (call regions)
    regions = {};
    for r = 1:length(comps)
        regions = [regions, repmat(regionStr(r), size(comps{r}))]; %#okAGROW
    end
    % make them column vectors for easier filling of EN table at end
    comps = transpose(cell2mat(comps));
    cubesizes = transpose(cell2mat(cubesizes));
    coords = cellfun(@transpose, coords, 'UniformOutput', false);
    coords = transpose(cell2mat(coords));

    % save plots of good ICs
    % TODO: this isn't general use, needs to move to en_entrainment.m
    try
        dtplot(EEG, comps, fullfile(getpath('goodcomps'), [stim,'_',task]));
    catch
        disp('dip and topo plots could not be produced')
    end

    % do fft of all comps
    [yfft, f] = getfft3( ...
        EEG.icaact(comps, :, :), ...
        EEG.srate, ...
        'spectrum',     'amplitude', ...
        'nfft',         nfft, ...
        'detrend',      false, ...
        'wintype',      'hanning', ...
        'ramp',         [], ...
        'dim',          2); % should the the time dimension
    [fftdata, freqs] = noisefloor3(yfft, [2 2], f);

    % en_comps is comps x harms x trials
    en_comps = zeros(length(comps), length(harms), size(EEG.icaact, 3));

    % loop trials and get entrainment for all comps and harms
    for i = 1:size(EEG.icaact, 3)
        en_comps(:, :, i) = getbins3( ...
            fftdata(:, :, i), ...
            freqs, ...
            harms * tempo(i), ...
            'width', binwidth, ...
            'func',  'mean');
    end

    % make en_comps more similar to en_region, like this:
    % en_region: trials x harms x region
    % en_comps:  trials x harms x comps
    en_comps = permute(en_comps, [3 2 1]);

    % make container for comps_ind
    comps_ind = zeros(size(en_region));

    % get max entrainment for each region
    for i = 1:length(regionStr)
        ind = strcmp(regions, regionStr{i}); % inds of comps for this region

        if any(ind)
            % save original indices, because once we use ind and pass it
            %   to the max function, the tmp_ind we get back will be
            %   relative to what was passed to max
            orig_ind = find(ind);

            % tmp/tmp_ind are 1 x harms x trials
            % tmp/tmp_ind are trials x harms (x 1 which used to be comps)
            [tmp, tmp_ind] = max(en_comps(:, :, ind), [], 3);
            tmp_ind = orig_ind(tmp_ind);

        else % if no comps for this region, make all zeros
            tmp = zeros(size(en_region(:, :, 1)));
            tmp_ind = zeros(size(tmp));
            % inds can't be 0, this will be caught when putting vals in EN
        end

        en_region(:, :, i) = tmp;       % trials x harms x region
        comps_ind(:, :, i) = tmp_ind;   % trials x harms x region
    end

else % no comps were found at all
    % these values will put zeros for comp and NaN for cubesize
    % en_region is already defined as all zeros, so entrainment will be 0
    comps = 0;
    cubesizes = NaN;
    coords = [NaN NaN NaN];
    comps_ind = ones(size(en_region));

end

%% make output table
% put vals into EN table
for h = 1:length(harms) % loop harmonics
    trial = transpose(1:size(EEG.icaact, 3)); % number trials sequentially
    harmonic = repmat(harms(h), [size(EEG.icaact, 3), 1]);
    tmp = table(trial, harmonic, 'VariableNames', {'trial', 'harmonic'});

    % add cols for each region for comp, cubesize, and entrainment
    for r = 1:length(regionStr)
        % transpose and squeeze here make sure it's a column
        compname = [regionStr{r}, '_comp'];
        xname    = [regionStr{r}, '_x'];
        yname    = [regionStr{r}, '_y'];
        zname    = [regionStr{r}, '_z'];
        distname = [regionStr{r}, '_distance'];
        if any(comps_ind(:, h, r)) == 0
            % if there were no comps for a region
            tmp.(compname) = zeros(size(EEG.icaact, 3), 1);
            tmp.(xname)    = nan(size(EEG.icaact, 3), 1);
            tmp.(yname)    = nan(size(EEG.icaact, 3), 1);
            tmp.(zname)    = nan(size(EEG.icaact, 3), 1);
            tmp.(distname) = nan(size(EEG.icaact, 3), 1);
        else
            tmp.(compname) = comps(comps_ind(:, h, r));
            tmp.(xname)    = coords(comps_ind(:, h, r), 1);
            tmp.(yname)    = coords(comps_ind(:, h, r), 2);
            tmp.(zname)    = coords(comps_ind(:, h, r), 3);
            tmp.(distname) = cubesizes(comps_ind(:, h, r));
        end
        tmp.(regionStr{r}) = en_region(:, h, r);
    end

    % add to master table
    EN_tmp = tmp;
    if h == 1
        EN = EN_tmp;
    else
        EN = [EN; EN_tmp]; %#ok<AGROW>
    end
end

if ~isempty(filename)
    writetable(EN, filename)
end

end

function [region, regionStr] = parse_region(region)
% input:
%   region = numeric vector or string
%
% output:
%   region = numeric vector of broadmann areas
%
%   regionStr = string of label for region. if input is numeric, this is
%       just that numeric vector converted to a string separated by
%       underscores.
%
% examples:
%   parse_region('aud'):        region    = [22 41 42]
%                               regionStr = 'aud'
%   parse_region([22 41 42]):   region    = [22 41 42]
%                               regionStr = '22_41_42'
%
if ischar(region)
    regionStr = region;
    switch lower(regionStr)
        case 'aud', region = [22 41 42]; % primary auditory
        case 'pmc', region = 6;          % premotor
        case 'mot', region = 4;          % primary motor
        case 'som', region = [1 2 3];    % somatosensory
        case 'pfc', region = [9 46];     % dlpfc, more or less
        case 'ifg', region = 47;         % Vuust2006 polyrhythms;
        case 'b40', region = 40;         % Vuust2006 polyrhythms
        otherwise
            error([region ' is not a valid region string.'])
    end
elseif isnumeric(region)
    regionStr = strrep(num2str(region), ' ', '_');
end
end

