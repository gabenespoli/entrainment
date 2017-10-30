function [move, pleasure] = playTrial(fname, stimType, trigType, ioObj, address)
%% prepare questions
% Witek2014 used 5-point likert; Janata2011 used 7-point
likert= 1:7;

if nargin > 1, stimType = 'sync'; end
if strcmp(stimType, 'mir'),         rhythmWord = 'beat';
elseif strcmp(stimType, 'sync'),    rhythmWord = 'rhythm';
end

% these questions from Witek2014 (with 'rhythm' as the rhythmWord)
moveQuestion = ['To what extent does this ', rhythmWord, ' make you want to move?'];
% pleasureQuestion = ['How much pleasure do you experience listening to this ', rhythmWord, '?'];

%% play audio
playAudio(fname, trigType, ioObj, address)
move = getLikertResponse(moveQuestion, likert);
% pleasure = getLikertResponse(pleasureQuestion, likert);
pleasure = NaN;

end

function playAudio(fname, trigType, ioObj, address)
fprintf('Loading file... ')
[y, Fs] = audioread(fname);
obj = audioplayer(y, Fs);
fprintf('Done.\n\n')

fprintf('Press enter to play the trial.\n')
pause
fprintf('\nPlaying... ')

if strcmpi(trigType, 'eeg')
    portcode = getPortcode(fname);
    io64(ioObj, address, portcode); % send portcode
    playblocking(obj)
    % sendPortcode(code) % TODO send portcode at end of trial?
else
    playblocking(obj)
end

fprintf('Done.\n')
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
