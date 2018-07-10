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

# load data ====
# dr for ratings avg (blocks), dt for tapping, de for neural entrainment
de <- mir.load.eeg(paste(folder, "en_mir_eeg.csv", sep=""))
dt <- mir.load.tapping(paste(folder, "ent_mir.csv", sep=""))
dr <- rbind(dt[, c("id", "stim", "task", "trial", "portcode", "move")],
            de[, c("id", "stim", "task", "trial", "portcode", "move")])
dt$id <- factor(dt$id) # don't know why this one defaults to integer
# collapse tempo and summarise by drum pattern
patterns <- read.csv(paste(folder, "mir_portcode_patterns.csv", sep=""))
dr <- merge(dr, patterns, by="portcode")
dt <- merge(dt, patterns, by="portcode")
de <- merge(de, patterns, by="portcode")
dr <- dr[, list(move=mean(move)), by=.(id, pattern)]
dt <- dt[, list(move=mean(move),
                duration=mean(duration),
                velocity=mean(velocity),
                asynchrony=mean(asynchrony),
                coeffofvar=mean(coeffofvar),
                variability=mean(variability)),
         by=.(id, pattern)]
de <- de[, list(move=mean(move),
                en=mean(en),
                normmax = mean(normmax)),
         by=.(id, pattern)]
da <- merge(dt, de, by=c("id", "pattern"))
da <- da[, move:=mean(c(move.x, move.y)), by=c("id", "pattern")]
da <- subset(da, select=-c(move.x, move.y))
# add mir features
mir  <- data.table(read.csv(paste(folder, "features.csv", sep="")))
mir <- mir[, c("portcode", "tempo"):=NULL]
mir <- mir[, lapply(.SD, mean), by=pattern]
# merge features with data
dr <- merge(dr, mir, by="pattern")
dt <- merge(dt, mir, by="pattern")
de <- merge(de, mir, by="pattern")
da <- merge(da, mir, by="pattern")
# collapse id so we're looking at the patterns
dr <- dr[, id:=NULL]
dr <- dr[, lapply(.SD, mean), by=pattern]
dt <- dt[, id:=NULL]
dt <- dt[, lapply(.SD, mean), by=pattern]
de <- de[, id:=NULL]
de <- de[, lapply(.SD, mean), by=pattern]
da <- da[, id:=NULL]
da <- da[, lapply(.SD, mean), by=pattern]

# collapse pattern and summarise by tempo

# Stats ----
# Ratings Model ====
# Ratings ####
ratings.model <- lm(move ~
                    beatsalience +           # Madison2011
                    eventdensity_shakeit +   # Madison2011
                    rmsStd +                 # Stupacher2016
                    flux_0_50 +              # Stupacher2016
                    flux_50_100 +            # Stupacher2016
                    flux_100_200,            # Stupacher2016
                    data=dr)

summary(ratings.model)

# Entrainment with ratings model ####
en.ratings.model <- lm(normmax ~
                       beatsalience +           # Madison2011
                       eventdensity_shakeit +   # Madison2011
                       rmsStd +                 # Stupacher2016
                       flux_0_50 +              # Stupacher2016
                       flux_50_100 +            # Stupacher2016
                       flux_100_200,            # Stupacher2016
                       data=de)

en.ratings.model.step <- step(en.ratings.model, direction="both")
summary(en.ratings.model.step)

summary(en.ratings.model)

# Tapping model ====
# Tapping model ####
tapping.model  <- lm(variability ~
                     pulseclarity +   # Burger2012
                     percussiveness + # Burger2012
                     flux_0_50 +      # Burger2012, Stupacher2016
                     flux_50_100 +    # Burger2012, Stupacher2016
                     flux_100_200,    # Burger2012, Stupacher2016
                     data=dt)

summary(tapping.model)

# Entrainment with tapping model ####
en.tapping.model  <- lm(normmax ~
                        pulseclarity +   # Burger2012
                        percussiveness + # Burger2012
                        flux_0_50 +      # Burger2012, Stupacher2016
                        flux_50_100 +    # Burger2012, Stupacher2016
                        flux_100_200,    # Burger2012, Stupacher2016
                        data=de)

summary(en.tapping.model)

# Entrainment Model (stepwise known features) ====
df <- subset(de,
             select=c(normmax,
                      beatsalience,
                      pulseclarity,
                      eventdensity_shakeit,
                      percussiveness,
                      rmsStd,
                      flux_0_50,
                      flux_50_100,
                      flux_100_200))

en     <- lm(normmax ~ ., data=df)
en.step <- step(en, direction="both")

summary(en.step)

en.step$anova

# Entrainment Model (stepwise all features) ====
df <- subset(de,
             select=c(normmax,
               beatsalience,
               pulseclarity,
               eventdensity_shakeit,
               eventdensity_mir,
               rms,
               rmsStd,
               percussiveness,
               fluctuation,
               lowenergy,
               flux,
               flux_0_50,
               flux_50_100,
               flux_100_200,
               flux_200_400,
               flux_400_800,
               flux_800_1600,
               flux_1600_3200,
               flux_3200_6400,
               flux_6400_12800,
               flux_12800_22050))

en.all <- lm(normmax ~ ., data=df)
en.all.step <- step(en.all, direction="both")

summary(en.all.step)

en.all.step$anova

# Entrainment Correlations ====
df <- subset(de, select=c(en,
                          beatsalience,
                          pulseclarity,
                          eventdensity_shakeit,
                          percussiveness,
                          rmsStd,
                          flux_0_50,
                          flux_50_100,
                          flux_100_200))

cortable(df)

en.cor.model <- lm(normmax ~
                    eventdensity_shakeit +
                    percussiveness,
                    data=de)

summary(en.cor.model)

# Entrainment uncorrelated variables ====
summary(lm(en ~
           eventdensity_shakeit +
           percussiveness,
         data = de[de$harmonic==1]))

summary(step(lm(en ~
           pulseclarity +
           rmsStd +
           percussiveness +
           fluctuation +
           flux,
         data = de[de$harmonic==1])), direction="both")

# Plots ----
# Ratings Model ====
# ratings, entrainment, evdy ####
p <- ggplot(data=da, aes(move, normmax))
p + geom_point(aes(size=eventdensity_shakeit)) +
  labs(x="Ratings of Wanting to Move",
       y="Premotor Entrainment (μV)",
       title="Size is Event Variability") +
  geom_smooth(method="lm", level=0) +
  theme(legend.position="none")
if (do.save) {
  ggsave(paste(paperfolder, "mir_en_move_evdy.png", sep=""), scale=plotscale)
}

# ratings, evdy ####
p <- ggplot(data=dr, aes(eventdensity_shakeit, move))
p + geom_point() +
  labs(x="Event Variability",
       y="Ratings of Wanting to Move") +
  geom_smooth(method="lm", level=0)
if (do.save) {
  ggsave(paste(paperfolder, "mir_mv_evdy.png", sep=""), scale=plotscale)
}

p <- ggplot(data=dr, aes(eventdensity_mir, move))
p + geom_point() +
  labs(x="Event Density",
       y="Ratings of Wanting to Move") +
  geom_smooth(method="lm", level=0)
if (do.save) {
  ggsave(paste(paperfolder, "mir_mv_evdymir.png", sep=""), scale=plotscale)
}

# entrainment, evdy ####
p <- ggplot(data=de, aes(eventdensity_shakeit, normmax))
p + geom_point() +
  labs(x="Event Variability",
       y="Premotor Entrainment (μV)") +
  geom_smooth(method="lm", level=0)
if (do.save) {
  ggsave(paste(paperfolder, "mir_en_evdy.png", sep=""), scale=plotscale)
}

p <- ggplot(data=de, aes(eventdensity_mir, normmax))
p + geom_point() +
  labs(x="Event Density",
       y="Premotor Entrainment (μV)") +
  geom_smooth(method="lm", level=0)
if (do.save) {
  ggsave(paste(paperfolder, "mir_en_evdymir.png", sep=""), scale=plotscale)
}

# Tapping Model ====
# tapping, entrainment, perc ####
p <- ggplot(data=da, aes(variability, normmax))
p + geom_point(aes(size=percussiveness)) +
  labs(x="Tapping Variability",
       y="Premotor Entrainment (μV)",
       title="Size is Percussiveness") +
  geom_smooth(method="lm", level=0) +
  theme(legend.position="none")
if (do.save) {
  ggsave(paste(paperfolder, "mir_en_tap_perc.png", sep=""), scale=plotscale)
}

# tapping, entrainment, pattern ####
p <- ggplot(data=da[da$id==19], aes(variability, normmax))
p + geom_point(aes(colour=id)) +
  labs(x="Tapping Variability",
       y="Normalized Premotor Entrainment",
       colour="ID")

if (do.save) {
  ggsave(paste(paperfolder, "mir_en_tap_pattern.png", sep=""), scale=plotscale)
}

# tapping, perc ####
p <- ggplot(data=dt, aes(percussiveness, variability))
p + geom_point() +
  labs(x="Percussiveness",
       y="Tapping Variability") +
  geom_smooth(method="lm", level=0)
if (do.save) {
  ggsave(paste(paperfolder, "mir_tap_perc.png", sep=""), scale=plotscale)
}

# tapping, tempo ####
p <- ggplot(data=dt2, aes(tempo, variability))
p + geom_point() +
  labs(x="Tempo",
       y="Tapping Variability") +
  geom_smooth(method="lm", level=0)
if (do.save) {
  ggsave(paste(paperfolder, "mir_tap_tempo.png", sep=""), scale=plotscale)
}

# entrainment, perc ####
p <- ggplot(data=de, aes(percussiveness, normmax))
p + geom_point() +
  labs(x="Percussiveness",
       y="Premotor Entrainment (μV)") +
  geom_smooth(method="lm", level=0)
if (do.save) {
  ggsave(paste(paperfolder, "mir_en_perc.png", sep=""), scale=plotscale)
}

# Exploratory Neural Model ====
# evdy, perc, en ####
p <- ggplot(data=de, aes(eventdensity_shakeit, percussiveness))
p + geom_point(aes(size=normmax)) +
  labs(x="Event Variability",
       y="Percussiveness",
       title="Size is Premotor Entrainment") +
  geom_smooth(method="lm", level=0) +
  theme(legend.position="none")
if (do.save) {
  ggsave(paste(paperfolder, "mir_en_evdy_perc.png", sep=""), scale=plotscale)
}

# Others ====

p <- ggplot(data=dr, aes(pattern, move))
p + geom_point(aes(color=factor(tempo)))

dp <- dr[, .(move=mean(move),
             eventdensity=mean(eventdensity_shakeit)), by="pattern"]

p <- ggplot(data=dp, aes(pattern, move))
p + geom_point(aes(size=eventdensity))


p <- ggplot(data=da, aes(asynchrony, normmax))
p + geom_point(aes(colour=move)) +
  labs(y="Premotor Entrainment (μV)",
       x="Tapping Asynchrony",
       colour="Ratings of Wanting to Move")

sync.inverted.u(da, "normmax", "asynchrony")
