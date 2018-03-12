%% Average Reference for full-ranked data
% This method for average referencing was taken from Makoto's EEG
% processing pipeline (link below). The explanation of this formula by
% Andreas Widmann from that link is copied here for posterity:
%
% What is rank? Usually, the number of data rank is the same as the number
% of channels. However, if a pair of channels are bridged, the rank of the
% data is the number of channels-1. For another example, a pair of
% equations, 2x+3y+4=0 and 3x+2y+5=0 have rank of 2, but another pair
% 2x+3y+4=0 and 4x+6y+8=0 have rank of 1 for the two equations are
% dependent (the latter is exact twice of the former).
%
% EEG data consist of n+1 channels; n probes and 1 reference. The n+1
% channel data have rank n because the reference channel data are all
% zeros and rank deficient. Usually, this reference channel is regarded
% as useless and excluded for plotting, which is why you usually find
% your data to have n channels with rank n (i.e. full ranked). It is
% important that when you perform ICA, you apply it to full-ranked data,
% otherwise strange things can happen (see below). Your data are usually
% full-ranked in this way and ready for ICA.
% 
% When you apply average reference, you need to put the reference channel
% back if it is missing (which is usually the case). You can include the
% reference channel in computing average reference by selecting the 'Add
% current reference back to the data' option in the re-reference GUI. If
% you do not have initial reference channel location, in theory you should
% generate a zero-filled channel and concatenate it to your EEG data matrix
% as an extra channel (which makes the data rank-deficient) and perform
% average reference. To make the data full-ranked again, one may (a) drop a
% channel--choosing the reference channel is reasonable (b) reduce the
% dimensionality by using a PCA option for ICA.
%
% To perform the abovementioned process on the command line, one can
% manually compute average reference using adjusted denominator:
% EEG.data = bsxfun( @minus, EEG.data, sum( EEG.data, 1 ) / ( EEG.nbchan + 1 ) );
%
% Link to Makoto's pipeline:
% https://sccn.ucsd.edu/wiki/Makoto's_preprocessing_pipeline#Re-reference_the_data_to_average_.2811.2F29.2F2017_updated.29

function data = averageReference(data)
% data should be chan x time x epochs
data = bsxfun(@minus, data, sum(data,1) / (size(data,1) + 1));
end
