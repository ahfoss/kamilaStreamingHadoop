# kamilaStreamingHadoop

This package implements the KAMILA (KAy-means for MIxed LArge data) clustering method on a computing cluster using Hadoop and the SLURM batch scheduler.
The method is specifically designed to handle mixed-type data sets consisting of both continuous and categorical variables.
Categorical variables do not need to be (and should not be) dummy coded, which leads to better performance and more efficient memory usage.
For details about the KAMILA algorithm, see our paper in [*Machine Learning*](http://link.springer.com/article/10.1007/s10994-016-5575-7) and our forthcoming software paper.

Rather than attempt a bloated "one size fits all" approach, we instead aim for a lightweight "one size fits some" approach that can serve as a starting point for crafting a solution that meets the user's particular needs.
Our primary contribution is a Hadoop-based implementation of the novel KAMILA algorithm, and as such we do not focus here on developing detailed tools for data management.

This package also includes an implementation of Lloyd's k-means algorithm.

## Dependencies

The [Environment Modules](http://www.modules.sourceforge.net) package is used to manage packages and environment variables.
This setup requires java 1.6.0\_22, hadoop 2.5.1, [myhadoop](https://github.com/glennklockwood/myhadoop/tree/v0.30b) 0.30b, R 3.0.0, and the SLURM workload manager 16.05.3.

## KAMILA Setup: data structures

Three data files are required to run KAMILA.
The primary data file should be in csv format (with header row) and placed in the `csv` directory.
Continuous variables should be z-normalized numeric values, while categorical variables can take on any values (although consider coding them concisely using the integers 1:M, where M is the number of categorical levels).
Using z-normalized continuous variables ensures that a sensible `EPSILON_CON` can be used (see below).
A small subset of the *continuous* variables (perhaps around 2000--5000 data points) should be randomly selected without replacement and placed in the same `csv` directory.
Finally, a tsv file containing information on the categorical variables should be included in the `csv` directory.
This tsv file should contain a header row and the following six columns, with each row corresponding to a categorical variable in the data set:
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
(If your data is already stored in HDFS, this step should obviously be skipped.)

## KAMILA Usage: Running the batch job

The main SLURM batch submission script `kamila.slurm` should then be modified to fit your computing setup and data.
Lines 12 through 75 are marked as the relevant user-specified options.
Up to line 39 are options for the SLURM command `sbatch` which should be (un)commented and modified as needed.
Consult the `sbatch` [documentation](http://www.slurm.schedmd.com/sbatch.html) for further information.
The remainder of the user-specified options are environment variables.
The first three variables are the file names of the three data files described in the previous section:
 - `DATANAME`: The file name of the primary csv data file
 - `SUBSAMP_DATANAME`: The file name of the subsampled continuous data file
 - `CATINFO_DATANAME`: The file name of the tsv file 
The fourth variable, `DATADIR`, is the directory of the data files, i.e, the full path of the data file is `./$DATADIR/$DATANAME`.
The remainder of the environment variables control the behavior of the KAMILA algorithm:
 - `INITIAL_SEED`: Integer; A random seed for the random number generator for reproducibility
 - `NUM_CLUST`: Integer; KAMILA partitions the data into this many clusters
 - `NUM_MAP`: Integer; the default number of map tasks, passed to hadoop streaming option `mapred.map.tasks`
 - `NUM_REDUCE`: Integer; the default number of reduce tasks, passed to hadoop streaming option `mapred.reduce.tasks`
 - `NUM_CHUNK`: Integer; each cluster is split into this many chunks, and each chunk is assigned its own key (i.e. about `NUM_CLUST` x `NUM_CHUNK` keys total). This is useful if the number of available reducers greatly exceeds `NUM_CLUST`.
 - `NUM_INIT`: Integer; the number of distinct initializations should be used.
 - `MAX_NITER`: Integer; the maximum number of initializations computed for each distinct initialization.
 - `EPSILON_CON` and `EPSILON_CAT`: Positive real; parameters controlling the stopping rule. The closer to zero the more stringent the rule and thus the more likely each initialization will simply run for `MAX_NITER` iterations. The run is stopped if the summed absolute deviation of the centroid parameters in both the continuous and categorical variables are less than `EPSILON_CON` and `EPSILON_CAT`, respectively, from one iteration to the next. A reasonable value is the total deviation you would accept in the estimated centroid parameters relative to the true parameters, which depends on the data and the user's analysis needs. See the software paper cited above for more information.
 - `RBIN_HOME`: Character; file path to `R`, e.g. `/home/blah/R/R-3.x.x/bin`.

KAMILA clustering can be run by submitting the batch script to the SLURM scheduler in the usual way:

    $ sbatch kamila.slurm

## KAMILA Output files

Output files are stored in the directory `output-kamila-*`, where the `*` denotes the job submission number.
The file structure is organized as follows:

    output-kamila-*/
        best_run/
        run_1/
            stats/
            iter_1/
            iter_2/
            iter_3/
            ...
        run_2/
            stats/
            iter_1/
            iter_2/
            ...
        run_3/
        ...

The file `output-kamila-*/best_run/allClustQual.txt` contains a list of the objective criterion values used to select the best run.
The directory `output-kamila-*/run_i/` contains information on the ith run; within each run's directory the directory `iter_j/` stores information on the jth run.
The primary results files, `output-kamila-*/run_i/stats/finalRunStats.RData`, contain two `R` list objects: `runSummary` and `clustSummary`.
The `output-kamila-*/run_i/iter_j/` directories contain the centroids of the current run/iteration stored as an `RData` file, along with other output from the reducers for that iteration.

The `runSummary` object contains overall summary statistics for the clustering:
 - `clusterQualityMetric`, the final quantity used to select the best solution over all the runs
 - `totalEucDistToCentroid`, the total Euclidean distance from each continuous point to its centroid
 - `totalCatLogLik`, the log-likelihood of the categorical centroids with respect to the categorical variables

The `clustSummary` list contains one slot for each cluster.
Each cluster's slot contains a list of length five with the elements:
 - `count`, the number of observations assigned to this cluster
 - `totalDistToCentroid`, the total Euclidean distance from each member of the current cluster to the centroid (along the continuous variables only)
 - `totalCatLogLik`, the log-likelihood of the categorical centroids of the current cluster with regard to the categorical variables
 - `con`, means, minima, and maxima along each continuous variable for members of the current cluster
 - `catfreq`, frequencies of observations of each level of each categorical variable within the current cluster. Frequencies are calculated by counting the number of observations at a particular level of a particular variable and dividing by the number of observations in the current cluster.

The knitr document `Rnw/kamilaSummary.Rnw` provides example results that can be tabulated and plotted from these output objects.
Note: see the [knitr documentation](http://yihui.name/knitr/) for more information on report generation using knitr.

## Example usage

In a linux terminal:

    # Generate sample data
    Rscript R/genData.R
    
    # Format the data, generate required metadata files.
    sh preprocessing.slurm
    # Or use:
    # slurm preprocessing.slurm

    # Cluster the data
    slurm kamila.slurm
    
    # Generate a report on the clustering
    cd Rnw/
    # Modify JOBID variable in the section "User-Supplied Values" in
    # kamilaSummary.Rnw to be the SLURM job ID used in kamila.slurm.
    Rscript -e "require(knitr);knit('kamilaSummary.Rnw')"
    pdflatex kamilaSummary.tex
    !!
    evince kamilaSummary.pdf &

