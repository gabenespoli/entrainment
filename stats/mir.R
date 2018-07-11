# Setup ----
# variables and functions ====
source("mir_functions.R")
source("cortable.R")
folder <- "../tables/"
plotfolder <- "../plots/"
paperfolder <- "~/projects/phd/images/"
yl <- c(0, 0.3)
plotscale <- 0.55
do.save <- TRUE

# load raw data ====
eeg.raw <- mir.load.eeg(paste(folder, "en_mir_eeg.csv", sep=""))
tap.raw <- mir.load.tapping(paste(folder, "ent_mir.csv", sep=""))
tap.raw$id <- as.factor(tap.raw$id)
patterns <- read.csv(paste(folder, "mir_portcode_patterns.csv", sep=""))
eeg.raw <- merge(eeg.raw, patterns, by="portcode")
tap.raw <- merge(tap.raw, patterns, by="portcode")

# Load Ratings ====
rat.all <- rbind(tap.raw[, c("id", "pattern", "move")],
                 eeg.raw[, c("id", "pattern", "move")])
rat.all <- rat.all[, list(move=mean(move)), by=.(id, pattern)]
rat.avg <- rbind(tap.raw[, c("pattern", "move")],
                 eeg.raw[, c("pattern", "move")])
rat.avg <- rat.avg[, list(move=mean(move)), by=.(pattern)]

# Load Tapping ====
tap.all <- tap.raw[, list(variability=mean(variability),
                      asynchrony=mean(asynchrony),
                      coeffofvar=mean(coeffofvar),
                      duration=mean(duration),
                      velocity=mean(velocity)), by=.(id, pattern)]
tap.avg <- tap.raw[, list(variability=mean(variability),
                      asynchrony=mean(asynchrony),
                      coeffofvar=mean(coeffofvar),
                      duration=mean(duration),
                      velocity=mean(velocity)), by=pattern]

# Load Entrainment ====
eeg.all <- eeg.raw[, list(en=mean(en), en_norm=mean(normmax)),
                   by=.(id, pattern)]
eeg.avg <- eeg.raw[, list(en=mean(en), en_norm=mean(normmax)),
                   by=.(pattern)]

# Load Combined ====
all.all <- merge(tap.all, eeg.all, by=c("id", "pattern"))
all.all <- merge(rat.all, all.all, by=c("id", "pattern"))
all.avg <- merge(tap.avg, eeg.avg, by="pattern")
all.avg <- merge(rat.avg, all.avg, by="pattern")

# add mir ====
mir  <- data.table(read.csv(paste(folder, "features.csv", sep="")))
mir <- mir[, portcode:=NULL]
mir <- mir[, tempo:=NULL]
mir <- mir[, lapply(.SD, mean), by=pattern]
rat.all <- merge(rat.all, mir, by="pattern")
rat.avg <- merge(rat.avg, mir, by="pattern")
tap.all <- merge(tap.all, mir, by="pattern")
tap.avg <- merge(tap.avg, mir, by="pattern")
eeg.all <- merge(eeg.all, mir, by="pattern")
eeg.avg <- merge(eeg.avg, mir, by="pattern")
all.all <- merge(all.all, mir, by="pattern")
all.avg <- merge(all.avg, mir, by="pattern")

# Stats (collapse id) ----
# Ratings Model (Ratings) ====
ratings.model <- lm(move ~
                    beatsalience +           # Madison2011
                    eventdensity_shakeit +   # Madison2011
                    rmsStd +                 # Stupacher2016
                    flux_0_50 +              # Stupacher2016
                    flux_50_100 +            # Stupacher2016
                    flux_100_200,            # Stupacher2016
                    data=rat.avg)

summary(ratings.model)
# 
# Call:
# lm(formula = move ~ beatsalience + eventdensity_shakeit + rmsStd + 
#     flux_0_50 + flux_50_100 + flux_100_200, data = dr)
# 
# Residuals:
#      Min       1Q   Median       3Q      Max 
# -1.21193 -0.31520 -0.06137  0.40418  0.79342 
# 
# Coefficients:
#                      Estimate Std. Error t value Pr(>|t|)    
# (Intercept)            4.4126     0.9656   4.570 0.000136 ***
# beatsalience          -1.6783     0.9739  -1.723 0.098249 .  
# eventdensity_shakeit   4.6275     3.5786   1.293 0.208805    
# rmsStd                -6.8165    11.9349  -0.571 0.573442    
# flux_0_50             -0.7287     0.6252  -1.166 0.255727    
# flux_50_100            1.8407     1.5536   1.185 0.248202    
# flux_100_200           3.2963    54.3054   0.061 0.952124    
# ---
# Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1
# 
# Residual standard error: 0.5456 on 23 degrees of freedom
# Multiple R-squared:  0.2711,	Adjusted R-squared:  0.08091 
# F-statistic: 1.425 on 6 and 23 DF,  p-value: 0.2477
# 

# Ratings Model (Entrainment) ====
en.ratings.model <- lm(en_norm ~
                       beatsalience +           # Madison2011
                       eventdensity_shakeit +   # Madison2011
                       rmsStd +                 # Stupacher2016
                       flux_0_50 +              # Stupacher2016
                       flux_50_100 +            # Stupacher2016
                       flux_100_200,            # Stupacher2016
                       data=eeg.avg)

summary(en.ratings.model)
# 
# Call:
# lm(formula = normmax ~ beatsalience + eventdensity_shakeit + 
#     rmsStd + flux_0_50 + flux_50_100 + flux_100_200, data = de)
# 
# Residuals:
#       Min        1Q    Median        3Q       Max 
# -0.050263 -0.013856  0.002537  0.019885  0.052560 
# 
# Coefficients:
#                      Estimate Std. Error t value Pr(>|t|)    
# (Intercept)           0.21037    0.05124   4.106 0.000433 ***
# beatsalience          0.03240    0.05168   0.627 0.536896    
# eventdensity_shakeit -0.62619    0.18989  -3.298 0.003148 ** 
# rmsStd                0.89558    0.63332   1.414 0.170724    
# flux_0_50             0.00139    0.03318   0.042 0.966934    
# flux_50_100          -0.03900    0.08244  -0.473 0.640590    
# flux_100_200          5.13597    2.88169   1.782 0.087911 .  
# ---
# Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1
# 
# Residual standard error: 0.02895 on 23 degrees of freedom
# Multiple R-squared:  0.3876,	Adjusted R-squared:  0.2278 
# F-statistic: 2.426 on 6 and 23 DF,  p-value: 0.05779
# 

# run model on all participants ####
ids <- unique(eeg.all$id)
ids.length <- length(ids)
r.squared <- vector(mode="integer", length=ids.length)
for (i in 1:ids.length) {
  model <- lm(en_norm ~ eventdensity_shakeit + flux_100_200,
              data=eeg.all[eeg.all$id == ids[i]])
  r.squared[i] <- summary(model)$r.squared
}
median(r.squared, na.rm=TRUE)
max(r.squared, na.rm=TRUE)
min(r.squared, na.rm=TRUE)

# Tapping Model (Tapping) ====
tapping.model  <- lm(variability ~
                     pulseclarity +   # Burger2012
                     percussiveness + # Burger2012
                     flux_0_50 +      # Burger2012, Stupacher2016
                     flux_50_100 +    # Burger2012, Stupacher2016
                     flux_100_200,    # Burger2012, Stupacher2016
                     data=tap.avg)

summary(tapping.model)
# 
# Call:
# lm(formula = variability ~ pulseclarity + percussiveness + flux_0_50 + 
#     flux_50_100 + flux_100_200, data = dt)
# 
# Residuals:
#       Min        1Q    Median        3Q       Max 
# -0.053872 -0.024217 -0.006682  0.011093  0.114993 
# 
# Coefficients:
#                 Estimate Std. Error t value Pr(>|t|)
# (Intercept)     0.072056   0.062340   1.156    0.259
# pulseclarity    0.006990   0.006086   1.149    0.262
# percussiveness -0.005962   0.003611  -1.651    0.112
# flux_0_50       0.037046   0.050066   0.740    0.467
# flux_50_100    -0.087401   0.123644  -0.707    0.486
# flux_100_200    1.804543   3.931044   0.459    0.650
#k 
# Residual standard error: 0.04291 on 24 degrees of freedom
# Multiple R-squared:  0.2235,	Adjusted R-squared:  0.0617 
# F-statistic: 1.381 on 5 and 24 DF,  p-value: 0.2663
# 

# Tapping Model (Entrainment) ====
en.tapping.model  <- lm(en_norm ~
                        pulseclarity +   # Burger2012
                        percussiveness + # Burger2012
                        flux_0_50 +      # Burger2012, Stupacher2016
                        flux_50_100 +    # Burger2012, Stupacher2016
                        flux_100_200,    # Burger2012, Stupacher2016
                        data=eeg.avg)

summary(en.tapping.model)
# 
# Call:
# lm(formula = normmax ~ pulseclarity + percussiveness + flux_0_50 + 
#     flux_50_100 + flux_100_200, data = de)
# 
# Residuals:
#       Min        1Q    Median        3Q       Max 
# -0.054525 -0.018660 -0.001524  0.015826  0.075632 
# 
# Coefficients:
#                 Estimate Std. Error t value Pr(>|t|)  
# (Intercept)     0.091972   0.046735   1.968   0.0607 .
# pulseclarity    0.002577   0.004562   0.565   0.5775  
# percussiveness  0.006016   0.002707   2.222   0.0359 *
# flux_0_50       0.050863   0.037533   1.355   0.1880  
# flux_50_100    -0.121286   0.092694  -1.308   0.2031  
# flux_100_200    0.410528   2.947047   0.139   0.8904  
# ---
# Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1
# 
# Residual standard error: 0.03217 on 24 degrees of freedom
# Multiple R-squared:  0.2111,	Adjusted R-squared:  0.04675 
# F-statistic: 1.284 on 5 and 24 DF,  p-value: 0.3032
# 

# run model on all participants ####
ids <- unique(eeg.all$id)
ids.length <- length(ids)
r.squared <- vector(mode="integer", length=ids.length)
for (i in 1:ids.length) {
  model <- lm(en_norm ~ percussiveness,
              data=eeg.all[eeg.all$id == ids[i]])
  r.squared[i] <- summary(model)$r.squared
}
median(r.squared, na.rm=TRUE)
max(r.squared, na.rm=TRUE)
min(r.squared, na.rm=TRUE)

# Stepwise Model (Entrainment) ====
en.model <- lm(en_norm ~
               beatsalience +
               pulseclarity +
               eventdensity_shakeit +
               percussiveness +
               rmsStd +
               flux_0_50 +
               flux_50_100 +
               flux_100_200,
             data=eeg.avg)
en.step <- step(en.model, direction="both")

summary(en.step)
# 
# Call:
# lm(formula = normmax ~ pulseclarity + eventdensity_shakeit + 
#     percussiveness + flux_100_200, data = df)
# 
# Residuals:
#       Min        1Q    Median        3Q       Max 
# -0.059289 -0.011985  0.001675  0.016878  0.041649 
# 
# Coefficients:
#                       Estimate Std. Error t value Pr(>|t|)    
# (Intercept)           0.171287   0.043552   3.933 0.000589 ***
# pulseclarity          0.007432   0.003949   1.882 0.071538 .  
# eventdensity_shakeit -0.495487   0.148230  -3.343 0.002614 ** 
# percussiveness        0.004245   0.001981   2.143 0.042078 *  
# flux_100_200          1.694995   1.213743   1.397 0.174840    
# ---
# Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1
# 
# Residual standard error: 0.02719 on 25 degrees of freedom
# Multiple R-squared:  0.4128,	Adjusted R-squared:  0.3188 
# F-statistic: 4.393 on 4 and 25 DF,  p-value: 0.007939
# 

en.step$anova
#             Step Df     Deviance Resid. Df Resid. Dev       AIC
# 1                NA           NA        21 0.01707233 -206.1448
# 2    - flux_0_50  1 7.126437e-05        22 0.01714360 -208.0198
# 3 - beatsalience  1 2.321140e-04        23 0.01737571 -209.6164
# 4       - rmsStd  1 3.630944e-04        24 0.01773881 -210.9959
# 5  - flux_50_100  1 7.469058e-04        25 0.01848571 -211.7586

# Stats (MLM) ----
# Ratings Model (Ratings) ====
rat.base  <- lmer(move ~ 1 + (1|id), data=rat.all, REML=FALSE)
rat.model <- lmer(move ~
                  beatsalience +
                  eventdensity_shakeit +
                  rmsStd +
                  flux_0_50 +
                  flux_50_100 +
                  flux_100_200 +
                  (1|id),
                data=rat.all,
                REML=FALSE)

# anova ####
anova(rat.base, rat.model)
# Data: rat.all
# Models:
# rat.base: move ~ 1 + (1 | id)
# rat.model: move ~ beatsalience + eventdensity_shakeit + rmsStd + flux_0_50 + 
# rat.model:     flux_50_100 + flux_100_200 + (1 | id)
#           Df    AIC    BIC  logLik deviance  Chisq Chi Df Pr(>Chisq)
# rat.base   3 3757.3 3772.5 -1875.7   3751.3                         
# rat.model  9 3690.6 3736.1 -1836.3   3672.6 78.771      6  6.409e-15
#              
# rat.base     
# rat.model ***
# ---
# Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

# summary ####
summary(rat.model)
# Linear mixed model fit by maximum likelihood  ['lmerMod']
# Formula: 
# move ~ beatsalience + eventdensity_shakeit + rmsStd + flux_0_50 +  
#     flux_50_100 + flux_100_200 + (1 | id)
#    Data: rat.all
# 
#      AIC      BIC   logLik deviance df.resid 
#   3690.6   3736.1  -1836.3   3672.6     1161 
# 
# Scaled residuals: 
#     Min      1Q  Median      3Q     Max 
# -3.5288 -0.5989  0.0351  0.6849  2.6268 
# 
# Random effects:
#  Groups   Name        Variance Std.Dev.
#  id       (Intercept) 0.8955   0.9463  
#  Residual             1.2171   1.1032  
# Number of obs: 1170, groups:  id, 39
# 
# Fixed effects:
#                      Estimate Std. Error t value
# (Intercept)            4.4126     0.3474  12.700
# beatsalience          -1.6783     0.3153  -5.322
# eventdensity_shakeit   4.6275     1.1587   3.994
# rmsStd                -6.8165     3.8644  -1.764
# flux_0_50             -0.7287     0.2024  -3.600
# flux_50_100            1.8407     0.5031   3.659
# flux_100_200           3.2963    17.5836   0.187
# 
# Correlation of Fixed Effects:
#             (Intr) btslnc evntd_ rmsStd f_0_50 f_50_1
# beatsalienc -0.386                                   
# evntdnsty_s -0.236 -0.515                            
# rmsStd      -0.477  0.196 -0.271                     
# flux_0_50   -0.144 -0.039  0.214  0.015              
# flux_50_100  0.145  0.006 -0.140 -0.055 -0.983       
# flx_100_200  0.144  0.132 -0.316 -0.313  0.292 -0.417

# Ratings Model (Entrainment) ====
eeg.base  <- lmer(en ~ 1 + (1|id), data=eeg.all, REML=FALSE)
eeg.model <- lmer(en ~
                  beatsalience +
                  eventdensity_shakeit +
                  rmsStd +
                  flux_0_50 +
                  flux_50_100 +
                  flux_100_200 +
                  (1|id),
                data=eeg.all,
                REML=FALSE)

# anova ####
anova(eeg.base, eeg.model)
# Data: eeg.all
# Models:
# eeg.base: en ~ 1 + (1 | id)
# eeg.model: en ~ beatsalience + eventdensity_shakeit + rmsStd + flux_0_50 + 
# eeg.model:     flux_50_100 + flux_100_200 + (1 | id)
#           Df    AIC    BIC logLik deviance  Chisq Chi Df Pr(>Chisq)  
# eeg.base   3 -12109 -12094 6057.6   -12115                           
# eeg.model  9 -12112 -12066 6065.0   -12130 14.912      6    0.02095 *
# ---
# Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

# summary ####
summary(eeg.model)
# Linear mixed model fit by maximum likelihood  ['lmerMod']
# Formula: 
# en ~ beatsalience + eventdensity_shakeit + rmsStd + flux_0_50 +  
#     flux_50_100 + flux_100_200 + (1 | id)
#    Data: eeg.all
# 
#      AIC      BIC   logLik deviance df.resid 
# -12112.0 -12066.5   6065.0 -12130.0     1152 
# 
# Scaled residuals: 
#     Min      1Q  Median      3Q     Max 
# -2.0680 -0.5224 -0.1112  0.2311  9.8849 
# 
# Random effects:
#  Groups   Name        Variance  Std.Dev. 
#  id       (Intercept) 5.978e-07 0.0007731
#  Residual             1.561e-06 0.0012493
# Number of obs: 1161, groups:  id, 39
# 
# Fixed effects:
#                        Estimate Std. Error t value
# (Intercept)           1.698e-03  3.770e-04   4.505
# beatsalience         -1.394e-05  3.578e-04  -0.039
# eventdensity_shakeit -3.719e-03  1.316e-03  -2.827
# rmsStd                3.715e-03  4.401e-03   0.844
# flux_0_50             1.087e-04  2.297e-04   0.473
# flux_50_100          -5.396e-04  5.707e-04  -0.946
# flux_100_200          4.448e-02  1.996e-02   2.229
# 
# Correlation of Fixed Effects:
#             (Intr) btslnc evntd_ rmsStd f_0_50 f_50_1
# beatsalienc -0.406                                   
# evntdnsty_s -0.247 -0.514                            
# rmsStd      -0.503  0.197 -0.271                     
# flux_0_50   -0.149 -0.041  0.214  0.014              
# flux_50_100  0.150  0.008 -0.140 -0.054 -0.983       
# flx_100_200  0.153  0.130 -0.316 -0.314  0.291 -0.415

# Tapping Model (Tapping) ====
tap.base  <- lmer(variability ~ 1 + (1|id), data=tap.all, REML=FALSE)
tap.model <- lmer(variability ~
                  pulseclarity +
                  percussiveness +
                  flux_0_50 +
                  flux_50_100 +
                  flux_100_200 +
                  (1|id),
                data=tap.all,
                REML=FALSE)

# anova ####
anova(tap.base, tap.model)
# Data: tap.all
# Models:
# tap.base: variability ~ 1 + (1 | id)
# tap.model: variability ~ pulseclarity + percussiveness + flux_0_50 + flux_50_100 + 
# tap.model:     flux_100_200 + (1 | id)
#           Df     AIC     BIC logLik deviance  Chisq Chi Df Pr(>Chisq)
# tap.base   3 -2655.8 -2640.8 1330.9  -2661.8                         
# tap.model  8 -2749.0 -2709.1 1382.5  -2765.0 103.21      5  < 2.2e-16
#              
# tap.base     
# tap.model ***
# ---
# Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

# summary ####
summary(tap.model)
# Linear mixed model fit by maximum likelihood  ['lmerMod']
# Formula: 
# variability ~ pulseclarity + percussiveness + flux_0_50 + flux_50_100 +  
#     flux_100_200 + (1 | id)
#    Data: tap.all
# 
#      AIC      BIC   logLik deviance df.resid 
#  -2749.0  -2709.1   1382.5  -2765.0     1084 
# 
# Scaled residuals: 
#     Min      1Q  Median      3Q     Max 
# -2.5717 -0.5894 -0.2392  0.2973  3.8533 
# 
# Random effects:
#  Groups   Name        Variance Std.Dev.
#  id       (Intercept) 0.002024 0.04498 
#  Residual             0.004247 0.06517 
# Number of obs: 1092, groups:  id, 37
# 
# Fixed effects:
#                  Estimate Std. Error t value
# (Intercept)     0.0698128  0.0173701   4.019
# pulseclarity    0.0072182  0.0015333   4.708
# percussiveness -0.0059724  0.0009104  -6.560
# flux_0_50       0.0349634  0.0126186   2.771
# flux_50_100    -0.0822303  0.0311663  -2.638
# flux_100_200    1.7365233  0.9923175   1.750
# 
# Correlation of Fixed Effects:
#             (Intr) plsclr prcssv f_0_50 f_50_1
# pulseclarty -0.746                            
# percussvnss -0.351  0.128                     
# flux_0_50   -0.075 -0.016  0.294              
# flux_50_100  0.025  0.075 -0.211 -0.982       
# flx_100_200  0.010 -0.205 -0.336  0.329 -0.485

# Tapping Model (Entrainment) ====
eeg.base  <- lmer(en ~ 1 + (1|id), data=eeg.all, REML=FALSE)
eeg.model <- lmer(en ~
                  pulseclarity +
                  percussiveness +
                  flux_0_50 +
                  flux_50_100 +
                  flux_100_200 +
                  (1|id),
                data=eeg.all,
                REML=FALSE)

# anova ####
anova(eeg.base, eeg.model)
# Data: eeg.all
# Models:
# eeg.base: en ~ 1 + (1 | id)
# eeg.model: en ~ pulseclarity + percussiveness + flux_0_50 + flux_50_100 + 
# eeg.model:     flux_100_200 + (1 | id)
#           Df    AIC    BIC logLik deviance  Chisq Chi Df Pr(>Chisq)  
# eeg.base   3 -12109 -12094 6057.6   -12115                           
# eeg.model  8 -12109 -12069 6062.6   -12125 10.085      5    0.07287 .
# ---
# Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

# summary ####
summary(eeg.model)
# Linear mixed model fit by maximum likelihood  ['lmerMod']
# Formula: 
# en ~ pulseclarity + percussiveness + flux_0_50 + flux_50_100 +  
#     flux_100_200 + (1 | id)
#    Data: eeg.all
# 
#      AIC      BIC   logLik deviance df.resid 
# -12109.2 -12068.7   6062.6 -12125.2     1153 
# 
# Scaled residuals: 
#     Min      1Q  Median      3Q     Max 
# -2.1714 -0.5220 -0.0943  0.2324  9.8596 
# 
# Random effects:
#  Groups   Name        Variance  Std.Dev. 
#  id       (Intercept) 5.977e-07 0.0007731
#  Residual             1.567e-06 0.0012520
# Number of obs: 1161, groups:  id, 39
# 
# Fixed effects:
#                  Estimate Std. Error t value
# (Intercept)     7.520e-04  3.185e-04   2.361
# pulseclarity    1.351e-05  2.863e-05   0.472
# percussiveness  4.212e-05  1.697e-05   2.482
# flux_0_50       4.479e-04  2.346e-04   1.909
# flux_50_100    -1.126e-03  5.792e-04  -1.945
# flux_100_200    1.106e-02  1.841e-02   0.601
# 
# Correlation of Fixed Effects:
#             (Intr) plsclr prcssv f_0_50 f_50_1
# pulseclarty -0.760                            
# percussvnss -0.357  0.127                     
# flux_0_50   -0.072 -0.021  0.297              
# flux_50_100  0.021  0.080 -0.214 -0.982       
# flx_100_200  0.013 -0.207 -0.338  0.326 -0.482

# Stepwise Model (Entrainment) ====
eeg.base  <- lmer(en ~ 1 + (1|id), data=eeg.all, REML=FALSE)
eeg.model <- lmer(en ~ beatsalience +
                  eventdensity_shakeit +
                  rmsStd +
                  pulseclarity +
                  percussiveness +
                  flux_0_50 +
                  flux_50_100 +
                  flux_100_200 +
                  (1|id),
                data=eeg.all,
                REML=FALSE)

# anova ####
anova(eeg.base, eeg.model)
# Data: eeg.all
# Models:
# eeg.base: en ~ 1 + (1 | id)
# eeg.model: en ~ beatsalience + eventdensity_shakeit + rmsStd + pulseclarity + 
# eeg.model:     percussiveness + flux_0_50 + flux_50_100 + flux_100_200 + 
# eeg.model:     (1 | id)
#           Df    AIC    BIC logLik deviance  Chisq Chi Df Pr(>Chisq)  
# eeg.base   3 -12109 -12094 6057.6   -12115                           
# eeg.model 11 -12111 -12055 6066.5   -12133 17.906      8    0.02194 *
# ---
# Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

# summary ####
summary(eeg.model)
# Linear mixed model fit by maximum likelihood  ['lmerMod']
# Formula: 
# en ~ beatsalience + eventdensity_shakeit + rmsStd + pulseclarity +  
#     percussiveness + flux_0_50 + flux_50_100 + flux_100_200 +  
#     (1 | id)
#    Data: eeg.all
# 
#      AIC      BIC   logLik deviance df.resid 
# -12111.0 -12055.4   6066.5 -12133.0     1150 
# 
# Scaled residuals: 
#     Min      1Q  Median      3Q     Max 
# -2.1296 -0.5174 -0.1044  0.2291  9.8266 
# 
# Random effects:
#  Groups   Name        Variance  Std.Dev. 
#  id       (Intercept) 5.977e-07 0.0007731
#  Residual             1.557e-06 0.0012476
# Number of obs: 1161, groups:  id, 39
# 
# Fixed effects:
#                        Estimate Std. Error t value
# (Intercept)           1.378e-03  4.195e-04   3.285
# beatsalience         -5.901e-05  3.584e-04  -0.165
# eventdensity_shakeit -3.392e-03  1.447e-03  -2.343
# rmsStd                7.270e-04  4.722e-03   0.154
# pulseclarity          3.774e-05  3.091e-05   1.221
# percussiveness        2.481e-05  1.872e-05   1.325
# flux_0_50             1.970e-04  2.513e-04   0.784
# flux_50_100          -6.365e-04  6.038e-04  -1.054
# flux_100_200          3.560e-02  2.130e-02   1.672
# 
# Correlation of Fixed Effects:
#             (Intr) btslnc evntd_ rmsStd plsclr prcssv f_0_50 f_50_1
# beatsalienc -0.331                                                 
# evntdnsty_s -0.256 -0.483                                          
# rmsStd      -0.259  0.210 -0.284                                   
# pulseclarty -0.315 -0.036 -0.190 -0.245                            
# percussvnss -0.333 -0.070  0.357 -0.291  0.083                     
# flux_0_50   -0.209 -0.059  0.345 -0.069 -0.108  0.383              
# flux_50_100  0.166  0.021 -0.258 -0.008  0.159 -0.275 -0.978       
# flx_100_200  0.233  0.144 -0.403 -0.182  0.012 -0.350  0.109 -0.263

# Plots ----
# Ratings Model ====
# ratings, entrainment, evtvar ####
p <- ggplot(data=all.avg, aes(move, en_norm))
p + geom_point(aes(size=eventdensity_shakeit)) +
  labs(x="Ratings of Wanting to Move",
       y="Premotor Entrainment (normalized)",
       title="Size is Event Variability") +
  geom_smooth(method="lm", level=0, colour="black") +
  theme(legend.position="none")
if (do.save) {
  ggsave(paste(paperfolder, "mir_en_move_evtvar.png", sep=""), scale=plotscale)
}

# ratings, evtvar ####
p <- ggplot(data=rat.avg, aes(eventdensity_shakeit, move))
p + geom_point() +
  labs(x="Event Variability",
       y="Ratings of Wanting to Move") +
  geom_smooth(method="lm", level=0, colour="black")
if (do.save) {
  ggsave(paste(paperfolder, "mir_mv_evtvar.png", sep=""), scale=plotscale)
}

# entrainment, evtvar ####
p <- ggplot(data=eeg.avg, aes(eventdensity_shakeit, en_norm))
p + geom_point() +
  labs(x="Event Variability",
       y="Premotor Entrainment (normalized)") +
  geom_smooth(method="lm", level=0, colour="black")
if (do.save) {
  ggsave(paste(paperfolder, "mir_en_evtvar.png", sep=""), scale=plotscale)
}

# Tapping Model ====
# tapping, entrainment, perc ####
p <- ggplot(data=all.avg, aes(variability, en_norm))
p + geom_point(aes(size=percussiveness)) +
  labs(x="Tapping Variability",
       y="Premotor Entrainment (normalized)",
       title="Size is Percussiveness") +
  geom_smooth(method="lm", level=0, colour="black") +
  theme(legend.position="none")
if (do.save) {
  ggsave(paste(paperfolder, "mir_en_tap_perc.png", sep=""), scale=plotscale)
}

# tapping, perc ####
p <- ggplot(data=tap.avg, aes(percussiveness, variability))
p + geom_point() +
  labs(x="Percussiveness",
       y="Tapping Variability") +
  geom_smooth(method="lm", level=0, colour="black")
if (do.save) {
  ggsave(paste(paperfolder, "mir_tap_perc.png", sep=""), scale=plotscale)
}


# entrainment, perc ####
p <- ggplot(data=eeg.avg, aes(percussiveness, en_norm))
p + geom_point() +
  labs(x="Percussiveness",
       y="Premotor Entrainment (normalized)") +
  geom_smooth(method="lm", level=0, colour="black")
if (do.save) {
  ggsave(paste(paperfolder, "mir_en_perc.png", sep=""), scale=plotscale)
}

# Exploratory Neural Model ====
# evtvar, perc, en ####
p <- ggplot(data=eeg.avg, aes(eventdensity_shakeit, percussiveness))
p + geom_point(aes(size=en_norm)) +
  labs(x="Event Variability",
       y="Percussiveness",
       title="Size is Premotor Entrainment (normalized)") +
  geom_smooth(method="lm", level=0, colour="black") +
  theme(legend.position="none")
if (do.save) {
  ggsave(paste(paperfolder, "mir_en_evtvar_perc.png", sep=""), scale=plotscale)
}
