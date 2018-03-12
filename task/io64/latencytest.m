function [times,triggers] = latencytest(varargin)

% latency test for sending triggers from matlab

% settings
triggers = 0:255;
delay = 0.2; % in seconds
address = 'd050';

% add toolbox to path
% psychtoolboxPath = 'C:\Users\BioSemi111\Documents\MATLAB\Psychtoolbox';
% try
%     addpath(genpath(psychtoolboxPath));
%     disp(['    Added ''',psychtoolboxPath,''' to path.'])
% catch
%     disp(['    Did not add ''',psychtoolboxPath,''' to path.'])
% end

% Run SetupPsychToolbox

% pre-load mex files to avoid latency on first load
GetSecs;
WaitSecs(0.01);

% http://apps.usd.edu/coglab/psyc770/IO64.html
config_io
address = hex2dec(address);

% loop triggers, send them, get the time 
times = zeros(1,length(triggers));
for i = 1:length(triggers)
    outp(address,triggers(i))
    times(i) = GetSecs;
    WaitSecs(delay);
end

end

function config_io
global cogent;
%create IO64 interface object
cogent.io.ioObj = io64();
%install the inpoutx64.dll driver
%status = 0 if installation successful
cogent.io.status = io64(cogent.io.ioObj);
if(cogent.io.status ~= 0), disp('inp/outp installation failed!'), end
end

function [byte] = inp(address)
global cogent;
byte = io64(cogent.io.ioObj,address);
end

function outp(address,byte)
global cogent;
%test for correct number of input arguments
if(nargin ~= 2), error('usage: outp(address,data)'); end
io64(cogent.io.ioObj,address,byte);
end

