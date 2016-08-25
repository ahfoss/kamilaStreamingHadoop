
# Generate a sample data set for demo'ing kamila.slurm
require(mvtnorm)

set.seed(2)


# create data directory
suppressWarnings(dir.create('csv'))

# small mixed data set
clustSize <- 5 * 10^3
ndim <- 5
mu2 <- 3

dat <- data.frame(
  Con1 = c(rnorm(clustSize),rnorm(clustSize,mean=mu2)),
  Disc1 = c(
    sample(c('puma','lion','tiger','serval'),size=clustSize,replace=T),
    sample(c('puma','lion'),size=clustSize,replace=T)
  ),
  Con2 = c(runif(clustSize), runif(clustSize,min=0.5,max=1.5)),
  Disc2 = c(
    sample(c('common','very common'),size=2*clustSize - 7,replace=TRUE),
    rep('rare',4),
    rep('super rare', 3)
  ),
  Disc3 = sample(paste('lev',1:15,sep=''),size=2*clustSize,replace=TRUE)
)

# Add a few missing values to the continuous variables
dat[2,'Con1'] <- NA
dat[5,'Con2'] <- NA
dat[8,'Con1'] <- NA
dat[12,'Con2'] <- NA
dat[20,'Con2'] <- NA

write.table(
  dat,
  file = 'csv/sample.csv',
  row.names=FALSE,
  col.names=TRUE,
  sep=','
)

