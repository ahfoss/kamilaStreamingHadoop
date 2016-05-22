#!/util/academic/R/R-3.0.0/bin/Rscript

# Command-line input argument: NUM_CHUNK, the number of splits associated with each centroid
# Read from file: current means
# Read from stdin: full csv data set in Hadoop streaming framework
# Output: three tab-delimited values: (1) key, (2) Euclidean distance to
# nearest cluster, and (3) comma delimited data vector. The key is (nearest
# centroidid).(chunk id number), where chunk id is an arbitrary integer that
# serves to split the reducer loads among different nodes.

argIn <- commandArgs(TRUE)
NUM_CHUNK <- as.numeric(argIn[1])

# Load current centroid stats
load('currentMeans.RData')

# Evaluate multinomial PMF for one observation
evalOneMultin <- function(obs,thet) thet[obs]

# Evaluate multinomial over several PMFs
# Generates matrix of Q x G probs (Q cat vars and G clusters) and then sums
# log probs over columns to yield a numeric vector of length G with cluster-
# specific log probs.
evalAllMult <- function(dataVec, paramList) {
  probMat <- sapply(
    paramList,
    function(elm) mapply(FUN=evalOneMultin, obs=dataVec, thet=elm[['thetas']])
  )
  clusterCatLogLiks <- apply(probMat, 2, FUN=function(col) sum(log(col)))
  return(clusterCatLogLiks)
}

# Calculate a distance to a centroid and evaluate at kde. Call
# kdeStats$resampler() from outside of the function scope.
evalOneKde <- function(obs, cent) {
  thisDist <- dist(rbind(cent, obs))
  kdeStats$resampler(thisDist)
}
# Calculate distance to each centroid and evaluate at radialKDE
evalAllKde <- function(dataVec, paramList, myKde) {
  probVec <- sapply(
    paramList,
    function(elm) {
      evalOneKde(obs=dataVec, cent=elm[['centroid']])
    }
  )
  return(log(probVec))
}

if (!exists('myMeans') || !exists('kdeStats')) stop("Mean RData file not complete.")

numClusts <- length(myMeans)
numConVars <- length(myMeans[[1]][['centroid']])
numCatVars <- length(myMeans[[1]][['thetas']])

f <- file("stdin")
open(f)
thisChunkNum <- 1
while(length(line <- readLines(f,n=1)) > 0) {
  vec <- as.numeric(unlist(strsplit(line,',')))
  conVec <- vec[1:numConVars]
  catVec <- vec[(numConVars+1):(numConVars+numCatVars)]

  # Get distances to each continuous centroid evaluated at radialKDE, posterior
  # probability of categorical vector, and multiply. Use to assign to best
  # cluster.
  # Continuous distances: Could have stored this the first MR run, but the
  # additional costs of writing all to file is unappealing.
  conLogLiks <- evalAllKde(
    dataVec=conVec,
    paramList=myMeans
  )
  catLogLiks <- evalAllMult(dataVec=catVec, paramList=myMeans)
  objectiveFuns <- conLogLiks + catLogLiks
  closestCent <- which.max(objectiveFuns)
  eucDist <- dist(rbind(
    conVec,
    myMeans[[closestCent]][['centroid']]
  ))

  # output <clustNum \t vec>
  # where vec is comma separated numeric values
  cat(
    paste(closestCent,thisChunkNum,sep='.')
   ,'\t'
   ,eucDist
   ,'\t'
   ,paste(vec,collapse=',')
   ,'\n'
   ,sep=''
  )

  # Flip chunk number
  thisChunkNum <- thisChunkNum %% NUM_CHUNK + 1
}
