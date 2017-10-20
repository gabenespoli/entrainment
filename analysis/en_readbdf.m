function EEG = gv_readbdf(filename,varargin)
%EG_BDF  Load a BDF file, add channel labels and locations, trim data,
%   save as EEGLAB set file.
% 
% USAGE
%   EEG = eg_bdf(filename)
%   EEG = eg_bdf(filename,'Param1','Value1',etc.)
%
% INPUT
%   filename        = Filename and path of the raw EEG file to
%                             preprocess. Should be a .bdf file.
% 
%   'raw'           = Folder where FILENAME can be found. 
%                     Default is the current folder or the 
%                     path given in FILENAME.
% 
%   'chanlocs'      = Filename and path to the channel locations
%                     file. Default is '/standard-10-5-cap385.elp'.
%
%   'rmchans'       = Channels to remove. Useful if some eye
%                     channels were not used, or some channels were
%                     noisy.
%
%   'trim'          = Number of seconds on either side of first 
%                     and last port code to trim. Default none ([];
%                     (include all data).
%
%   'ref'           = Channel indices for rereferencing. Default
%                     none.
%
%   'eventchans'    = Channel number where event markers are.
% 
% See also pop_readbdf, pop_chanedit, pop_select, eeg_eegrej, pop_reref
% 
% Written by Gabriel A. Nespoli 2016-01-19. Revised 2016-04-12.

% parse filename
if mod(nargin,2) == 0, error('Incorrect parameter/value pairs.'), end
[rawFolder,name,ext] = fileparts(filename);
if isempty(ext), ext = '.bdf'; end

% defaults
ref = 'none'; % [] = avg ref
chanlocs = getfolder('resources','/chanlocs/standard-10-5-cap385.elp');
rmchans = {'EXG7' 'EXG8'};
trim = []; % in seconds
eventchans = 73; % 64-chans: 73; 128-chans: 

% user-defined
for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case {'raw','rawfolder'},       rawFolder = varargin{i+1};
        case 'ref',                     ref = varargin{i+1};
        case 'chanlocs',                chanlocs = varargin{i+1};
        case 'rmchans',                 rmchans = varargin{i+1};
        case 'trim',                    trim = varargin{i+1};
        case 'eventchans',              eventchans = vararig{i+1};
    end
end

% check input
if ~exist(chanlocs,'file'), error('Cannot find specified channel locations file.'), end

% 1. load file
disp('Reading bdf file...')
    % pop_readbdf(filename,range,eventchans,ref)
EEG = pop_readbdf(fullfile(rawFolder,[name,ext]),[],eventchans,[]);
EEG.setname = name;

% 2. channel labels and locations
disp('Adding channel labels and locations...')
EEG = pop_chanedit(EEG,...
    'changefield',{65 'labels' 'M1' },...
    'changefield',{66 'labels' 'M2' },...
    'changefield',{67 'labels' 'LO1'},...
    'changefield',{68 'labels' 'LO2'},...
    'changefield',{69 'labels' 'IO1'},...
    'changefield',{70 'labels' 'IO2'},...
    'lookup',chanlocs);

if ~isempty(rmchans)
    EEG = pop_select(EEG,'nochannel',rmchans); end

% 3. trim recording
if ~isempty(trim)
    recStart = [];
    recEnd = [];
    
    if EEG.event(1).latency - trim * EEG.srate > 1
        recStart =  [1 EEG.event(1).latency - trim * EEG.srate]; end
    
    if EEG.event(end).latency + trim * EEG.srate < length(EEG.times)
        recEnd = [EEG.event(end).latency + trim * EEG.srate length(EEG.times)]; end
    
    if ~isempty(recStart) || ~isempty(recEnd)
        EEG = eeg_eegrej(EEG,[recStart; recEnd]);
    end
end

% 4. rereference
if isnumeric(ref)
    EEG = pop_reref(EEG,ref);
elseif ischar(ref) && strcmpi(ref,'avg')
    EEG.data = bsxfun(@minus,EEG.data,sum(EEG.data,1) / (EEG.nbchan + 1)); % explanation below
end

end

% from http://sccn.ucsd.edu/wiki/Makoto's_preprocessing_pipeline#Run_ICA
% 2016-06-21
% 
% What is rank? Usually, the number of data rank is the same as the number of
% channels. However, if a pair of channels are bridged, the rank of the data is
% the number of channels-1. For another example, a pair of equations, 2x+3y+4=0
% and 3x+2y+5=0 have rank of 2, but another pair 2x+3y+4=0 and 4x+6y+8=0 have
% rank of 1 for the two equations are dependent (the latter is exact twice of
% the former). EEG data consist of n+1 channels; n probes and 1 reference. The
% n+1 channel data have rank n because the reference channel data are all zeros
% and rank deficient. Usually, this reference channel is regarded as useless and
% excluded for plotting, which is why you usually find your data to have n
% channels with rank n (i.e. full ranked). It is important that when you perform
% ICA, you apply it to full-ranked data, otherwise strange things can happen
% (see below). Your data are usually full-ranked in this way and ready for ICA.
% When you apply average reference, you need to put the reference channel back
% if it is missing (which is usually the case). You can include the reference
% channel in computing average reference by selecting the 'Add current reference
% back to the data' option in the re-reference GUI. If you do not have initial
% reference channel location, in theory you should generate a zero-filled
% channel and concatenate it to your EEG data matrix as an extra channel (which
% makes the data rank-deficient) and perform average reference. To make the data
% full-ranked again, one may (a) drop a channel--choosing the reference channel
% is reasonable (b) reduce the dimensionality by using a PCA option for ICA. To
% perform the abovementioned process on the command line, one can manually
% compute average reference using adjusted denominator: EEG.data = bsxfun(
% @minus, EEG.data, sum( EEG.data, 1 ) / ( EEG.nbchan + 1 ) );
