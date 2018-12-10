%BARPLOT  Plots a bar graph with standard error bars from a table variable
%   and corresponding grouping variable.
% 
% Usage:
%   [y, stdError] = barplot(d, grpVar, datVar)
%   [y, stdError] = barplot(d, grpVar, datVar, 'Param1', Value1, etc.)
% 
% INPUT
%   d             = [table] Data to average and plot.
%   grpVar        = [string] Variable to group data (each bar will be a 
%                   unique value from this variable.
%   datVar        = [string] Variable to plot on y-axis (value for height 
%                   of each bar).
%   'spec'        = [cell of strings]
%   'order'       = [numeric]
%   'labels'      = [cell of strings] Should be the desired order as 
%                   specified in 'order', not the current order of items in
%                   the dataset.
%   'fontsize'    = [numeric length 1]
%   'title'       = [string]
%   'xtitle'      = [string]
%   'ytitle'      = [string]
%   'ylim'        = [numeric length 2]
%   'pretty'      = [boolean] Makes plot look nicer for presentations. 
%                   Default true.
%   'rmnan'       = [boolean] If true removes nans before averaging.
%                   Default true.
%   'rmzeros'     = [boolean] If true removes zeros before averaging.
%                   Default false.
%   'sigstar'     = [cell] Args to pass to sigstar.m.
%   'save'        = [string|cell of strings] Filename(s) to save the plot.
%   'ax'          = [axis handle] Axis handle to plot onto.
%   'fig'         = [figure handle] Figure handle to plot into.
% 
% OUTPUT
%   y             = [numeric] Value of each bar (means).
%   stdError      = [numeric] Standard error of each mean.
%   h             = [axis handle]
% 
% Written by Gabriel A. Nespoli 2016-05-01. Revised 2018-05-29.

function varargout = barplot(d, grpVar, datVar, varargin)

ax = [];
fig = [];

plotSpec = '';
plotOrder = [];
fontsize = 14;

plotTitle = '';
xtitle = grpVar;
ytitle = datVar;

yl = [];

pretty = true;
rmnans = true;
rmzeros = false;

sigstarVars = {};

filename = '';

labels = '';
plotnum = [];

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case {'plotspec','spec','color'},   plotSpec = varargin{i+1};
        case {'plotorder','order'},         plotOrder = varargin{i+1};
        case 'fontsize',                    fontsize = varargin{i+1};
        case {'title','plottitle'},         plotTitle = varargin{i+1};
        case {'xtitle','xlabel'},           xtitle = varargin{i+1};
        case {'ytitle','ylabel'},           ytitle = varargin{i+1};
        case {'ylim','yl'},                 yl = varargin{i+1};
        case 'pretty',                      pretty = varargin{i+1};
        case 'rmnans',                      rmnans = varargin{i+1};
        case 'rmzeros',                     rmzeros = varargin{i+1};
        case 'sigstar',                     sigstarVars = varargin{i+1};
        case {'save','filename'},           filename = varargin{i+1};
        case 'labels',                      labels = varargin{i+1};
        case 'ax',                          ax = varargin{i+1};
        case 'fig',                         fig = varargin{i+1};
        case 'plotnum',                     plotnum = varargin{i+1};
        otherwise, disp(['Unknown parameter ',varargin{i}])
    end
    
end

if ~iscategorical(d.(grpVar)), d.(grpVar) = categorical(d.(grpVar)); end
labels = unique(d.(grpVar));
if isempty(labels), labels = labels; end

y = nan(1,length(labels));
stdError = nan(size(y));

plotOrder = getPlotOrder(d,plotOrder,length(labels));
labels = labels(plotOrder);
plotSpec = getPlotSpec(d,plotSpec,length(labels));

%figure
if isempty(fig), fig = figure; end
if isempty(ax), ax = gca; end
for i = 1:length(labels)

    ind = d.(grpVar) == labels(i); % get indices of grpvar to average for current bar
    temp = d.(datVar)(ind); % get values to average for current bar

    if rmnans, temp(isnan(temp)) = []; end
    if rmzeros, temp(temp == 0) = []; end

    stdError(i) = ste(temp);
    y(i) = mean(temp);

    h = bar(ax, i, y(i)); % plot the current bar
    if i == 1, hold on, end

    if ~isempty(plotSpec{i})
        if isnumeric(plotSpec{i})
            set(h,'FaceColor',plotSpec{i})

        elseif ischar(plotSpec{i})
            set(h,'FaceColor',plotSpec{i}(1))

            if length(plotSpec{i}) > 2 && strcmp(plotSpec{i}(2:3),'--')
                currentColor = get(h,'FaceColor') + 0.8;
                currentColor(currentColor > 1) = 1;
                set(h,'FaceColor',currentColor)

            elseif length(plotSpec{i}) > 1 && strcmp(plotSpec{i}(2),'-')
                currentColor = get(h,'FaceColor') + 0.5;
                currentColor(currentColor > 1) = 1;
                set(h,'FaceColor',currentColor)
            end
        end
    end
end

% labels and errorbars
set(ax,'XTick',1:length(labels),'XTickLabel',cellstr(labels))
errorbar(ax,1:length(labels),y,stdError,'.k');

if ~isempty(sigstarVars)
    if islogical(sigstarVars) && sigstarVars
        pairs = cell(size(labels));
        pvals = nan(size(labels));
        for i = 1:length(labels)
            ind1 = i;
            if i == length(labels), ind2 = 1; else, ind2 = i+1; end
            pairs{i} = [ind1 ind2];
            cat1 = labels(ind1);
            cat2 = labels(ind2);
            data1 = d.(datVar)(d.(grpVar)==cat1);
            data2 = d.(datVar)(d.(grpVar)==cat2);
            [~, pvals(i)] = ttest2(data1, data2);
        end
        sigstarVars = {pairs pvals [] fontsize};

    elseif length(sigstarVars) < 2
        sigstarVars = {sigstarVars{1} [] [] fontsize};
    elseif length(sigstarVars) < 3
        sigstarVars = {sigstarVars{1} sigstarVars{2} [] fontsize};
    elseif length(sigstarVars) < 4
        sigstarVars = {sigstarVars{1} sigstarVars{2} sigstarVars{3} fontsize};
    end

    sigstar(sigstarVars{:})
end

[xtitle,ytitle] = getTitles(d,grpVar,xtitle,datVar,ytitle);

xlabel(xtitle)
ylabel(ytitle)
title(plotTitle)
doPlotNum(plotnum)
set(ax,'FontSize',fontsize)

if ~isempty(yl) && isnumeric(yl) && length(yl) == 2
    ylim(yl)
end

if pretty
    set(ax,'box','off')
    set(fig,'color','w')
end

if ~isempty(filename)
    filename = cellstr(filename);
    for i = 1:length(filename)
        [~, ~, ext] = fileparts(filename{i});
        if strcmpi(ext, '.png')
            print(filename{i}, '-dpng')
        else
            savefig(filename{i})
        end
    end
end

if nargout > 0
    varargout{1} = y;
    varargout{2} = stdError;
    varargout{3} = h;
end

end

function [xtitle,ytitle] = getTitles(d,grpVar,xtitle,datVar,ytitle)
grpVarInd = ismember(d.Properties.VariableNames,grpVar); % xtitle
if ~isempty(d.Properties.VariableDescriptions) && ~isempty(d.Properties.VariableDescriptions{grpVarInd})
    xtitle = d.Properties.VariableDescriptions{grpVarInd}; end
if ~isempty(d.Properties.VariableUnits) && ~isempty(d.Properties.VariableUnits{grpVarInd})
    xtitle = [xtitle,' (',d.Properties.VariableUnits{grpVarInd},')']; end

datVarInd = ismember(d.Properties.VariableNames,datVar); % ytitle
if ~isempty(d.Properties.VariableDescriptions) && ~isempty(d.Properties.VariableDescriptions{datVarInd})
    ytitle = d.Properties.VariableDescriptions{datVarInd}; end
if ~isempty(d.Properties.VariableUnits) && ~isempty(d.Properties.VariableUnits{datVarInd})
    ytitle = [ytitle,' (',d.Properties.VariableUnits{datVarInd},')']; end
end

function plotOrder = getPlotOrder(d,plotOrder,n)
if isempty(plotOrder)...
        && isstruct(d.Properties.UserData)...
        && ismember('plotOrder',fieldnames(d.Properties.UserData))...
        && ~isempty(d.Properties.UserData.plotOrder)
    plotOrder = d.Properties.UserData.plotOrder;
else
    plotOrder = 1:n;
end
if length(plotOrder) ~= n
    disp('Ignoring plotOrder; it was the incorrect length.')
    plotOrder = 1:n;
end
end

function plotSpec = getPlotSpec(d,plotSpec,n)
if isempty(plotSpec)...
        && isstruct(d.Properties.UserData)...
        && ismember('plotSpec',fieldnames(d.Properties.UserData))...
        && ~isempty(d.Properties.UserData.plotSpec)
    plotSpec = fixPlotSpec(d.Properties.UserData.plotSpec,n);
else
    plotSpec = fixPlotSpec(plotSpec,n);
end
end

function plotSpec = fixPlotSpec(plotSpec,n)
resetSpec = false;
if isnumeric(plotSpec), plotSpec = {plotSpec};
elseif ischar(plotSpec), plotSpec = cellstr(plotSpec);
end
if length(plotSpec) == 1 && isempty(plotSpec{1})
    resetSpec = true;
elseif length(plotSpec) == 1
    for i = 1:n, plotSpec{i} = plotSpec{1}; end
elseif length(plotSpec) ~= n
    warning('Ignoring lineSpec because there was a problem.')
    resetSpec = true;
end
if resetSpec, for i = 1:n, plotSpec{i} = ''; end, end
end

function doPlotNum(plotnum)
if isempty(plotnum), return, end
if ~iscell(plotnum) || length(plotnum) < 3
    warning('Problem with PLOTNUM. Not numbering plot')
    return
end
text(plotnum{1},plotnum{2},plotnum{3}, plotnum{4:end})
end

function y = ste(x), y = std(x) / sqrt(length(x)); end

