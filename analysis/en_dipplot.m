function en_dipplot(EEG, comps)

dipdir = fullfile('~','local','matlab','eeglab','plugins','dipfit2.3');
mrifile  = fullfile(dipdir, 'standard_BESA', 'avg152t1.mat');
pop_dipplot(EEG, comps, ...
            'mri',          mrifile, ...
            'projlines',    'on', ...
            'normlen',      'on');

        
sources = dipplot(EEG.dipfit.model, ...
            'mri',          mrifile, ...
            'normlen',      'on', ...
            'plot',         'off');
              
coords = [sources(comps).talcoord];
coords = reshape(coords, 3, length(coords) / 3)';
if length(comps) ~= size(coords, 1), error('Something''s wrong.'), end
region = tal2region(coords, 5);

for i = 1:length(comps)
    if ~isempty(region.cellType{i})
        str = strcat(region.cellType{i}{:});
    else
        str = '';
    end
    fprintf('Comp %i: %s\n', comps(i), str)
end
        
end
