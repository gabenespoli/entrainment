% getPorcode: function to get a portcode for a stimulus filename
% portcode = getPortcode(fname) 
% fname: [string] absolute or local path to a file. Filename should be a number
%           e.g. '1.mp3' or '01.wav'
% If the filename is not a number, the portcode 255 is returned.

function portcode = getPortcode(fname)
[~,name,~] = fileparts(fname);

try
    portcode = str2num(name);

catch, me
    portcode = 255;

end

end
