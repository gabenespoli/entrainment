function EEG = en_dipfit(EEG, chans, rv, hc)
% rv = residual variance in percent. default 15.
% hc = head circumference in cm, from which to calculate the radius.
%   default is empty ([]), which uses autofit instead of manual grid search
%   and interactive fine fit. I think this uses a radius of 85
%   (circumference of about 53.4).

% TODO: get voxel size of dipole model, save it somewhere

if nargin < 2 || isempty(chans)
    chans = 1:size(EEG.icaact,1);
end
if nargin < 3 || isempty(rv)
    rv = 40;
end
if nargin < 4 || isempty(hc)
    hr = []; % leave empty for autofit
else
    hr = hc / pi / 2 * 10;
end

% coord_transform was obtained in the following way:
%   - load an EEG struct from this study
%   - Tools > Dipfit > Head model and settings from the EEGLAB gui
%   - Select Boundary MNI model
%   - Select manual co-reg
%   - Select warp montage
%   - Press ok
%   - copy coord_transform from the text box

EEG = pop_dipfit_settings(EEG, ...
    'coordformat',      'MNI', ...
    'hdmfile',          getpath('hdmfile'), ...
    'mrifile',          getpath('mrifile'), ...
    'chanfile',         getpath('chanfile'), ...
    'coord_transform',  [0.7743 -15.9248 2.61177 0.0845758 0.00105183 -1.57215 1.18029 1.07178 1.14575], ...
    'chansel',          chans);

if isempty(hr)
    % auto fit (coarse grid scan, then auto fine fit)
    EEG = pop_multifit(EEG, ...
        chans, ...
        'threshold', rv, ...
        'plotopt', {'normlen' 'on'});

else
    % grid scan
    EEG = pop_dipfit_gridsearch(EEG, ...
        chans, ...
        linspace(-hr, hr, 11), ...
        linspace(-hr, hr, 11), ...
        linspace(0, hr, 6), ...
        rv / 100);

    warning('Not doing any fine dipole fitting. Please do this manually.')
    % pop_autofit?
    % I don't think there's an automated way to fine fit while also including a custom hr
    % check https://sccn.ucsd.edu/wiki/A08:_DIPFIT#Interactive_fine-grained_fitting

end
