function en_entrainment_tapping(ids)
% Fitch & Rosenfeld (2007)
%   - align each tap with the closest beat
%   - add nans for missing values
%   - calculate [mean] asynchrony

end


% from @Fitch2007
% The experimental program generated a file with two columns of times for each trial: the “correct” time as predicted by the computer, and the actual time at which the subject tapped. Each tap occupied a single row. The times of participants’ taps were first aligned with the temporally closest computer generated pulse by the analysis software. The algorithm shifted the two data columns relative to each other by adding empty rows until each tap was in the same row as the nearest com- puter pulse. An empty row was left in the column of computer pulses if the subject added an extra pulse, while an empty row was left in the column of subject taps if the subject missed a pulse. Because our interest is in participants’ temporal accuracies for correct notes, these missed and extraneous taps were ignored in the subsequent temporal error analysis. For each tap, the error was calculated by comparing the time of the sub- ject’s tap and the time of the computer generated pulse (see Figure 4), and then took the absolute value of the difference between these two times. This error was normalized across tempos by dividing the observed interpulse interval by the correct interval between pulses, generating an error proportional to the correct local interpulse interval. The errors were then sub- tracted from 1 to convert to normalized accuracy per tap (with 1.0 signifying perfect accuracy). The accuracy per tap was then averaged over the entire trial to gener- ate a mean accuracy per trial for the pulse-tracking task, that was independent across tempos.
% The number of “reset” events in each trial was also tallied as a measure of accuracy. A reset event was scored when a subject’s tap occurred closer in time to the syncopated pulse (the “offbeat”) than to the correct, unsyncopated pulse (the “onbeat”), where the synco- pated pulse falls exactly midway between unsyncopated pulses (Figure 5). After the data had been optimally aligned, the number of reset events as so defined was summed for each trial.
