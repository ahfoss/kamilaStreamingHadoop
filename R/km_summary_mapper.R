#!/util/academic/R/R-3.0.0/bin/Rscript

# Input: current means, full csv data set
# Output: cluster membership, squared Euclidean distance to respective centroid; tab delimited

load('currentMeans.RData')
if (!exists('myMeans')) stop("Mean RData file not found")
nMeans <- length(myMeans)

f <- file("stdin")
open(f)
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
    closestClust
   ,'\t'
   ,squaredEucDist
   ,'\t'
   ,paste(vec,collapse=',')
   ,'\n'
   ,sep=''
  )
}
