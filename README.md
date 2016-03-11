# kmeansStreamingHadoop
Lloyd's k-means algorithm written for MyHadoop on a SLURM batch scheduler

R files necessary to implement a bare-bones k-means clustering on a csv file.

Input must be a csv file with the continuous variables to be clustered, and an RData file with the initialized cluster centers.

kmeans.slurm gives an example batch submission script
km_mapper.r gives the map step
km_reducer.r gives the reduce step
km_intermediary.r is executed in between successive map-reduce pairs
currentMeans.RData gives an example initialized means RData file
genData.r generates example data



TO DO:
initialization map-reduce run
summary map-reduce run to obtain:
  - boxplots for each variable by cluster
  - counts for each cluster
  - summary statistics (objective function value, within to between SS, etc)
Outer loop of repeated k-means runs with random initialized centroids
Clean up code into subfolders etc.
