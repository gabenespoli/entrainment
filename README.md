# Neural Entrainment Scripts

These MATLAB scripts were used for a project measuring neural entrainment using EEG. I have put them here with the hope that they will be useful to others interested in analyzing EEG data. They can be used as a template for another analysis or for inspiration. Many of the scripts can be used outside of this project (see the [General EEG Analysis](#analysis-functions-general-eeg-analysis) section).

The `analysis` folder is a combination of wrapper scripts for [EEGLAB](https://sccn.ucsd.edu/eeglab/index.php) (mostly for preprocessing), and custom functions for selecting independent components by location and measuring entrainment. The `task` folder is for presenting stimuli on a Windows computer, and was used to send port codes to a BioSemi EEG recording system.

## Table of Contents

1. [Analysis](#analysis)
    1. [Explanation of the Method](#analysis-explanation-of-the-method)
    2. [Running the Analysis](#analysis-running-the-analysis)
        1. [The Project Folder](#analysis-the-project-folder)
        2. [The Diary File](#analysis-the-diary-file)
        3. [Running the Whole Pipeline](#analysis-running-the-whole-pipeline)
    3. [List of Analysis Functions](#analysis-list-of-analysis-functions)
        1. [Project Macros](#analysis-functions-project-macros)
        2. [Project Utilities](#analysis-functions-project-utilities)
        3. [Project EEG Analysis](#analysis-functions-project-eeg-analysis)
        4. [General EEG Analysis](#analysis-functions-general-eeg-analysis)
2. [Task](#task)
3. [MATLAB](#matlab)

<a name="analysis">

## Analysis

<a name="analysis-explanation-of-the-method">

### Explanation of the Method

Coming soon...

<a name="analysis-running-the-pipeline">

### Running the Analysis

<a name="analysis-the-project-folder"></a>

#### The Project Folder

The function `getpath` is used to access all required directory paths and files for the rest of the scripts in this toolbox (except for the [General EEG Analysis](#analysis-functions-general-eeg-analysis) functions, which don't require any external paths or files). Paths can be edited, added, or removed from that function as needed. Here is the folder structure for the current project, with some example filenames:

```
project_folder/         set this in getroot
├─ analysis/            the folder from this repository
│  └─ en_diary.csv      this file should be edited with your own data
│
├─ data/  
│  ├─ bdf/              .bdf files of raw EEG recordings  
│  ├─ eeg/              .set files from en_preprocess_eeg  
│  ├─ eeg_goodcomps/    .png topo- and dip-plots from en_eeg_entrainment  
│  │  └─ pmc            subfolder(s) for specific brain regions
│  ├─ eeg_entrainment/  .csv files from en_eeg_entrainment  
│  ├─ eeg_topoplots/    .fig and .png topoplots files from en_preprocess_eeg  
│  ├─ logfiles/         .csv and .txt files should be copied from task/logfiles
│  ├─ midi/             .mid and .wav tapping files exported from Pro Tools
│  └─ tapping/          .mat files from en_preprocess_tapping
│
├─ eeglab/              EEGLAB toolbox (https://bitbucket.org/sccn_eeglab/eeglab.git)
│
├─ miditoolbox1.1/      MIDI toolbox (https://github.com/miditoolbox/1.1) 
│
└─ task/                from this repository; move to stimulus presentation computer
   └─ logfiles/         these are just logfiles from testing
```

Note: the task scripts save the logfiles in the task/logfiles folder; these files should be moved to the logfiles folder for analysis.

<a name="analysis-the-diary-file"></a>

#### The Diary File

The diary.csv file can be considered a sort of configuration file for the analysis. It should contain the following columns, with each row representing a single participant:

| Variable                    | Type                                    | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| --------------------------- | --------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| id                          | [number]                                | Each row should be a unique number. When calling the functions in this toolbox, use this number to refer to a specific participant.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| incl                        | [boolean; 1 or 0]                       | Whether or not to include this participant in the analysis. When calling the "getdata" or looping functions in this toolbox, leaving the id argument empty will use all id's that have a 1 here.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| order                       | [number; 1 or 2]                        | This is used by the `en_epoch` function.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| bdffile                     | [comma-separated list of strings]       | List of bdf (raw BioSemi EEG data) files associated with this id. Don't include the ".bdf". If there are multiple files, `en_readbdf` will read them all and merge them using EEGLAB's `pop_mergeset`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| hc                          | [numeric]                               | Circumference of the participant's head in centimeters (cm). This can be used for dipole fitting by `en_dipfit`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| capsize                     | [string, 'M' or 'ML']                   | Which BioSemi cap was used, either medium (M) or medium-large (ML). This is used by the `en_dipfit` function for the grid search.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| eventchans                  | [number]                                | The channel from which the portcode information should be extracted. Used by the `en_readbdf` function.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| badchans                    | [comma-separated list of strings]       | Channel/electrode labels that should be removed because they were noisy during the recording.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| extra_eeg_event             | [comma-separated list of numbers]       | If there were extra portcodes sent (e.g., because a trial was repeated and the portcode was erroneously sent twice), enter the indices of the portcodes that should be removed. For example, if there are 60 trials, and the portcode for the 30th trial was sent twice (i.e., the 30th and 31st portcodes are the same trial, and you would like to remove the first one), enter 30 here.                                                                                                                                                                                                                                                                                                                              |
| missed_eeg_event            | [comma-separated list of numbers]       | If some portcodes did not get sent (e.g., because the BioSemi battery died, but the experiment continued), enter the indices of the portcodes that were missed. For example, if there are 60 trials, and the battery died after the 10th trial, you didn't notice and stop the experiment until after the 15th trial (trials 11 to 15 did not have their portcodes recorded), enter "11, 12, 13, 14, 15" here (without the quotes). Note that if the battery dies in the middle of a trial, you might want to consider adding that trial to *extra_eeg_event*. Filling in this field will probably require some comparison of the logfile (which portcodes were sent) and the BDF file (which portcodes were recorded). |
| extra_midi_event            | [comma-separated list of numbers]       | Same as extra_eeg_event, but for the MIDI recording.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| experimenters               | [comma-separated list of strings]       | Initials of the experimenters for this participant's session.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| recording_notes             | [semicolon-separated list of sentences] | Any notes from the EEG recording session that might be good to know.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| midi_audio_marker_threshold | [number]                                | The `threshold` parameter used by `findAudioMarkers` when finding event markers for epoching MIDI data. If the audio level is the same for all participants than this will not be needed. Leaving this empty will use the default value set in `en_preprocess_tapping`.                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| midi_timeBetween_secs       | [number]                                | The `timeBetween` parameter used by `findAudioMarkers` when finding event markers for epoching MIDI data. Make this shorter if the participant was really quick advancing from one trial to the next. leaving this empty will use the default value set in `en_preprocess_tapping`.                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| dipolar_comps               | [comma-separated list of numbers]       | After running `en_preprocess_eeg`, look at the topographical plots that are saved and mark down which components are dipolar. This field is used by `en_eeg_entrainment` to select good components with `select_comps`. See Delorme, Palmer, Onton, Oostenveld, & Makeig (2012; PLOS ONE) for more information.                                                                                                                                                                                                                                                                                                                                                                                                         |

<a name="analysis-running-the-whole-pipeline"></a>

#### Running the Whole Pipeline

The following code will run the entire analysis pipeline from raw data files to a tabular data frame of entrainment values.

```matlab
% make a copy of getroot_example.m and rename it getroot.m
% edit getroot.m to return the absolute path to the project root
%   (i.e., the "project_folder" in the directory structure above)
% set current folder to this analysis folder, or add it to the MATLAB path
ids = 6:16; % specify the ids you would like to analyze
en_load('eeglab') % adds eeglab to the MATLAB path
en_preprocess(ids); % preprocess EEG and tapping data, saves topoplots
% look at topographical maps saved in getpath('topoplots') and mark down component numbers that are dipolar in en_diary.csv
en_loop_eeg_entrainment(ids);
% MIDI analysis is coming soon...
T = en_getdata(ids);
writetable(T, 'mydata.csv');
```

<a name="analysis-list-of-analysis-functions"></a>

### List of Analysis Functions

Each function list is loosely in the order that they would be used in the processing pipeline.

<a name="analysis-functions-project-macros"></a>

#### Project Macros

Perform a whole section of the analysis pipeline and batch processing. These mostly contain calls to the other functions in the lists below.

| Function                  | Description                                                                                                                                                                                                                                                                                           |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `en_preprocess`           | Loops through the specified IDs and runs `en_preprocess_eeg` and `en_preprocess_tapping`. All output from the command window is captured for each ID and saved as a hidden file to `getpath('eeg')`, as well as a summary file to keep track of what has been completed and if errors were present.   |
| `en_preprocess_eeg`       | A macro that runs `en_readbdf` and a number of [EEGLAB](https://sccn.ucsd.edu/eeglab/index.php) functions to pre-process EEG data, including ICA and dipole fitting. Resultant .set files are saved to `getpath('eeg')`.                                                                              |
| `en_preprocess_tapping`   | A macro that loads the .wav file of stimuli that was exported from Pro Tools, searches for audio onsets to get the stimulus onset times, and uses these to epoch the MIDI tapping data. MIDI data is read using MIDI Toolbox and saved as a MATLAB table.                                             |
| `en_loop_eeg_entrainment` | Loops through specified IDs and runs `en_eeg_entrainment`.                                                                                                                                                                                                                                            |
| `en_eeg_entrainment`      | A macro that takes an ID or EEGLAB struct and outputs a table of entrainment values for each trial. Resultant tables are saved as .csv files in `getpath('eeg_entrainment')`.                                                                                                                         |

<a name="analysis-functions-project-utilities"></a>

#### Project Utilities

Simplify finding and loading files.

| Function                  | Description                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `getroot`                 | This function should return the absolute path to the project root folder. It is used by getpath.m to find files and folders needed for the analysis                                                                                                                                                                                                                                                                                                   |
| `getpath`                 | Takes a keyword as input and returns a directory or file path. All functions in this "toolbox" use this function to get path names. This means that you can move these scripts to a different computer or port them to a different project, and will only have to change this file in order for everything to work (theoretically). This function depends on getroot.m Note that you will have to create this file from the example that is provided. |
| `en_load`                 | Takes a keyword (and optionally an ID number), and loads the specified file into the MATLAB workspace. Can also start [EEGLAB](https://sccn.ucsd.edu/eeglab/index.php) from the path specified in `getpath('eeglab')`.                                                                                                                                                                                                                                |

<a name="analysis-functions-project-eeg-analysis"></a>

#### Project EEG Analysis

These include wrappers on EEGLAB functions (mostly EEG preprocessing) and custom scripts for spectral analyses.

| Function                  | Description                                                                                                                                                                                                                                                                                                                                                                |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `en_readbdf`              | Takes an ID number as input, gets their .bdf filenames from `en_diary.csv`, and reads those files into an [EEGLAB](https://sccn.ucsd.edu/eeglab/index.php) .set file (if there are multiple .bdf files, they are merged). It also converts the channel labels from the BioSemi alphabetical labels into [Oostenveld](http://robertoostenveld.nl/electrode/)'s 10-5 system. |
| `en_epoch`                | Epochs an EEG struct using [EEGLAB](https://sccn.ucsd.edu/eeglab/index.php) based on portcodes which are specified with keywords. This function in particular is highly specialized for the current study, and will require lots of editing to work for a different study.                                                                                                 |
| `en_dipfit`               | Wrapper on [EEGLAB](https://sccn.ucsd.edu/eeglab/index.php) functions for dipole fitting using the Boundary Element Model (BEM).                                                                                                                                                                                                                                           |

<a name="analysis-functions-general-eeg-analysis"></a>

#### General EEG Analysis

Some EEG-related functions for preprocessing and spectral analysis that will work outside of this project.

| Function                  | Description                                                                                                                                                                                                                                       |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `alpha2fivepct`           | Takes an EEG struct or a cell of strings, and remaps channel labels from BioSemi alphabetical labels to [Oostenveld](http://robertoostenveld.nl/electrode/)'s 10-5 system.                                                                        |
| `averageReference`        | Performs average referencing for fully-ranked data on an EEG struct.                                                                                                                                                                              |
| `tal2region`              | This is a wrapper for the [Talairach client](http://www.talairach.org/client.html). It requires that the `talairach.jar` file be in the same folder.                                                                                              |
| `region2comps`            | This is a wrapper for `tal2region`, that takes an EEG struct and a brain region as input, and returns the IC numbers that are in, or close to that region.                                                                                        |
| `select_comps`            | Takes a preprocessed EEG struct and returns component numbers that match three criteria: region, residual variance, or by manually giving indices. In this project, the indices input is used for manually selecting components that are dipolar. |
| `dtplot`                  | Takes a preprocessed EEG struct and displays both a topographical plot and a dipole plot for the specified components. If a folder argument is given, these plots are saved as .png files instead of being displayed.                             |
| `getfft3`                 | A fancy wrapper on MATLAB's `fft` function that expects data to be channels-by-time-by-trials (e.g., EEGLAB's EEG.data).                                                                                                                          |
| `noisefloor3`             | For each value in the data, remove the mean of surrounding values. This version expects data to be channels-by-time-by-trials (e.g., EEGLAB's EEG.data).                                                                                          |
| `getbins3`                | Given some data and a vector of labels, get the value (or mean/max/min) of data for specified labels. This is used to get the max spectral value at a given frequency.                                                                            |

<a name="task"></a>

## Task

Please see the documentation included in each of the functions in the task folder for an explanation of how they work.

<a name="matlab"></a>

## MATLAB

These scripts were written using MATLAB R2017a.
