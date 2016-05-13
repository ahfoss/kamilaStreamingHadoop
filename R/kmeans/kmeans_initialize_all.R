#!/util/academic/R/R-3.0.0/bin/Rscript

# These objects and functions are only intended to be used by kmeans.slurm.
#
# This creates a preselected and pseudo-randomized object that contains all
# centroids that may be used for initializing the kmeans runs. Randomization
# is controlled by the input seed. If, during the kmeans runs, the number of
# centroids is exhausted, they are re-randomized and reused. Centroids are
# from a random subset of points in the larger data set.

# Input arguments:
# [1] SEED, an integer giving the initial seed for R's RNG state.
# [2] OUT_DIR, where the RData file will be saved.
# [3] SUBSAMP, the directory and filename of a csv subsampled version of the 
#     data set of interest.

argIn <- commandArgs(TRUE)
INITIAL_SEED <- as.integer(argIn[1])
OUT_DIR <- argIn[2]
SUBSAMP <- argIn[3]

set.seed(INITIAL_SEED)

subsampledData <- read.csv(SUBSAMP)

# generate randomly permuted row indices
randInds <- sample(nrow(subsampledData))

# create list to hold all info needed to generate random vecs
# selectedVec: the current row of data; corresponds to first element of inds
# inds: index of subsampled data in random order
# data: the data inds maps onto
currentQueue <- list(
  selectedVec = NULL,
  inds = randInds,
  data = subsampledData
)

# create function to advance the queue and return a vec
advanceQueue <- function(queue) {
  # if the current inds is empty, regenerate
  if (length(queue$inds) == 0) {
    queue$inds <- sample(nrow(queue$data))
  }
  # pull the first ind
  thisInd <- queue$inds[1]
  queue$inds <- queue$inds[-1]
  # access and store the selected vector
  queue$selectedVec <- as.numeric(queue$data[thisInd,])
  return(queue)
}

save(
  .Random.seed,
  currentQueue,
  advanceQueue,
  file=file.path(OUT_DIR, 'seeding.RData')
)

