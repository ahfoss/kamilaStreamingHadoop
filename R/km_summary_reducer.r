#!/util/academic/R/R-3.0.0/bin/Rscript

# Calculate cluster counts and w/in cluster SS
### Output: ##########
# 1 \t 253 \t 651.325
# 2 \t 358 \t 804.266
# ...
######################
#
# where first col is cluster id, second is count and third is WSS

f <- file("stdin")
open(f)

logClusterInfo <- function(clusterId,clustCount,wss) {
  cat(
    clusterId,
    '\t',
    clustCount,
    '\t',
    wss,
    '\n',
    sep=''
  )
}

last_key <- Inf

# running tally of observations used in current sum
clust_count <- 0

while(length(line <- readLines(f,n=1)) > 0) {
  this_kvpair <- unlist(strsplit(line,split="\t"))
  this_key <- this_kvpair[1]
  # value in this case is squared Euclidean dist to centroid
  value <- as.numeric(this_kvpair[2])

  if (last_key == this_key) {
    # executed if still within same cluster
    running_total_wss <- running_total_wss + value
    clust_count <- clust_count + 1
  } else {
    # executed when ending a cluster or starting the first
    if (last_key!=Inf) {
      # executed when ending a cluster
      logClusterInfo(last_key,clust_count,running_total_wss)
    }
    # executed when starting the first cluster
    running_total_wss <- value
    clust_count <- 1
    last_key <- this_key
  }

}

if (last_key == this_key) {
  logClusterInfo(last_key,clust_count,running_total_wss)
}


