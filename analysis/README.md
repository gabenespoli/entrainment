# en/analysis

## Project functions

`en_getpath`: Takes a keyword as input and returns a directory or file path. All functions in this "toolbox" use this function to get path names. This means that you can move these scripts to a different computer or port them to a different project, and will only have to change this file in order for everything to work (theoretically).

`en_load`: Takes a keyword (and optionally an ID number), and loads the specified file into the MATLAB workspace. Can also start [EEGLAB](https://sccn.ucsd.edu/eeglab/index.php) from the path specified in `en_getpath('eeglab')`.

`en_readbdf`: Takes an ID number as input, gets their .bdf filenames from `en_diary.csv`, and reads those files into an [EEGLAB](https://sccn.ucsd.edu/eeglab/index.php) .set file (if there are multiple .bdf files, they are merged). It also converts the channel labels from the BioSemi alphabetical labels into [Oostenveld](http://robertoostenveld.nl/electrode/)'s 10-5 system.

`en_eeg_preprocess`: A macro that runs `en_readbdf` and a number of [EEGLAB](https://sccn.ucsd.edu/eeglab/index.php) functions to pre-process EEG data, including ICA and dipole fitting. Resultant .set files are saved to `en_getpath('eeg')`.

`en_eeg_loop`: Loops through the specified IDs and runs `en_eeg_preprocess`. All output from the command window is captured for each ID and saved to `en_getpath('eeg')`, as well as a summary file with processing times and any errors for each ID.

## EEG analysis

`alpha2fivepct`: Takes an EEG struct or a cell of strings, and remaps channel labels from BioSemi alphabetical labels to [Oostenveld](http://robertoostenveld.nl/electrode/)'s 10-5 system.

`averageReference`: Performs average referencing for fully-ranked data on an EEG struct.

`en_epoch`: Epochs an EEG struct based on portcodes which are specified with keywords. This function in particular is highly specialized for the current study, and will require lots of editing to work for a different study.

`en_dipfit`: Wrapper on [EEGLAB](https://sccn.ucsd.edu/eeglab/index.php) functions for dipole fitting using the Boundary Element Model (BEM).

`tal2region`: This is a wrapper for the [Talairach client](http://www.talairach.org/client.html). It requires that the `talairach.jar` file be in the same folder.

`region2comps`: This is a wrapper for `tal2region`, that takes an EEG struct and a brain region as input, and returns the IC numbers that are in, or close to that region.

`en_select_comps`: Takes a preprocessed EEG struct and returns component numbers that match three criteria: region, residual variance, and dipolarity (as marked by manual inspection and recorded in en_diary.csv in the "dipolar_comps" column).
