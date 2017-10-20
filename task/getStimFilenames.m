function trialList = getStimFilenames(stimFolder, stimType, trialListFile)
% stimFilenames:    Cell array of filenames in randomized order. If certain 
%                   files are to be repeated, they are present multiple times.
%                   If 'currentTime' is given, this list is written to a
%                   trialListFile in the current directory.
%                   
% stimFolder:       String 
% stimType:         'mir' or 'sync'
% trialListFile:    string of file to save the list to

% convert stimFolder to an absolute path
% currentDir = pwd;
% cd(stimFolder)
% stimFolder = pwd;
% cd(currentDir)

% get stimulus filenames
switch stimType
    case 'mir'
        stimFolder = fullfile(stimFolder, 'mir');
        searchStr = fullfile(stimFolder, '*.wav');
    case 'sync'
        stimFolder = fullfile(stimFolder, 'sync');
        searchStr = fullfile(stimFolder, '*.mp3');
    otherwise
        error(['''', stimType, ''' is not a valid stimulus type.'])
end

files = dir(searchStr);
stimFilenames = {files.name};

% remove files starting with a dot
rmind = [];
for i = 1:length(stimFilenames)
    [~,name,~] = fileparts(stimFilenames{i});
    if strcmp(name(1), '.')
        rmind = [rmind, i]; %#ok<AGROW>
    end
end
if ~isempty(rmind)
    stimFilenames(rmind) = [];
end

trialList = stimFilenames(randperm(length(stimFilenames))); % randomize order

% tweak random order so that the sync portcode indicates order
% i.e., stims 101-105 are the same excerpt, so order the files so that
%   the portcode indicates the order of presentation for each unique excerpt
if strcmpi(stimType, 'sync')
    trialList = tweakSyncOrder(trialList);
end

% make absolute path
trialList = fullfile(stimFolder, trialList);

if nargin > 2
    fid = fopen(trialListFile, 'w');
    fprintf(fid, '%s\n', trialList{:});
    fclose(fid);
end

end

function newTrialList = tweakSyncOrder(trialList)

newTrialList = trialList;
allTweakFiles = {...
    '111.mp3', '112.mp3', '113.mp3', '114.mp3', '115.mp3'; ...
    '121.mp3', '122.mp3', '123.mp3', '124.mp3', '125.mp3'; ...
    '131.mp3', '132.mp3', '133.mp3', '134.mp3', '135.mp3'; ...
    '141.mp3', '142.mp3', '143.mp3', '144.mp3', '145.mp3'; ...
    '151.mp3', '152.mp3', '153.mp3', '154.mp3', '155.mp3'; ...
    '161.mp3', '162.mp3', '163.mp3', '164.mp3', '165.mp3'; ...
    };

for i = 1:size(allTweakFiles,1)
    tweakFiles = allTweakFiles(i,:);
    ind = ismember(trialList, tweakFiles);
    newTrialList(ind) = tweakFiles;
end

end
