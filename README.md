# kmeansStreamingHadoop
Lloyd's k-means algorithm and KAMILA written for MyHadoop on a SLURM batch scheduler.

# kmeans algorithm
R files necessary to implement a bare-bones k-means clustering on a csv file.

Input must be a csv file with the continuous variables to be clustered, and an RData file with the initialized cluster centers.

NOTE: Variables must be normalized to variance 1. This ensures that the kmeans algorithm is not unduly influenced by any of the variables, and also ensures that a single EPSILON threshold can be sensibly used to assess convergence based on the mean vectors.

Centroids are initialized by taking pseudo-random samples from the data set.

A k-means run terminates when MAX\_NITER number of iterations elapses, or when \sum\_g^G ||\mu\_g^{(t)} - \mu\_g^{(t-1)}||\_1 < EPSILON, where G is the number of clusters and t is an integer denoting the current iteration.

If a cluster is found to be empty during a k-means run, it is re-initialized using the same selection strategy.

kmeans.slurm gives an example batch submission script
km\_mapper.r gives the map step
km\_reducer.r gives the reduce step
km\_intermediary.r is executed in between successive map-reduce pairs
genData.r generates example data

# kamila algorithm

