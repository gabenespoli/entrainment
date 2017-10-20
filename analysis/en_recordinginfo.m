function d = phd_recordinginfo
%PHD_RECORDINGINFO  Load phd_recordinginfo.xlsx as a MATLAB table.
fname = '~/Dropbox/research/archive/2017/phd/phd_recordinginfo.xlsx';
[~,~,d] = xlsread(fname);
d = cell2table(d(2:end,:),'VariableNames',d(1,:));

% sort based on id
[~,ind] = sort(d.id);
d = d(ind,:);

end
