# Load packages ---------------------------------------------------------------
library(dplyr)
library(plyr)
library(data.table)
library(reshape)
library(ez)
library(MASS)
library(ggplot2)
library(ggsignif)
library(RColorBrewer)

# load and parse entrainment csv file -----------------------------------------
mir.load.eeg <- function(fname) {
  require(ez)
  require(reshape)
  require(data.table)

  # read csv
  df <- read.csv(fname)

  # use R's naming conventions instead of matlab's
  colnames(df)[colnames(df)=="aud"]         <- "aud.en"
  colnames(df)[colnames(df)=="aud_comp"]    <- "aud.comp"
  colnames(df)[colnames(df)=="aud_distance"]<- "aud.distance"
  colnames(df)[colnames(df)=="aud_norm"]    <- "aud.norm"
  colnames(df)[colnames(df)=="aud_normmax"] <- "aud.normmax"
  colnames(df)[colnames(df)=="pmc"]         <- "pmc.en"
  colnames(df)[colnames(df)=="pmc_comp"]    <- "pmc.comp"
  colnames(df)[colnames(df)=="pmc_distance"]<- "pmc.distance"
  colnames(df)[colnames(df)=="pmc_norm"]    <- "pmc.norm"
  colnames(df)[colnames(df)=="pmc_normmax"] <- "pmc.normmax"

  # melt regions into single column
  df <- reshape(df, direction="long",
                varying=c("aud.comp", "aud.distance",
                          "aud.en", "aud.norm", "aud.normmax",
                          "pmc.comp", "pmc.distance",
                          "pmc.en", "pmc.norm", "pmc.normmax"),
                timevar="region",
                times=c("aud", "pmc"),
                v.names=c("comp", "distance", "en", "norm", "normmax"),
                idvar=c("id", "stim", "task", "trial", "harmonic"))

  # drop not-so-meter-related harmonics
  # keep only 0.5, 1, 2, 4
  # edit keep only 1
  df <- df[!(df$harmonic==0.5), ]
  df <- df[!(df$harmonic==2), ]
  df <- df[!(df$harmonic==4), ]
  df <- df[!(df$harmonic==3), ]
  df <- df[!(df$harmonic==5), ]
  df <- df[!(df$harmonic==6), ]
  df <- df[!(df$harmonic==7), ]
  df <- df[!(df$harmonic==8), ]

  # drop auditory region
  df <- df[!(df$region=="aud"), ]

  # make it a data table
  df <- data.table(df)

  # make some things factors
  df$id <- as.factor(df$id)
  df$region <- as.factor(df$region)
  df$harmonic <- as.factor(df$harmonic)

  return(df)
}

# load tapping data -----------------------------------------------------------
mir.load.tapping <- function(fname) {
  require(data.table)
  df <- read.csv(fname)
  df <- data.table(df)
  return(df)
}

# add mir features to data tables ---------------------------------------------
mir.add.mir <- function(df, folder) {
  mir <- data.table(read.csv(paste(folder, "features.csv", sep="")))
  df <- merge(df, mir, by="portcode")
  # mir <- data.table(read.csv(paste(folder, "mir_features.csv", sep="")))
  # shakeit <- data.table(read.csv(paste(folder, "shakeit_features.csv", sep="")))
  # remove unneeded columns
  # mir[, c("filepath", "filename"):=NULL]
  # shakeit[, c("filename", "dateExtracted"):=NULL]

  # merge features with data
  # df <- merge(df, shakeit, by="portcode")
  # df <- merge(df, mir, by="portcode")
  return(df)
}
