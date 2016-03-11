
require(mvtnorm)

set.seed(2)

ndim <- 3
mu2 <- 3

# initial means
myMeans <- list(
#  c(3,3,3)
# ,c(3.2,2.8,2.6)	
  runif(3,-1,4)
 ,runif(3,-1,4)
 ,runif(3,-1,4)
 ,runif(3,-1,4)
)
save(myMeans,file='currentMeans.RData')
save(myMeans,file='initMeans.RData')

# small dataset
nn <- 10^3
dat <- rbind(
  rmvnorm(nn,sigma=diag(ndim))
 ,rmvnorm(nn,mean=rep(mu2,ndim),sigma=diag(ndim))
)
#write.table(
#  dat
# ,file="small2clust.csv"
# ,row.names=FALSE
# ,col.names=FALSE
# ,sep = ","
#)

# medium dataset ~ 100MB
#nn <- 10^6
#ndim <- 3
#dat <- rbind(
#  rmvnorm(nn,sigma=diag(ndim))
# ,rmvnorm(nn,mean=rep(mu2,ndim),sigma=diag(ndim))
#)
#write.table(
#  dat
# ,file="medium2clust.csv"
# ,row.names=FALSE
# ,col.names=FALSE
# ,sep = ","
#)

# 1GB data set
set.seed(1)
nn <- 10^7
ndim <- 3

chunkSize <- 10^6
for (i in 1:(nn/chunkSize)) {
  cat('\n Now writing chunk',i)
  thisDat <- rbind(
    rmvnorm(chunkSize,sigma=diag(ndim))
   ,rmvnorm(chunkSize,mean=rep(mu2,ndim),sigma=diag(ndim))
  )
  write.table(
    thisDat
   ,file="clust1GB.csv"
   ,row.names=FALSE
   ,col.names=FALSE
   ,sep = ","
   ,append = TRUE
  )
}


# 5GB data set
set.seed(1)
nn <- 5*10^7
ndim <- 3

#chunkSize <- 10^6
#nChunks <- nn/chunkSize
#for (i in 1:(nChunks)) {
#  cat('\n Now writing chunk',i,'/',nChunks)
#  thisDat <- rbind(
#    rmvnorm(chunkSize,sigma=diag(ndim))
#   ,rmvnorm(chunkSize,mean=rep(mu2,ndim),sigma=diag(ndim))
#  )
#  write.table(
#    thisDat
#   ,file="clust5GB.csv"
#   ,row.names=FALSE
#   ,col.names=FALSE
#   ,sep = ","
#   ,append = TRUE
#  )
#}
