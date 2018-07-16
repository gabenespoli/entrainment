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

# print cortable as a markdown pipe table ----
cortable.print <- function(df) {
  tb <- cortable(df)
  tb.rownames <- rownames(tb)
  tb.colnames <- colnames(tb)
  l <- vector("list", dim(tb)[1] + 1)

  # first row is column headers
  l[[1]] <- paste("|", "|",
                  paste(gsub("_", " ", tb.colnames), collapse=" | "),
                  "|")

  # second row is dashes to separate the header row
  l[[2]] <- paste("|", strrep("-", max(sapply(tb.rownames, nchar))), "|")
  for (i in tb.colnames) {
    l[[2]] <- paste(l[[2]], strrep("-", nchar(i)), "|")
  }

  # loop rows (list items)
  nrow <- 3
  for (rowname in tb.rownames) {
    l[[nrow]] <- paste("|", rowname)
    for (colname in tb.colnames) {
      l[[nrow]] <- paste(l[[nrow]], "|", tb[rowname, colname])
    }
    l[[nrow]] <- paste(l[[nrow]], "|")
    nrow <- nrow + 1
  }

  # display in console
  for (ln in l) {
    cat(ln, "\n")
  }
}

# print f string from an lm model ----
summary.print.f <- function(model) {
  s <- summary(model)
  df1 <- s$fstatistic["numdf"]
  df2 <- s$fstatistic["dendf"]
  fval <- s$fstatistic["value"]
  pval <- pf(fval, df1, df2, lower.tail=FALSE)
  pvalstr <- pval.string(pval)
  cat("*F*(", df1, ",", df2, ") = ", signif(fval, 4),
      ", ", pvalstr, "\n", sep="")
}

# print regression table as a markdown pipe table ----
summary.print.reg.table <- function(model) {
  s <- summary(model)
  s.colnames <- c("Estimate", "t value", "Pr(>|t|)")
  s.collabels <- c("Variable", "β", "*t*", "*p*")
  s.rownames <- rownames(s$coefficients)[-1] # remove intercept
  l <- vector("list", length(s.rownames) + 2)

  # first row is column headers, second row is dashes
  l[[1]] <- paste("|", paste(s.collabels, collapse=" | "), "|")
  l[[2]] <- paste("|", strrep("-", max(sapply(s.rownames, nchar))),
                  "|", strrep(" --------- |", 3), sep="")

  # loop variables and add rows
  nrow <- 3
  for (name in s.rownames) {
    l[[nrow]] <- paste("|", gsub("_", " ", name),
                       "|", signif(s$coefficients[name, "Estimate"], 4),
                       "|", signif(s$coefficients[name, "t value"], 4),
                       "|", pval.string(s$coefficients[name, "Pr(>|t|)"],
                                        pstr=FALSE),
                       "|")
    nrow <- nrow + 1
  }

  # display in console
  for (ln in l) {
    cat(ln, "\n")
  }
}

# get pval string ----
pval.string <- function(pval,
                        pstr=TRUE,
                        stars=TRUE,
                        sigdig=2) {
  starstr <- ""
  if (stars) {
    if (pval < .001) {
      starstr <- "***"
    } else if (pval < .01) {
      starstr <- "**"
    } else if (pval < .05) {
      starstr <- "*"
    } else if (pval < .1) {
      starstr <- "†"
    }
  }

  operator <- "="
  if (pval < .001) {
    operator <- "<"
    pvalstr <- ".001"
  } else if (pval < 1) {
    pvalstr <- toString(signif(pval, sigdig))
    pvalstr <- substr(pval, 2, nchar(pvalstr))
  } else if (pval == 1) {
    pvalstr <- "1"
  }

  if (pstr) {
    pvalstr <- paste("*p*", operator, pvalstr)
  } else if (pval < .001) {
    pvalstr <- paste(operator, pvalstr, sep="")
  }

  if (stars) {
    pvalstr <- paste(pvalstr, starstr, sep="")
  }

  return(pvalstr)

}
