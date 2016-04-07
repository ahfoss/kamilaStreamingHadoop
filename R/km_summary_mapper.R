#!/util/academic/R/R-3.0.0/bin/Rscript

# Command-line input argument: NUM_CHUNK, the number of splits associated with each centroid
# Read from file: current means
# Read from stdin: full csv data set in Hadoop streaming framework
# Output: cluster membership, squared Euclidean distance to respective centroid; tab delimited

argIn <- commandArgs(TRUE)
NUM_CHUNK <- as.numeric(argIn[1])

load('currentMeans.RData')
if (!exists('myMeans')) stop("Mean RData file not found")
nMeans <- length(myMeans)

f <- file("stdin")
open(f)
thisChunkNum <- 1
while(length(line <- readLines(f,n=1)) > 0) {
  vec <- as.numeric(unlist(strsplit(line,',')))

  # Get nearest cluster number
  smallestDist <- Inf
  closestClust <- -1
  for (i in 1:nMeans) {
    ithDist <- dist(rbind(myMeans[[i]],vec))
    if (ithDist < smallestDist) {
      smallestDist <- ithDist
      closestClust <- i
    }
  }

  # get squared euclidean distance
  squaredEucDist <- smallestDist^2

  # output <clustNum \t dist>
  cat(
    paste(closestClust,thisChunkNum,sep='.')
   ,'\t'
   ,squaredEucDist
   ,'\t'
   ,paste(vec,collapse=',')
   ,'\n'
   ,sep=''
  )

  # Flip chunk number
  thisChunkNum <- thisChunkNum %% NUM_CHUNK + 1
}
