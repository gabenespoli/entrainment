% latency test for sending triggers from matlab

% settings
triggers = 1:10;
delay = 0.5; % in seconds

% add toolbox to path
psychtoolboxPath = '~/local/matlab/Psychtoolbox';
try
    addpath(genpath(psychtoolboxPath));
    disp(['    Added ''',psychtoolboxPath,''' to path.'])
catch
    disp(['    Did not add ''',psychtoolboxPath,''' to path.'])
end

% pre-load mex files to avoid latency on first load
GetSecs;
WaitSecs(0.01);

% http://apps.usd.edu/coglab/psyc770/IO64.html
ioObj = io64; % create an instance of the io64 object
status = io64(ioObj); % initialize the interface to the inpoutx64 system driver
if status, error('io64 could not initialize.'), end
address = hex2dec('d050');

% loop triggers, send them, get the time 
times = zeros(1,length(triggers));
for trigger = triggers
    io64(ioObj,address,trigger); % send trigger (set value on port)
    times(i) = GetSecs;
    WaitSecs(delay);
end

%data_in = io64(ioObj,address); % read data from parallel port
