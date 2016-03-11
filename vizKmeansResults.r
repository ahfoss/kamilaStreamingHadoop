
# get csv data file, subsampled if necessary
dataFileName <- 'small2clust.csv'
saveDirName <- 'summary'

# get directory structure, cluster centroid
JOBID <- '5146222'
centroidFileNames <- list.files(
  paste('myoutput-',JOBID,sep=''),
  pattern='currentMeans_i',
  recursive=TRUE,
  full.names=TRUE
)

# Read in full data and rescale
dat <- read.csv(dataFileName,header=FALSE)
datMeans <- colMeans(dat)
datSds <- apply(dat,2,sd)
dat <- scale(dat, center=datMeans, scale=datSds)

# plot first two PCs
# X = U %*% D %*% V'
# U = X %*% solve(D %*% V')
svdDat <- svd(dat)
transMat <- solve(diag(svdDat$d) %*% t(svdDat$v))
#print('str(dat)')
#print(str(dat))
#print('dim(transMat)')
#print(dim(transMat))

# Read in all centroid data and rescale
allCentroids <- lapply(
  centroidFileNames,
  FUN=function(ff) {
    load(ff)
    dd=t(as.data.frame(myMeans)) 
    dd <- scale(dd, center=datMeans, scale=datSds)
    rownames(dd) <- paste('Clust',1:nrow(dd))
    colnames(dd) <- paste('Dim',1:ncol(dd))
    return(dd)
  }
)
#print(allCentroids)
numClust <- length(allCentroids)

# distinct colors for the clusters
myColors <- rainbow(numClust)
myColorsAlpha <- rainbow(numClust,alpha=0.5)

# Color points by nearest cluster
# Inefficient implementation: fix this
datColors <- t(apply(
  dat,
  1,
  function(rr) which.min(as.matrix(dist(rbind(rr,allCentroids[[numClust]])))[-1,1])
))

# create image file
suppressWarnings(dir.create(saveDirName))
plotName <- paste('kmeansPlot_',JOBID,'.png',sep='')
png(file=file.path(saveDirName,plotName))
plot(
  dat %*% transMat,
  xlab='Principal Component 1',
  ylab='Principal Component 2',
  col = myColorsAlpha[datColors]
)

for (i in 1:numClust) {
  transCentroids <- allCentroids[[i]] %*% transMat
  points(transCentroids, pch=19, col=myColors, cex=2)
  points(transCentroids, pch=1, col='black', cex=2, lwd=2)
  text(transCentroids, labels=i)
}

png()

