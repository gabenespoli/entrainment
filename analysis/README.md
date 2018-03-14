# en/analysis

## Running the Pipeline

The following code will run the entire EEG analysis pipeline from raw BDF files to a tabular data frame of entrainment values.

```matlab
% make sure paths in en_getpath are correct
% set current folder to this folder
ids = 6:16;
en_load('eeglab')
en_loop_eeg_preprocess(ids);
% look at topographical maps saved in en_getpath('topoplots') and mark down component numbers that are dipolar in en_diary.csv
en_loop_eeg_entrainment(ids);

% more to come...
```

## List of Functions

### Project Macros

These functions are used for performing a whole section of the analysis pipeline and batch processing. They mostly contain calls to the other functions in the lists below.

- `en_eeg_preprocess`: A macro that runs `en_readbdf` and a number of [EEGLAB](https://sccn.ucsd.edu/eeglab/index.php) functions to pre-process EEG data, including ICA and dipole fitting. Resultant .set files are saved to `en_getpath('eeg')`.

- `en_loop_eeg_preprocess`: Loops through the specified IDs and runs `en_eeg_preprocess`. All output from the command window is captured for each ID and saved to `en_getpath('eeg')`, as well as a summary file with processing times and any errors for each ID.

- `en_eeg_entrainment`: A macro that takes an ID or EEGLAB struct and outputs a table of entrainment values for each trial. Resultant tables are saved as .csv files in `en_getpath('eeg_entrainment')`.

`en_loop_eeg_entrainment`: Loops through specified IDs and runs `en_eeg_entrainment`.

### Project Utilities

These functions simplify finding and loading files.

`en_getpath`: Takes a keyword as input and returns a directory or file path. All functions in this "toolbox" use this function to get path names. This means that you can move these scripts to a different computer or port them to a different project, and will only have to change this file in order for everything to work (theoretically).

`en_load`: Takes a keyword (and optionally an ID number), and loads the specified file into the MATLAB workspace. Can also start [EEGLAB](https://sccn.ucsd.edu/eeglab/index.php) from the path specified in `en_getpath('eeglab')`.

### Project EEG Analysis

These include wrappers on EEGLAB functions (mostly EEG preprocessing) and custom scripts for spectral analyses.

`en_readbdf`: Takes an ID number as input, gets their .bdf filenames from `en_diary.csv`, and reads those files into an [EEGLAB](https://sccn.ucsd.edu/eeglab/index.php) .set file (if there are multiple .bdf files, they are merged). It also converts the channel labels from the BioSemi alphabetical labels into [Oostenveld](http://robertoostenveld.nl/electrode/)'s 10-5 system.

`en_epoch`: Epochs an EEG struct using [EEGLAB](https://sccn.ucsd.edu/eeglab/index.php) based on portcodes which are specified with keywords. This function in particular is highly specialized for the current study, and will require lots of editing to work for a different study.

`en_dipfit`: Wrapper on [EEGLAB](https://sccn.ucsd.edu/eeglab/index.php) functions for dipole fitting using the Boundary Element Model (BEM).

### General EEG Analysis

Some EEG-related functions for preprocessing and spectral analysis that will work outside of this project.

`alpha2fivepct`: Takes an EEG struct or a cell of strings, and remaps channel labels from BioSemi alphabetical labels to [Oostenveld](http://robertoostenveld.nl/electrode/)'s 10-5 system.

`averageReference`: Performs average referencing for fully-ranked data on an EEG struct.

`tal2region`: This is a wrapper for the [Talairach client](http://www.talairach.org/client.html). It requires that the `talairach.jar` file be in the same folder.

`region2comps`: This is a wrapper for `tal2region`, that takes an EEG struct and a brain region as input, and returns the IC numbers that are in, or close to that region.

`select_comps`: Takes a preprocessed EEG struct and returns component numbers that match three criteria: region, residual variance, or by manually giving indices. In this project, the indices input is used for manually selecting components that are dipolar.

`getfft3`: A fancy wrapper on MATLAB's `fft` function that expects data to be channels-by-time-by-trials (e.g., EEGLAB's EEG.data).

`noisefloor3`: For each value in the data, remove the mean of surrounding values. This version expects data to be channels-by-time-by-trials (e.g., EEGLAB's EEG.data).

`getbins3`: Given some data and a vector of labels, get the value (or mean/max/min) of data for specified labels. This is used to get the max spectral value at a given frequency.
