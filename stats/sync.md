# This is a test

Below is some code for a sync plot.


```r
source("sync_functions.R")
dt <- sync.load.tapping(paste(folder, "ent_sync.csv", sep=""))
dp <- de[, .(normmax=mean(normmax), se=sd(normmax)/sqrt(length(normmax))),
         by=.(syncopation_degree)]
```

```
## Error in eval(bysub, x, parent.frame()): object 'syncopation_degree' not found
```

```r
ggplot(data=dp, aes(x=syncopation_degree,
                    y=normmax,
                    fill=syncopation_degree)) +
  geom_col() +
  geom_errorbar(aes(ymax = dp$normmax + dp$se,
                   ymin = dp$normmax - dp$se), width=0.1) +
  geom_signif(data=de,
              comparisons = list(c("low", "high")),
              test="t.test",
              step_increase = 0.05,
              margin_top = -0.8,
              tip_length = 0.007,
              map_signif_level=TRUE) +
  labs(x = "Syncopation Degree", y = "Neural Entrainment") +
  scale_fill_grey(start=0.8, end=0.2) +
  theme(legend.position="none") +
  coord_cartesian(ylim=yl)
```

```
## Error in ggplot(data = dp, aes(x = syncopation_degree, y = normmax, fill = syncopation_degree)): object 'dp' not found
```

In conclusion, let's see if this works.
