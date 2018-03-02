function [freqs, vals] = en_freq(EEG, comp)

addpath(fullfile('~','bin','matlab','utils','dsp'))
do_evoked = true;
freqFactor = 1;

% get freqs
bpm = [EEG.urevent.type]';
freqs = (bpm / 60) * freqFactor;

% get data
data = squeeze(EEG.icaact(comp, :, :)); % data is time x trial
if do_evoked, [data, freqs] = makeEvoked(data, freqs); end
[yfft, f] = getfft(data, EEG.srate, 2^14);
vals = binmean(yfft, f, freqs, 0);

% avg duplicate freqs
cats = unique(freqs);
newvals = nan(length(freqs), 1);
for i = 1:length(cats)
    ind = freqs == cats(i);
    newvals(i) = mean(vals(ind));
end
vals = newvals;
freqs = cats;

% sort by freq
[freqs,ind] = sort(freqs);
vals = vals(ind);

% plot
plot(freqs * 60, vals, 'o')
lsline
set(gca, 'fontsize', 16)
xlabel('Frequency (bpm)')
ylabel('Entrainment')
if do_evoked
    plottitle = 'Evoked';
else
    plottitle = 'Induced';
end
[rho, pval] = corr(freqs, vals);
rho = num2str(round(rho, 3));
pval = num2str(round(pval, 3));

plottitle = [plottitle, ...
             ' (IC ', num2str(comp), ')', ...
             ' (r = ', rho, ', p = ', pval, ')'];


title(plottitle);

end

function [evoked, cats] = makeEvoked(data, freqs)
cats = unique(freqs);
evoked = nan(size(data,1), length(cats));
for i = 1:length(cats)
    ind = freqs == cats(i);
    evoked(:, i) = mean(data(:, ind), 2);
end
end

function ind=getind(x,val)
% GETIND  Get indices of closest values.
%   IND = GETIND(X,VAL) searches in X for the closest values of VAL, and
%         returns the indices of these values.
ind = nan(length(val), 1);
for i = 1:length(val)
    [~, ind(i)]=min(abs(x - val(i) ));
end
end
