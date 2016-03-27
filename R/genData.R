
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
 ,col.names=TRUE
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
# ,col.names=TRUE
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
#   ,col.names=TRUE
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
#   ,col.names=TRUE
#   ,sep = ","
#   ,append = TRUE
#  )
#}

# small data set with missing values and non-numbers
dat <- data.frame(a=rnorm(25),b=sample(letters,size=25,replace=T),stringsAsFactors=F)
dat[3,1]=NA
dat[1,2]=1
dat[2,2]=''
for (i in 5:24) dat[i,2]=i
write.table(
  dat
 ,file='csv/smallMissing.csv'
 ,row.names=FALSE
 ,col.names=TRUE
 ,sep=","
)

