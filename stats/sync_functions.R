# Load packages ---------------------------------------------------------------
library(dplyr)
library(plyr)
library(data.table)
library(reshape)
library(ez)
library(ggplot2)
library(ggsignif)

# load and parse entrainment csv file -----------------------------------------
sync.load.eeg <- function(fname) {
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
  df <- df[!(df$harmonic==3), ]
  df <- df[!(df$harmonic==5), ]
  df <- df[!(df$harmonic==6), ]
  df <- df[!(df$harmonic==7), ]
  df <- df[!(df$harmonic==8), ]

  # make it a data table
  df <- data.table(df)

  # make some things factors
  df$id <- as.factor(df$id)
  df$syncopation_degree <- factor(df$syncopation_degree,
                                  levels=c("low", "moderate", "high"))
  df$region <- as.factor(df$region)
  df$harmonic <- as.factor(df$harmonic)

  return(df)
}

# load tapping data -----------------------------------------------------------
sync.load.tapping <- function(fname) {
  require(data.table)
  df <- read.csv(fname)
  df <- data.table(df)
  df$id <- as.factor(df$id)
  df$syncopation_degree <- factor(df$syncopation_degree,
                                  levels=c("low", "moderate", "high"))
  return(df)
}

# inverted-U analysis ---------------------------------------------------------
sync.inverted.u <- function(df, dv, iv) {
  require(data.table)
  require(reshape)
  require(ez)

  dt <- data.table(df)
  # iv <- "syncopation_index"

  formula.linear <- paste("summary(lm(", dv, "~", iv, "))",
                          "$adj.r.squared", sep="")
  formula.quadratic <- paste("summary(lm(", dv, "~ I(", iv, "^2)))",
                          "$adj.r.squared", sep="")

  # regress each participant's ratings against the stims with syncopation
  #   index as predictor
  dt <- dt[, list(model.linear=eval(parse(text=formula.linear)),
                  model.quadratic=eval(parse(text=formula.quadratic))),
            by=id]

  # reshape into long format for the within design
  dt <- reshape(dt, direction="long",
                varying=c("model.linear", "model.quadratic"),
                timevar="model",
                times=c("linear", "quadratic"),
                v.names="adj.r.squared",
                idvar="id")
  dt$model <- factor(dt$model, levels=c("linear", "quadratic"))

  #  if entrainment is all zeros, the regression would be NA
  #   this would mess up the ANOVA, so remove them
  bad <- is.na(dt$adj.r.squared)
  if (sum(bad) > 0) {
    warning(paste("Removed", sum(bad), "records due to R^2 = NA."))
  }
  dt <- dt[!bad, ]

  # run ANOVA
  model <- ezANOVA(dt, dv=.(adj.r.squared), wid=.(id), within=.(model),
          detailed=FALSE, type="III")
  means <- ddply(dt, c("model"), summarise, mean=mean(adj.r.squared))

  # build return string
  if (model$ANOVA$p < .001) {
    pval <- "< 0.001"
  } else {
    pval <- paste("=", signif(model$ANOVA$p, digits=2), sep=" ")
  }
  mean.linear <- means$mean[means$model=="linear"]
  mean.quadratic <- means$mean[means$model=="quadratic"]
  str <- paste("*F*(",
               model$ANOVA$DFn, ",",
               model$ANOVA$DFd, ") = ",
               signif(model$ANOVA$F, digits=4),
               ", *p* ", pval,
               " (linear = ", signif(mean.linear, 4),
               ", quadratic = ", signif(mean.quadratic, 4),
               ")",
               sep="")
  return(str)
}

# t-test function -------------------------------------------------------------
en.t.test <- function(data, groups, test.groups, ind=0) {
  # data: vector of data
  # groups: factor with groups
  # test.groups: cell of length 2 with groups to compare
  # example: en.t.test(df$normmax, df$syncopation_degree, c("low", "high"))
  if (length(ind) > 1) {
    data <- data[ind]
    groups <- groups[ind]
  }
  x <- data[groups==test.groups[1]]
  y <- data[groups==test.groups[2]]
  d <- t.test(x, y)
  df <- round(d$parameter, 1)
  t <- signif(d$statistic, 4)
  p <- signif(d$p.value, 2)

  str <- paste("*t*(", df, ") = ", t, ", ", "*p* = ", p, sep="")
  means <- paste(test.groups[1], ": ", signif(mean(x), 6), ", ",
                 test.groups[2], ": ", signif(mean(y), 6),
                 sep="")
  return(c(str, means))
}

# print f string --------------------------------------------------------------
en.f.string <- function(model, effect) {
  DFn  <- m$ANOVA$DFn[m$ANOVA$Effect==effect]
  DFd  <- m$ANOVA$DFd[m$ANOVA$Effect==effect]
  Fval <- signif(m$ANOVA$F[m$ANOVA$Effect==effect], 4)
  pval <- signif(m$ANOVA$p[m$ANOVA$Effect==effect], 2)
  if (pval < 0.001) {
    pval <- paste("<", .001)
  } else {
    pval <- paste("=", pval)
  }
  str <- paste("*F*(", DFn, ",", DFd, ") = ", Fval, ", *p* ", pval, sep="")
  return(str)
}
