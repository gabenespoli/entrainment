function en_dipplot(EEG, comps)

pop_dipplot(EEG, ...
    comps, ...
    'mri',          en_getpath('mrifile'), ...
    'projlines',    'on', ...
    'normlen',      'on');
        

% get dipole info struct

% sources = dipplot(EEG.dipfit.model, ...
%     'mri',          en_getpath('mrifile'), ...
%     'coordformat',  'MNI', ...
%     'normlen',      'on', ...
%     'plot',         'off');
              
% TODO sources is only as big as the number of comps with good rv
%   comps is the number of the comp
%   need to get indices of comps in sources
% coords = [sources(comps).talcoord];
% coords = reshape(coords, 3, length(coords) / 3)';
% if length(comps) ~= size(coords, 1), error('Something''s wrong.'), end
% region = tal2region(coords, 5);

% for i = 1:length(comps)
%     if ~isempty(region.cellType{i})
%         str = strcat(region.cellType{i}{:});
%     else
%         str = '';
%     end
%     fprintf('Comp %i: %s\n', comps(i), str)
% end
        
end
