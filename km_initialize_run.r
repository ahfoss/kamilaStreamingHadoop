#!/util/academic/R/R-3.0.0/bin/Rscript

# Input arguments:
# [1] DATA_DIM, the dimensionality (i.e. number of variables) in the data set.
# [2] NUM_CLUST, the number of clusters in the data
# [3] OUT_DIR, the pathway for the output

# Could add functionality to accept a random seed, but for now instead we just
# save the initialized means and re-use if necessary.

# get input args
argIn <- commandArgs(TRUE)
DATA_DIM <- as.integer(argIn[1])
NUM_CLUST <- as.integer(argIn[2])
OUT_DIR <- argIn[3]

myMeans <- list()
for (i in 1:NUM_CLUST) {
  myMeans[[i]] <- runif(n = DATA_DIM, min = -3, max = 3)
}

dir.create(OUT_DIR)
save(myMeans, file=file.path(OUT_DIR, 'currentMeans.RData')) # iteratively updated file
save(myMeans, file=file.path(OUT_DIR, 'initialMeans.RData')) # permanent log file

