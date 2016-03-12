#!/bin/bash
##SBATCH --partition=general-compute
#SBATCH --partition=debug
#SBATCH --time=00:50:00

#SBATCH --nodes=2
#SBATCH --ntasks-per-node=12
##SBATCH --constraint=CPU-E5645
## --exclusive allocates the entire node for this job
#SBATCH --exclusive

#SBATCH --job-name="hadoopKM"
#SBATCH --output=test-%J.out
#SBATCH --mail-user=ahfoss@buffalo.edu
#SBATCH --mail-type=ALL

##SBATCH --requeue
#Specifies that the job will be requeued after a node failure.
#The default is that the job will not be requeued.
#
# This SLURM script is modified version of the SDSC script
# found in /util/academic/myhadoop/myHadoop-0.30b/examples.
# CDC January 29, 2015
#
# Modified 3/9/15 by Alex Foss for streaming mode

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

################
# User-specified values
################
DATANAME=small2clust.csv # file to be clustered

# NUM_TASKS should be less than or equal to the # clusters
NUM_TASKS=4
# Number of initializations of the kmeans algorithm
NUM_INIT=3
# Max number of iterations per initialization
MAX_NITER=40
# Tolerance for determining convergence; see README.txt
# Converted to float
EPSILON=0.01

export RBIN_HOME="/util/academic/R/R-3.0.0/bin"
echo "RBIN_HOME="$RBIN_HOME
################
# End of user-specified values
################


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
NUM_CLUST=`"$RBIN_HOME"/Rscript -e "load('currentMeans.RData');length(myMeans)" | awk -F' ' '{print $2}'`
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

echo "-------copy file to hdfs ---"
$HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR dfs -put ./"$DATANAME" /data/

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



echo "----------start kmeans run---------"
# initialize the means based on the dimensionality of the data

# Create variable to store sum of L1 norm of means of current vs previous
# iteration.
unset objectiveArray
declare -a objectiveArray

for i in `seq 1 $MAX_NITER`
do
  echo "--------ITER $i--------"

# modified
$HADOOP_HOME/bin/hadoop --config $HADOOP_CONF_DIR \
  jar /util/academic/hadoop/2.5.1/hadoop-2.5.1/share/hadoop/tools/lib/hadoop-streaming-2.5.1.jar \
  -D mapreduce.job.reduces=$NUM_TASKS \
  -mapper "$RBIN_HOME/Rscript $PWD/km_mapper.r" \
  -reducer "$RBIN_HOME/Rscript $PWD/km_reducer.r" \
  -input /data/"$DATANAME" \
  -output hadoop_output_i$i \
  -file currentMeans.RData 

  echo "-------list output ---"
  # Get name of current output file
  $HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR dfs -ls 
  $HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR dfs -ls hadoop_output_i$i/
  THIS_OUTPUT=`$HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR dfs -ls hadoop_output_i$i/part-* | awk -F'/' '{print $2}'`
  echo
  echo Current output files are: $THIS_OUTPUT
  echo

  # Copy output to local dir
  mkdir -p ./myoutput-$SLURM_JOBID/iter_$i/
  for ff in $THIS_OUTPUT
    do echo Copying $ff
    $HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR dfs -get hadoop_output_i$i/$ff ./myoutput-$SLURM_JOBID/iter_$i
    echo
    cat ./myoutput-$SLURM_JOBID/iter_$i/$ff
    echo
  done

  echo Contents of myoutput-$SLURM_JOBID/iter_$i
  ls -lht ./myoutput-$SLURM_JOBID/iter_$i
  echo Concatenated mean vectors:
  cat ./myoutput-$SLURM_JOBID/iter_$i/part-*
  # Run script on output; km_intermediary.r outputs currentMeans.RData, as well
  # as the objective function for the current iteration. Note if $i is 1, then
  # 99 is stored in objectiveArray.
  objectiveArray[$i]=`cat ./myoutput-$SLURM_JOBID/iter_$i/part-* | Rscript km_intermediary.r $EPSILON $SLURM_JOBID $i`
  echo ${objectiveArray[*]} > ./myoutput-$SLURM_JOBID/iter_$i/currentObjective_i$(expr $i + 1).txt
  cp currentMeans.RData ./myoutput-$SLURM_JOBID/iter_$i/currentMeans_i$(expr $i + 1).RData

  # check if convergence criteria is met
  if (( $(bc <<< "${objectiveArray[$i]} < $EPSILON") ))
  then
  	# if convergence criteria is met, then break this kmeans run
	echo Breaking kmeans run early due to convergence criteria
  	break
  fi

done

echo
echo
echo
echo "-------list output ---"
$HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR dfs -ls 
$HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR dfs -ls hadoop_output_i1
$HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR dfs -ls /data

echo "-------Get output ---"
#$HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR dfs -get wordcount-output ./myoutput1-$SLURM_JOBID
#$HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR dfs -get lettercount-output ./myoutput2-$SLURM_JOBID
#$HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR dfs -help

echo "-------Stop hdfs and yarn ---"
$HADOOP_HOME/sbin/stop-all.sh

#### Clean up the working directories after job completion
$MH_HOME/bin/myhadoop-cleanup.sh

