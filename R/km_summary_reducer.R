#!/util/academic/R/R-3.0.0/bin/Rscript

# Calculate cluster counts and w/in cluster SS
#####################
### Input: ##########
# (nearest cluster).(chunk id number), squared euc dist to cluster centroid, data line
#####################
# 1.1 \t 23.5 \t 5.4,2.1,4.4
# 1.2 \t 11.2 \t 5.1,1.0,2.9
# ...
######################

#####################
### Output: ##########
# (nearest cluster).(chunk id number), cluster count, WSS, min vec, sum vec, max vec
#####################
# 1.1 \t 253 \t 651.325 \t 1.0,1.0,1.0 \t 1.0,1.0,1.0 \t 1.0,1.0,1.0
# 1.2 \t 358 \t 804.266 \t 1.0,1.0,1.0 \t 1.0,1.0,1.0 \t 1.0,1.0,1.0
# ...
######################
#
# where first col is cluster id, second is count and third is WSS

f <- file("stdin")
open(f)

logClusterInfo <- function(clusterId,clustCount,wss,minvec,sumvec,maxvec) {
  cat(
    clusterId,
    '\t',
    clustCount,
    '\t',
    wss,
    '\t',
    paste(minvec,collapse=','),
    '\t',
    paste(sumvec,collapse=','),
    '\t',
    paste(maxvec,collapse=','),
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
  vec <- as.numeric(unlist(strsplit(this_kvpair[3],split=',')))

  if (last_key == this_key) {
    # executed if still within same cluster
    running_total_wss <- running_total_wss + value
    running_sum <- running_sum + vec
    # current mins
    minbool <- current_mins > vec
    if (any(minbool)) {
      current_mins[minbool] <- vec[minbool]
    }
    # current maxs
    maxbool <- current_maxs < vec
    if (any(maxbool)) {
      current_maxs[maxbool] <- vec[maxbool]
    }
    clust_count <- clust_count + 1
  } else { # executed when ending a cluster or starting the first
    if (last_key!=Inf) {
      # executed when ending a cluster
      logClusterInfo(last_key,clust_count,running_total_wss,current_mins,running_sum,current_maxs)
    }
    # executed when starting a cluster, including the first
    running_total_wss <- value
    running_sum <- vec
    current_mins <- vec
    current_maxs <- vec
    clust_count <- 1
    last_key <- this_key
  }

}

if (last_key == this_key) {
  logClusterInfo(last_key,clust_count,running_total_wss,current_mins,running_sum,current_maxs)
}


