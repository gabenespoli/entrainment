% getPorcode: function to get a portcode for a stimulus filename
%
% USAGE: portcode = getPortcode(fname, stimType) fname: [string] absolute or local path to a file. filename should be a number
%           e.g. '1.mp3' or '01.wav'
% stimType: either 'mir' or 'sync'
%
% The portcode comprises either 1 (mir) or 2 (sync) and then the filename number.
% This means that filenames must be a number and in the range 1-99.
% If the filename is not a number, the portcode 255 is returned.

function portcode = getPortcode(fname)
[~,name,~] = fileparts(fname);

try
    portcode = str2num(name);

catch, me
    portcode = 255;

end

end
