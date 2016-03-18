#!/util/academic/R/R-3.0.0/bin/Rscript

# Input: current means, full csv data set
# Output: full csv data set with tab-delimited prepended first column closest cluster id

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

  # output <clustNum \t vec>
  # where vec is comma separated numeric values
  cat(
    closestClust
   ,'\t'
   ,paste(vec,collapse=',')
   ,'\n'
   ,sep=''
  )
}
