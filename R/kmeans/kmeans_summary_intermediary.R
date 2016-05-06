#!/util/academic/R/R-3.0.0/bin/Rscript

# Two input argument:
# [1] IN_FILE, the input tsv file to collapse; this file has counts, sums, mins,
# and maxs for each chunk of each cluster which need to be combined and
# aggregated appropriately within cluster.
# [2] OUT_FILE, the output tsv file.

# get input arguments
argIn <- commandArgs(TRUE)
if (length(argIn) < 2) stop('Insufficient number of args passed to km_summary_intermediary.R')
IN_FILE <- argIn[1]
OUT_FILE <- argIn[2]

dat <- read.table(IN_FILE, sep='\t', header=TRUE,stringsAsFactors=FALSE)

spl <- strsplit(as.character(dat$ClusterNumber),split='.',fixed=TRUE)
clustNum <- unlist(lapply(spl,'[',1))

collapsedDat <- data.frame(
  ClusterNumber = as.numeric(unique(clustNum)),
  ClusterSize = tapply(
    X = dat$ClusterSize,
    INDEX = factor(clustNum),
    FUN = sum
  )
)
collapsedDat$SSQ <- tapply(
  X = dat$SSQ,
  INDEX = factor(clustNum),
  FUN = sum
)

collapsedDat$minvec <- tapply(
  X = dat$minvec,
  INDEX = factor(clustNum),
  FUN = function(vec) {
    spl <- strsplit(vec,split=',') # spl is a list of character vectors
    # numList: a numeric matrix; cols of numList correspond to slots of spl
    numList <- sapply(spl, as.numeric)
    clustMins <- apply(numList,1,min)
    return(paste(clustMins,collapse=','))
  }
)
collapsedDat$sumvec <- tapply(
  X = dat$sumvec,
  INDEX = factor(clustNum),
  FUN = function(vec) {
    spl <- strsplit(vec,split=',') # spl is a list of character vectors
    # numList: a numeric matrix; cols of numList correspond to slots of spl
    numList <- sapply(spl, as.numeric)
    clustSums <- apply(numList,1,sum)
    return(paste(clustSums,collapse=','))
  }
)
collapsedDat$maxvec <- tapply(
  X = dat$maxvec,
  INDEX = factor(clustNum),
  FUN = function(vec) {
    spl <- strsplit(vec,split=',') # spl is a list of character vectors
    # numList: a numeric matrix; cols of numList correspond to slots of spl
    numList <- sapply(spl, as.numeric)
    clustMaxs <- apply(numList,1,max)
    return(paste(clustMaxs,collapse=','))
  }
)
# sumMat: numeric matrix, where each col corresponds to a cluster
sumMat <- sapply(strsplit(collapsedDat$sumvec,split=','), as.numeric)
countMat <- matrix(collapsedDat$ClusterSize,nrow=nrow(sumMat),ncol=ncol(sumMat),byrow=TRUE)
meanMat <- sumMat / countMat
collapsedDat$meanvec <- apply(meanMat, 2, function(vec) paste(vec,collapse=','))

write.table(
  collapsedDat,
  file=OUT_FILE,
  append=FALSE,
  sep='\t',
  quote=FALSE,
  row.names=FALSE,
  col.names=TRUE
)
