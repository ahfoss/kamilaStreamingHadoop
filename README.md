# kmeansStreamingHadoop
Lloyd's k-means algorithm written for MyHadoop on a SLURM batch scheduler

R files necessary to implement a bare-bones k-means clustering on a csv file.

Input must be a csv file with the continuous variables to be clustered, and an RData file with the initialized cluster centers.

NOTE: Variables must be normalized to variance 1. This ensures that the kmeans algorithm is not unduly influenced by any of the variables, and also ensures that a single EPSILON threshold can be SENSIBLY used to assess convergence based on the mean vectors.

Centroids are initialized with random uniform draws from the [-3, 3]^p hypercube, where p gives the dimension of the data. Again, this is sensible only when the variables are normalized to variance 1, hence the requirement.

A k-means run terminates when MAX_NITER number of iterations elapses, or when
$$ \sum_g^G ||\mu_g^{(t)} - \mu_g^{(t-1)}||_1 < EPSILON $$
where G is the number of clusters and t is an integer denoting the current iteration.

kmeans.slurm gives an example batch submission script
km_mapper.r gives the map step
km_reducer.r gives the reduce step
km_intermediary.r is executed in between successive map-reduce pairs
currentMeans.RData gives an example initialized means RData file
genData.r generates example data



TO DO:
initialization map-reduce run: standardize data to mean 0 and variance 1 and save original means and variances in a file in the summary directory.
summary map-reduce run to obtain:
  - boxplots for each variable by cluster
  - counts for each cluster
  - summary statistics (objective function value, within to between SS, etc)
Outer loop of repeated k-means runs with random initialized centroids
