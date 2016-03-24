#!/util/academic/R/R-3.0.0/bin/Rscript
# Input arguments:
# [1] EPSILON, the tolerance used to assess convergence
# [2] JOBID, the id of the current SLURM job
# [3] CURR_RUN, the index of the current kmeans run (outer loop)
# [4] CURR_IND, the index of the current kmeans iteration (inner loop)
# [5] OUT_DIR, directory of current means file

# get input arguments
argIn <- commandArgs(TRUE)
EPSILON <- as.numeric(argIn[1])
JOBID <- argIn[2]
CURR_RUN <- as.integer(argIn[3])
CURR_IND <- as.integer(argIn[4])
OUT_DIR <- argIn[5]

# convert output from reducing step (means formatted as plaintext parsed R objects) into actual R object
f <- file("stdin")
open(f)

myMeans <- list()

while (length(line <- readLines(f,n=1)) > 0) {
  this_kvpair <- unlist(strsplit(line,split="\t"))
  myMeans[[this_kvpair[1]]] <- eval(parse(text=this_kvpair[2]))
}

if (length(myMeans) == 0) {
  cat('NA')
  stop(paste('Stopped in iteration ',CURR_IND,'; no means detected.', sep=''))
}
save(myMeans,file=file.path(OUT_DIR,'currentMeans.RData'))

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
    currentMeans[[i]] <- genMean(dataDim) # runif(n=dataDim, min = -2, max = 2)
    warning('Empty mean detected in intermediary script; regenerating.')
  }
}
# make sure to initialize new replacement means if the last clusters were empty
lenPrevMeans <- length(prevMeans)
while( length(currentMeans) < lenPrevMeans ) {
  currentMeans[[length(currentMeans)+1]] <- genMean(dataDim) # runif(n=dataDim, min = -2, max = 2)
  warning('Empty mean detected in intermediary script; regenerating.')
}

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

