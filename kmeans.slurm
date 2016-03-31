#!/bin/bash

# This SLURM script is modified version of the SDSC script
# found in /util/academic/myhadoop/myHadoop-0.30b/examples.
# CDC January 29, 2015
#
# Modified 3/9/15 by Alex Foss for streaming mode


##############################
# Debugging SLURM options
#SBATCH --partition=debug
#SBATCH --time=00:50:00
#SBATCH --nodes=2
##############################

##############################
# Full SLURM options
##SBATCH --partition=general-compute
##SBATCH --time=20:50:00
##SBATCH --nodes=2
##Specifies that the job will be requeued after a node failure.
##The default is that the job will not be requeued.
##SBATCH --requeue
##############################
##SBATCH --constraint=CPU-E5645
##SBATCH --ntasks-per-node=12

##############################
# General SLURM options for full or debugging mode
## --exclusive allocates the entire node for this job
#SBATCH --exclusive
#SBATCH --job-name="test"
#SBATCH --output=test-%J.out
#SBATCH --mail-user=ahfoss@buffalo.edu
#SBATCH --mail-type=ALL
##############################

echo "SLURM_JOBID="$SLURM_JOBID
echo "SLURM_JOB_NODELIST"=$SLURM_JOB_NODELIST
echo "SLURM_NNODES"=$SLURM_NNODES
echo "SLURMTMPDIR="$SLURMTMPDIR

echo "working directory = "$SLURM_SUBMIT_DIR

module load java/1.6.0_22
module load hadoop/2.5.1
module load myhadoop/0.30b
module load R/3.0.0
module list

################################
# User-specified values
################################
# Date file is ./$DATADIR/$DATANAME

# file to be clustered
#DATANAME=1987_rmvna_norm.csv
DATANAME=small2clust_rmvna_norm.csv
# directory in which data file is stored
DATADIR=csv

# number of variables in the data set
#DATA_DIM=10
DATA_DIM=5

# number of clusters to search for
NUM_CLUST=20
# NUM_TASKS should be less than or equal to the # clusters
NUM_TASKS=10
# Number of initializations of the kmeans algorithm
NUM_INIT=3
# Max number of iterations per initialization
MAX_NITER=3
# Tolerance for determining convergence; see README.txt
# Converted to float
EPSILON=0.01

export RBIN_HOME="/util/academic/R/R-3.0.0/bin"
echo "RBIN_HOME="$RBIN_HOME
################################
# End of user-specified values
################################


TMP_DIR=tmp_"$SLURM_JOBID"
echo "MH_HOME="$MH_HOME
echo "HADOOP_HOME="$HADOOP_HOME
echo "Setting HADOOP to use SLURMTMPDIR on the local disk"
export MH_SCRATCH_DIR=$SLURMTMPDIR
echo "MH_SCRATCH_DIR="$MH_SCRATCH_DIR
#### Set this to the directory where Hadoop configs should be generated
# Don't change the name of this variable (HADOOP_CONF_DIR) as it is
# required by Hadoop - all config files will be picked up from here
#
# Make sure that this is accessible to all nodes
export HADOOP_CONF_DIR=$SLURM_SUBMIT_DIR/config-$SLURM_JOBID
echo "MyHadoop config directory="$HADOOP_CONF_DIR

# Test that the number of nodes <= number of clusters
echo
echo Checking that NUM_TASKS \<= NUM_CLUST
echo NUM_TASKS: \($NUM_TASKS\)
echo NUM_CLUST:   \($NUM_CLUST\)
echo ........
if [ $NUM_TASKS -gt $NUM_CLUST ]
  then
  echo Exiting.
  echo
  exit 1
else
  echo Proceeding.
  echo
fi

### Set up the configuration
# Make sure number of nodes is the same as what you have requested from SLURM
# usage: $myhadoop-configure.sh -h
# this is the non-persistent mode
NPROCS=`srun --nodes=${SLURM_NNODES} bash -c 'hostname' |wc -l`
echo "-------Set up the configurations for myHadoop"
$MH_HOME/bin/myhadoop-configure.sh 
echo "-------Start hdfs and yarn ---"
$HADOOP_HOME/sbin/start-all.sh
#### Format HDFS, if this is the first time or not a persistent instance
echo "-------Show Report ---"
$HADOOP_HOME/bin/hadoop dfsadmin -report
echo "-------make directory ---"
$HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR dfs -mkdir /data

echo "-------copy file to hdfs, don't copy header row ---"
#$HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR dfs -put ./"$DATADIR"/"$DATANAME" /data/
sed 1d ./"$DATADIR"/"$DATANAME" | $HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR dfs -put - /data/"$DATANAME"

echo "-------list directory ---"
$HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR dfs -ls /data

# parsing:
# Robj is an arbitrary object to be stored.
# It is stored in this manner:
# storedObj <- deparse(Robj)
#
# It can be regenerated as follows:
# reconstitutedObj <- eval(parse(text=storedObj))

# Design for k-means: 
# input csv dataset, no cluster memberships, and RData file with initial centers
# Map step: each data row is assigned a cluster
#	output: <k \t csv data row>
# Reduce step: each cluster is assigned a centroid
#	output: <k \t deparsed R object describing cluster centroid>
# Intermediary file between M-R runs converts deparsed data to RData file
# Each kmeans run terminates after MAX_NITER iterations or when the centroids
#	change by less than EPSILON units; whichever happens first. See README.txt
#	for details.


##################################################
##################################################
##################################################
## outer number init kmeans loop starts here
## Outer loop starts here; each iteration is a unique
## k-means run. The best is chosen as the final
## partition.
#
# Structure of output:
#
# myoutput-[0-9]/
#     run_1/
#         iter_0/currentMeans_i1.RData
#         iter_1/
#             currentMeans_i2.RData
#             currentObjective_i2.txt
#             part-00000
#             part-00001
#             part-00002
#             ...
#             part-00???
#         iter_2/etc
#         ...
#         stats/
#     run_2/
#         iter_0/
#         iter_1/
#         iter_2/
#         ...
#         stats/
#     run_3/
#         iter_0/
#         iter_1/
#         iter_2/
#         ...
#         stats/
#     ...
#     best_run/
#         stats.tsv
#         allWss.txt
#
##################################################
# create a variable to store within cluster sum of squares
declare -a wssArray

for ((runNumber=1; runNumber<=NUM_INIT; runNumber++))
do
    echo "-----------------------------------------------"
    echo "----------start kmeans run $runNumber-------------------"
    echo "-----------------------------------------------"
    mkdir $TMP_DIR
    mkdir -p ./myoutput-$SLURM_JOBID/run_$runNumber/

    # initialize the means based on the dimensionality of the data
    Rscript R/km_initialize_run.R $DATA_DIM $NUM_CLUST $TMP_DIR
    mkdir -p ./myoutput-$SLURM_JOBID/run_$runNumber/iter_0/
    cp $TMP_DIR/initialMeans.RData ./myoutput-$SLURM_JOBID/run_$runNumber/iter_0/currentMeans_i1.RData
    
    # Create variable to store values used to assess convergence
    unset objectiveArray
    declare -a objectiveArray
    
    for i in `seq 1 $MAX_NITER`
    do
        echo "--------ITER $i--------"
    
        # Primary M-R step
        $HADOOP_HOME/bin/hadoop --config $HADOOP_CONF_DIR \
          jar /util/academic/hadoop/2.5.1/hadoop-2.5.1/share/hadoop/tools/lib/hadoop-streaming-2.5.1.jar \
          -D mapreduce.job.reduces="$NUM_TASKS" \
          -D mapred.text.key.comparator.options="-n" \
          -mapper "$RBIN_HOME/Rscript $PWD/R/km_mapper.R" \
          -reducer "$RBIN_HOME/Rscript $PWD/R/km_reducer.R" \
          -input /data/"$DATANAME" \
          -output hadoop_output_r"$runNumber"_i"$i" \
          -file "$TMP_DIR"/currentMeans.RData 
    
        echo "-------list output ---"
        # Get name of current output file
        $HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR dfs -ls 
        $HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR dfs -ls hadoop_output_r"$runNumber"_i$i/
        THIS_OUTPUT=`$HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR dfs -ls hadoop_output_r"$runNumber"_i$i/part-* | awk -F'/' '{print $2}'`
        echo
        echo Current output files are: $THIS_OUTPUT
        echo
      
        # Copy output to local dir
        mkdir ./myoutput-$SLURM_JOBID/run_$runNumber/iter_$i/
        for ff in $THIS_OUTPUT
          do echo Copying $ff
          $HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR dfs -get hadoop_output_r"$runNumber"_i$i/$ff ./myoutput-$SLURM_JOBID/run_$runNumber/iter_$i
          echo
          cat ./myoutput-$SLURM_JOBID/run_$runNumber/iter_$i/$ff
          echo
        done
    
        echo Contents of myoutput-$SLURM_JOBID/run_$runNumber/iter_$i
        ls -lht ./myoutput-$SLURM_JOBID/run_$runNumber/iter_$i
        echo Concatenated mean vectors:
        cat ./myoutput-$SLURM_JOBID/run_$runNumber/iter_$i/part-* | sort -n
      
        # Run script on output; km_intermediary.R outputs currentMeans.RData, as well
        # as the objective function for the current iteration.
	#ls -lh $TMP_DIR
        objectiveArray[$i]=`cat ./myoutput-$SLURM_JOBID/run_$runNumber/iter_$i/part-* | sort -n | Rscript R/km_intermediary.R $EPSILON $SLURM_JOBID $runNumber $i $TMP_DIR`
	#ls -lh $TMP_DIR
  
        # break kmeans run early if objective is empty
        if [ ${objectiveArray[$i]} = 'NA' ]
        then
          echo
          echo "--------------------"
          echo "ERROR in calculating distance between centroids"
          echo "FAILURE: BREAKING K-MEANS RUN EARLY"
          echo "--------------------"
          echo
          break
        fi
  
        echo "Current value of objective array is "${objectiveArray[*]}
        echo ${objectiveArray[*]}
        echo ${objectiveArray[*]} > ./myoutput-$SLURM_JOBID/run_$runNumber/iter_$i/currentObjective_i$(expr $i + 1).txt
        #ls -lh ./myoutput-$SLURM_JOBID/run_$runNumber/iter_$i/currentMeans_i$(expr $i + 1).RData
        cp $TMP_DIR/currentMeans.RData ./myoutput-$SLURM_JOBID/run_$runNumber/iter_$i/currentMeans_i$(expr $i + 1).RData
        #ls -lh ./myoutput-$SLURM_JOBID/run_$runNumber/iter_$i/currentMeans_i$(expr $i + 1).RData
      
        # check if convergence criteria is met
        if (( $(bc <<< "${objectiveArray[$i]} < $EPSILON") ))
        then
          # if convergence criteria is met, then break this kmeans run
          echo "Convergence criteria met: Breaking kmeans run early"
          break
        fi
    
    # end of this kmeans iter
    done
    
    ##################################################
    echo "Summary stats M-R run:"
    ##################################################
    #
    # Final map-reduce run to calculate within cluster
    # sum of squares, and final cluster counts.
    #
    # M: calc cluster memberships
    #    squared euclidean distance for each point
    # R: cluster counts
    #    w/in cluster SS
    #
    ##################################################
    $HADOOP_HOME/bin/hadoop --config $HADOOP_CONF_DIR \
      jar /util/academic/hadoop/2.5.1/hadoop-2.5.1/share/hadoop/tools/lib/hadoop-streaming-2.5.1.jar \
      -D mapreduce.job.reduces=$NUM_TASKS \
      -D mapred.text.key.comparator.options="-n" \
      -mapper "$RBIN_HOME/Rscript $PWD/R/km_summary_mapper.R" \
      -reducer "$RBIN_HOME/Rscript $PWD/R/km_summary_reducer.R" \
      -input /data/"$DATANAME" \
      -output run_"$runNumber"/hadoop_stats \
      -file "$TMP_DIR"/currentMeans.RData 
    
    # tabulate and store summary stats
    mkdir ./myoutput-$SLURM_JOBID/run_$runNumber/stats/
    $HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR dfs -get run_"$runNumber"/hadoop_stats/part-* ./myoutput-$SLURM_JOBID/run_$runNumber/stats/
    
    # save stats file
    echo  -e 'ClusterNumber\tClusterSize\tSSQ\tminvec\tmeanvec\tmaxvec'  > ./myoutput-$SLURM_JOBID/run_$runNumber/stats/stats.tsv
    cat ./myoutput-$SLURM_JOBID/run_$runNumber/stats/part-* | sort -n >> ./myoutput-$SLURM_JOBID/run_$runNumber/stats/stats.tsv
    echo
    echo "Show summary stats file contents:"
    cat ./myoutput-$SLURM_JOBID/run_$runNumber/stats/stats.tsv
    
    # calculate and store total WSS
    wssArray[$(($runNumber-1))]=`awk -F'\t' '{ sum += $3 } END { print sum }' ./myoutput-$SLURM_JOBID/run_$runNumber/stats/stats.tsv`
    echo "Total WSS for this run is "${wssArray[$(($runNumber-1))]}
    echo ${wssArray[$(($runNumber-1))]} > ./myoutput-$SLURM_JOBID/run_$runNumber/stats/totalWss.txt
    ##################################################
    echo "End of summary stats M-R run"
    ##################################################

    # remove tmp dir containing intial and current means
    rm -r $TMP_DIR

##################################################
##################################################
##################################################
## outer number init kmeans loop ends here
done
# write out wss values for all runs
mkdir ./myoutput-$SLURM_JOBID/best_run
echo ${wssArray[*]} > ./myoutput-$SLURM_JOBID/best_run/allWss.txt
##################################################
##################################################
##################################################
echo
echo
echo
echo "-------list output ---"
$HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR dfs -ls 
$HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR dfs -ls hadoop_output_i1
$HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR dfs -ls /data

echo "-------Stop hdfs and yarn ---"
$HADOOP_HOME/sbin/stop-all.sh

#### Clean up the working directories after job completion
$MH_HOME/bin/myhadoop-cleanup.sh

