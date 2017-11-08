function trialList = getTrialList(stimFolder, stimType, trialListFile, stimExt)
% trialList:        Cell array of filenames in randomized order. If certain 
%                   files are to be repeated, they are present multiple times.
%                   If 'currentTime' is given, this list is written to a
%                   trialListFile in the current directory.
%                   
% stimFolder:       String 
% stimType:         'mir' or 'sync'
% trialListFile:    string of file to save the list to

% filenames
%   mir         tempo       sync
%   101-130      90         11-16
%   131-160      96         21-26
%   161-190      102        31-36
%   191-220      108        41-46
%   221-250      114        51-56

if nargin < 3 || isempty(trialListFile)
    trialListFile = ['trialList_', datestr(now, 'yyyy-mm-dd_HH-MM-SS')];
end
if nargin < 4
    stimExt = '.wav';
end

%% add tempo jitter
switch lower(stimType)
    case 'mir'
        jitter = randi(5, 30, 1);
        jitter = jitter * 30 + 70;
        trialList = transpose(1:30);
        trialList = trialList + jitter;

    case 'sync'
        jitter = randi(5, 30, 1);
        jitter = jitter * 10;
        trialList = repmat([1 2 3 4 5 6]', 5, 1);
        trialList = trialList + jitter;

end

%% make filenames
trialList = cellfun(@num2str, num2cell(trialList), 'UniformOutput', false);
trialList = cellfun(@(x) fullfile(stimFolder, [x, stimExt]), trialList, 'UniformOutput', false);

%% randomize order
trialList = trialList(randperm(length(trialList)));

%% write trial list to file
fid = fopen(trialListFile, 'w');
fprintf(fid, '%s\n', trialList{:});
fclose(fid);

end
