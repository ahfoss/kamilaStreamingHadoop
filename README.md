# kmeansStreamingHadoop

Clustering very large mixed-type data sets with k-means and KAMILA. Mixed-type refers to combinations of continuous and categorical variables. This package implements Lloyd/Forgy's k-means and KAMILA (KAy-means for MIxed LArge data) clustering methods written for a computing cluster using Hadoop on a SLURM batch scheduler. For details about the KAMILA algorithm, see our paper in [*Machine Learning*](http://link.springer.com/article/10.1007/s10994-016-5575-7) and our forthcoming software paper.

Rather than attempt a bloated "one size fits all" approach, we instead aim for a lightweight "one size fits some" approach that can serve as a starting point for crafting a solution that meets the user's particular needs.
Our primary contribution is a Hadoop-based implementation of the novel KAMILA algorithm, and as such we do not focus here on developing detailed tools for data management.

## Dependencies

The [Environment Modules](modules.sourceforge.net) package is used to manage packages and environment variables. This setup requires java 1.6.0\_22, hadoop 2.5.1, [myhadoop](https://github.com/glennklockwood/myhadoop) 0.30b, R 3.0.0, and the SLURM workload manager 16.05.3.

## Setup: data structures

Three data files are required to run KAMILA.
The primary data file should be in csv format (with header row) and placed in the `csv` directory.
Continuous variables should be numeric values, while categorical variables can take on any values (although consider coding them concisely using the integers 1:M, where M is the number of categorical levels).
A small subset of the rows (perhaps around 2000--5000 data points) should be randomly selected without replacement and placed in the same `csv` directory.
Finally, a tsv file containing information on the categorical variables should be included in the `csv` directory.
This tsv file should contain the following columns, with each row corresponding to a categorical variable in the data set:
 - VarName: Variable name
 - VarIndex: One-based column index into the primary data file
 - CatIndex: One-based numbering within just the categorical variables (not currently used)
 - NumLev: Number of categorical levels in the current variable
 - LevNames: Comma-separated list of level names
 - LevCounts: Comma-separated list of counts corresponding to the levels in the previous column

The names of the data files are not important as long as they are referenced correctly in `kamila.slurm` as explained below.

See the files `preprocKamila.py` and `subsampleSqlData.py` for examples of how to automatically generate these files using python and Sqlite.
The former script also generates summary files useful for analyzing and plotting the clustering solution.

The current script sets up [HDFS](https://hadoop.apache.org/docs/r2.5.2/hadoop-project-dist/hadoop-hdfs/HdfsUserGuide.html) and copies the data over.
If your data is already stored in HDFS, this step should be skipped.

## Usage: Running the batch job

The appropriate SLURM batch submission file should then be 

## Output files

output files
Rnw example file


# kmeans algorithm

R files necessary to implement a bare-bones k-means clustering on a csv file.

Input must be a csv file with the continuous variables to be clustered, and an RData file with the initialized cluster centers.

NOTE: Variables must be normalized to variance 1. This ensures that the kmeans algorithm is not unduly influenced by any of the variables, and also ensures that a single EPSILON threshold can be sensibly used to assess convergence based on the mean vectors.

A k-means run terminates when MAX\_NITER number of iterations elapses, or when \sum\_g^G ||\mu\_g^{(t)} - \mu\_g^{(t-1)}||\_1 < EPSILON, where G is the number of clusters and t is an integer denoting the current iteration.

If a cluster is found to be empty during a k-means run, it is re-initialized using the same selection strategy.

kmeans.slurm gives an example batch submission script
km\_mapper.r gives the map step
km\_reducer.r gives the reduce step
km\_intermediary.r is executed in between successive map-reduce pairs
genData.r generates example data

# kamila algorithm

