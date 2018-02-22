function showProgress(trial, nTrials)

widthFactor = 2;
current = trial * widthFactor;
total = nTrials * widthFactor;

doneStr = repmat('=', 1, current);
emptyStr = repmat(' ', 1, total - current);
pct = num2str(round((trial / nTrials) * 100));

str = ['Progress: [', doneStr, emptyStr, '] ', pct, '%%\n'];

fprintf(str)

end
