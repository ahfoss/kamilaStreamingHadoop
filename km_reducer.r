#!/util/academic/R/R-3.0.0/bin/Rscript

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
  cat(clusterNum,'\t',deparse(robj),'\n',sep='')
}

last_key <- Inf

# running tally of observations used in current sum
clustCount <- 0

while(length(line <- readLines(f,n=1)) > 0) {
  this_kvpair <- unlist(strsplit(line,split="\t"))
  this_key <- this_kvpair[1]
  value <- as.numeric(unlist(strsplit(this_kvpair[2],split=",")))

  if (last_key == this_key) {
    # executed if still within same cluster
    running_total <- running_total + value
    clustCount <- clustCount + 1
  } else {
    # executed when ending a cluster or starting the first
    if (last_key!=Inf) {
      # executed when ending a cluster
      logClusterInfo(last_key,running_total/clustCount)
    }
    # executed when starting the first cluster
    running_total <- value
    clustCount <- 1
    last_key <- this_key
  }

}

if (last_key == this_key) {
  logClusterInfo(last_key,running_total/clustCount)
}


