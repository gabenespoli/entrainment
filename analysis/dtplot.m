%% dtplot
%   EEGLAB wrapper function to plot topographic maps and dipoles side by
%   side. Specify a folder if you want to save the plots instead.
%
% Usage:
%   dtplot(EEG, comps)
%   dtplot(EEG, comps, savedir)
%   [topofig, dipfig] = dtplot(...)
%
% Input:
%   EEG = EEGLAB structure with ICA and dipole fitting information.
%
%   comps = [numeric] List of component numbers to plot.
%
%   savedir = [string] Folder to save plots. If empty (''), plots are
%       displayed and not saved. Otherwise plots are saved as both a .fig
%       and a .png.
%
% Output:
%   topofig = Figure handle for the topoplot.
%
%   dipfig = Figure handle for the dipplot.

function varargout = dtplot(EEG, comps, savedir)
if nargin < 3, savedir = ''; end

%% topoplot
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

if isempty(savedir)
    % arrange figures so they aren't overlapping
    topofig.Position(1) = topofig.Position(1) - topofig.Position(3) / 2;
else
    % save figures instead of plotting them
    print(fullfile(savedir,   [EEG.setname, '_topoplot.png']), '-dpng')
    close(topofig)
end

%% dipplot
pop_dipplot(EEG, ...
    comps, ...
    'mri',          en_getpath('mrifile'), ...
    'projlines',    'on', ...
    'view',         [0.5 -0.5 0.5], ...
    'normlen',      'on');
dipfig = gcf;

if isempty(savedir)
    % arrange figures so they aren't overlapping
    dipfig.Position(1) = dipfig.Position(1) + dipfig.Position(3) / 2;
else
    % save figures instead of plotting them
    print(fullfile(savedir,   [EEG.setname, '_dipplot.png']), '-dpng')
    close(dipfig)
end

%% output figure handles
if nargout > 0
    varargout{1} = topofig;
end
if nargout > 1
    varargout{2} = dipfig;
end

end
