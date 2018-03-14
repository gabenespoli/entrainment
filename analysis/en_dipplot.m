%% en_dipplot
%   Plot a topographic maps and dipoles.

function varargout = en_dipplot(EEG, comps)

if length(comps) == 1
    topofig = figure; axis;
end
pop_topoplot(EEG, ...
     0, ...                     % 0 for comps, 1 for chans
     comps, ...                 % comps/chans to plot
     ['id ', EEG.setname], ...  % plot title
     0, ...                     % rows/cols per page (0 = near square)
     1, ...                     % plot dipoles too
     'electrodes', 'off');
if length(comps) > 1
    topofig = gcf;
end

pop_dipplot(EEG, ...
    comps, ...
    'mri',          en_getpath('mrifile'), ...
    'projlines',    'on', ...
    'view',         [0.5 -0.5 0.5], ...
    'normlen',      'on');
dipfig = gcf;

% arrange figures so they aren't overlapping
topofig.Position(1) = topofig.Position(1) - topofig.Position(3) / 2;
dipfig.Position(1) = dipfig.Position(1) + dipfig.Position(3) / 2;

if nargout > 0
    varargout{1} = topofig;
end
if nargout > 1
    varargout{2} = dipfig;
end

end
