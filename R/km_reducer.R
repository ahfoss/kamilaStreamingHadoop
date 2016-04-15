#!/util/academic/R/R-3.0.0/bin/Rscript

# Calculate cluster-level means
# write out file:
# 1.1 \t "robj" \t 352
# 1.2 \t "robj" \t 228
# 2.1 \t "robj" \t 42
# 2.2 \t "robj" \t 33
# ...
#
# where first col is (cluster id).(chunk id number), and robj is deparsed centroid object (totals, not means), and third column is the count for that cluster.

f <- file("stdin")
open(f)

logClusterInfo <- function(clusterNum,robj,count) {
  cat(clusterNum,'\t',deparse(robj),'\t',count,'\n',sep='')
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
      logClusterInfo(last_key,running_total,clustCount)
    }
    # executed when starting any cluster, including the first
    running_total <- value
    clustCount <- 1
    last_key <- this_key
  }

}
close(f)

if (exists('this_key') && last_key == this_key) {
  logClusterInfo(last_key,running_total,clustCount)
}


