#!/usr/bin/env Rscript

# Calculate cluster-level means
# write out file:
# 1 \t "robj"
# 2 \t "robj"
# ...
#
# where first col is cluster id, and robj is deparsed centroid object

f <- file("stdin")
open(f)

logClusterInfo <- function(clusterNum,robj) {
  cat(clusterNum,'\t',deparse(robj),'\n')
}

last_key <- Inf
clustCount <- 0

while(length(line <- readLines(f,n=1)) > 0) {
  this_kvpair <- unlist(strsplit(line,split="\t"))
  this_key <- this_kvpair[1]
  value <- as.numeric(unlist(strsplit(this_kvpair[2],split=",")))

  if (last_key == this_key) {
    running_total <- running_total + value
    clustCount <- clustCount + 1
  } else {
    if (last_key!=Inf) {
      logClusterInfo(last_key,running_total/clustCount)
      #cat(
      #  last_key
      # ,'\t'
      # ,paste(running_total/clustCount,collapse=',')
      # ,'\n'
      #)
    }
    running_total <- value
    clustCount <- 1
    last_key <- this_key
  }

}

if (last_key == this_key) {
  logClusterInfo(last_key,running_total/clustCount)
  #cat(
  #  last_key
  # ,'\t'
  # ,paste(running_total/clustCount,collapse=',')
  # ,'\n'
  #)
}


