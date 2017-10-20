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
stimFilenames = fullfile(stimFolder, {files.name});

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

if nargin > 2
    fid = fopen(trialListFile, 'w');
    fprintf(fid, '%s\n', trialList{:});
    fclose(fid);
end

end
