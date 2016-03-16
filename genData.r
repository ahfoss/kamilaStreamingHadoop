
require(mvtnorm)

set.seed(2)

ndim <- 5
mu2 <- 3

# create data directory
suppressWarnings(dir.create('csv'))

# small dataset
nn <- 10^3
dat <- rbind(
  rmvnorm(nn,sigma=diag(ndim))
 ,rmvnorm(nn,mean=rep(mu2,ndim),sigma=diag(ndim))
)

write.table(
  dat
 ,file="csv/small2clust.csv"
 ,row.names=FALSE
 ,col.names=FALSE
 ,sep = ","
)

# medium dataset ~ 100MB
#nn <- 10^6
#ndim <- 3
#dat <- rbind(
#  rmvnorm(nn,sigma=diag(ndim))
# ,rmvnorm(nn,mean=rep(mu2,ndim),sigma=diag(ndim))
#)
#write.table(
#  dat
# ,file="csv/medium2clust.csv"
# ,row.names=FALSE
# ,col.names=FALSE
# ,sep = ","
#)

# 1GB data set
set.seed(1)
nn <- 10^7
ndim <- 3

#chunkSize <- 10^6
#for (i in 1:(nn/chunkSize)) {
#  cat('\n Now writing chunk',i)
#  thisDat <- rbind(
#    rmvnorm(chunkSize,sigma=diag(ndim))
#   ,rmvnorm(chunkSize,mean=rep(mu2,ndim),sigma=diag(ndim))
#  )
#  write.table(
#    thisDat
#   ,file="csv/clust1GB.csv"
#   ,row.names=FALSE
#   ,col.names=FALSE
#   ,sep = ","
#   ,append = TRUE
#  )
#}


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
#   ,file="csv/clust5GB.csv"
#   ,row.names=FALSE
#   ,col.names=FALSE
#   ,sep = ","
#   ,append = TRUE
#  )
#}
