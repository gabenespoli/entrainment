function move = playTrial(fname, stimType, ioObj, address)

likertRange= 1:7; % Witek2014 used 5-point likert; Janata2012 used 7-point

if nargin > 1, stimType = 'sync'; end
if strcmp(stimType, 'mir'),         rhythmWord = 'beat';
elseif strcmp(stimType, 'sync'),    rhythmWord = 'rhythm';
end

% this question from Witek2014 (with 'rhythm' as the rhythmWord)
moveQuestion = ['To what extent does this ', rhythmWord, ...
                ' make you want to move?'];

audioObj = loadAudio(fname);
portcode = getPortcode(fname);
fprintf('Press enter to play the trial.\n')
pause

fprintf('\nPlaying... ')
io64(ioObj, address, portcode); % send portcode
playblocking(audioObj)
fprintf('Done.\n')

move = getLikertResponse(moveQuestion, likertRange);

end

function audioObj = loadAudio(fname)
fprintf('Loading file... ')
[y, Fs] = audioread(fname);
audioObj = audioplayer(y, Fs);
fprintf('Done.\n\n')
end

function portcode = getPortcode(fname)
% getPorcode: function to get a portcode for a stimulus filename
% portcode = getPortcode(fname) 
% fname: [string] absolute or local path to a file. Filename should be a number
%           e.g. '1.mp3' or '01.wav'
% If the filename is not a number, the portcode 255 is returned.
[~,name,~] = fileparts(fname);
try
    portcode = str2num(name);
catch, me
    portcode = 255;
end
end

function resp = getLikertResponse(question, likert)
likertFormat = repmat('\t%i',[1,size(likert)]);
fprintf('\n')
fprintf('%s\n', question)
fprintf('\n')
fprintf(likertFormat, likert);
fprintf('\n')
fprintf('\n')
resp = nan;
while ~ismember(resp, likert)
    try
        resp = input('Response: ');
    catch, me
    end
end
end

