#!/util/academic/R/R-3.0.0/bin/Rscript
# Input arguments:
# [1] EPSILON, the tolerance used to assess convergence
# [2] JOBID, the id of the current SLURM job
# [3] CURR_RUN, the index of the current kmeans run (outer loop)
# [4] CURR_IND, the index of the current kmeans iteration (inner loop)
# [5] OUT_DIR, directory of current means file

source('./R/helperFunctions.R') # for genMean()

# get input arguments
argIn <- commandArgs(TRUE)
EPSILON <- as.numeric(argIn[1])
JOBID <- argIn[2]
CURR_RUN <- as.integer(argIn[3])
CURR_IND <- as.integer(argIn[4])
OUT_DIR <- argIn[5]

# convert output from reducing step (centroid totals formatted as plaintext parsed R objects) into actual R object
f <- file("stdin")
open(f)

myTotals <- list()
myCounts <- c()

# Functions to update totals and counts, while preserving NULL/NA values
# for empty clusters.
updateTotalList <- function(totalList, newVal, keyInt) {
  # if key greater than length, insert new value and done
  if (keyInt > length(totalList)) {
    totalList[[keyInt]] <- newVal
    return(totalList)
  }
  # if existing position is NULL, insert new value and done
  if (is.null(totalList[[keyInt]])) {
    totalList[[keyInt]] <- newVal
    return(totalList)
  }
  # otherwise, add existing to new value and done
  totalList[[keyInt]] <- totalList[[keyInt]] + newVal
  return(totalList)
}
updateCountVec <- function(countVec, newVal, keyInt) {
  # if key greater than length, insert new value and done
  if (keyInt > length(countVec)) {
    countVec[keyInt] <- newVal
    return(countVec)
  }
  # if existing position is NA, insert new value and done
  if (is.na(countVec[keyInt])) {
    countVec[keyInt] <- newVal
    return(countVec)
  }
  # otherwise, add existing to new value and done
  countVec[keyInt] <- countVec[keyInt] + newVal
  return(countVec)
}

while (length(line <- readLines(f,n=1)) > 0) {
  this_kvtuple <- unlist(strsplit(line,split="\t"))
  keysplit <- unlist(strsplit(this_kvtuple[1], split="\\."))
  key1 <- as.integer(keysplit[1])
  centroidTotals <- eval(parse(text=this_kvtuple[2]))
  centroidCount <- as.numeric(this_kvtuple[3])
  # tally totals, counts
  myTotals <- updateTotalList(myTotals, centroidTotals, key1)
  myCounts <- updateCountVec (myCounts, centroidCount,  key1)
}

if (length(myTotals) == 0) {
  cat('NA')
  stop(paste('Stopped in iteration ',CURR_IND,'; no means detected.', sep=''))
}

# now loop through totals,counts to calculate myMeans
# in the event of empty clusters, NULLs propagate correctly.
myMeans <- list()
for (i in 1:length(myTotals)) {
  if (is.null(myTotals[[i]])) next
  myMeans[[i]] <- myTotals[[i]] / myCounts[i]
}

# check convergence using input
currentMeans <- myMeans
rm(myMeans)

# load previous means. Yes, index of RData file is one plus the index of the
# iter_[0-9]+ directory that contains it.
# Loaded file contains the variable stored as "myMeans"
load(file.path(
  paste('myoutput-',JOBID,sep=''),
  paste('run_',CURR_RUN,sep=''),
  paste('iter_',CURR_IND - 1,sep=''),
  paste('currentMeans_i',CURR_IND,'.RData',sep='')
))
prevMeans <- myMeans

# If a cluster had zero points, initialize new random replacements
dataDim <- length(prevMeans[[1]])
for (i in 1:length(currentMeans)) {
  if (length(currentMeans[[i]]) == 0) {
    #print(currentMeans)
    currentMeans[[i]] <- genMean(dataDim) # runif(n=dataDim, min = -2, max = 2)
    #print(currentMeans)
    warning('Empty internal centroid detected in intermediary script; regenerating: number of empty elements is now ',sum(vapply(currentMeans,is.null,NA)),'.')
  }
}
# make sure to initialize new replacement means if the last clusters were empty
lenPrevMeans <- length(prevMeans)
while( length(currentMeans) < lenPrevMeans ) {
  #print(currentMeans)
  currentMeans[[length(currentMeans)+1]] <- genMean(dataDim) # runif(n=dataDim, min = -2, max = 2)
  #print(currentMeans)
  warning('Empty final centroid detected in intermediary script; regenerating: length is now ',length(currentMeans),'.')
}

myMeans <- currentMeans
save(myMeans,file=file.path(OUT_DIR,'currentMeans.RData'))

# calculate and output the objective function
l1_norm <- function(x1, x2) {
  sum(abs(x1-x2))
}

objectiveFun <- 0
for (i in 1:length(currentMeans)) {
  objectiveFun <- objectiveFun + l1_norm(currentMeans[[i]],prevMeans[[i]])
}

# write to stdout
cat(objectiveFun)
#}

