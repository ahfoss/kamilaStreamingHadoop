#!/bin/bash

################################################################################
# A bare-bones script to monitor the progress of a kmeans hadoop job on the
# SLURM scheduling system. The job is monitored more often initially, when
# problems are most likely to occur, and then is gradually monitored less
# frequently. 
#
# Usage: 
# > sh BASH/monitor.sh USERID JOBNAME
#
# Written by alexanderhfoss@gmail.com
################################################################################

if [ $# -lt 2 ]
  then
  echo "Insufficient number of arguments supplied."
  echo "Usage: sh BASH/monitor.sh USERID JOBNAME"
  echo "Exiting."
  exit 1
fi

# get job number
JOBNUM=`squeue -n $2 -o "%.18i" | tail -1 | xargs`
# note SLURM displays first 8 characters of jobname
SHORT_JOBNAME=`echo $2 | cut -c1-8`
#SHORT_JOBNAME=`echo $2 | awk '{print substr($0,0,9)}'`
#read -n 8 SHORT_JOBNAME <<< "$2"

echo "Monitoring job name: "$2
echo "Truncated job name:  "$SHORT_JOBNAME
echo "Submitted by:        "$1
echo "Job id number:       "$JOBNUM

i=1
while squeue -u $1 | grep -q $SHORT_JOBNAME
  # print slurm info
  do squeue -n $2 -o "%.18i %.9P %.8j %.8u %.2t %.10M %.6D %.15R %p"

  # print kmeans progress
  printf "             PROGRESS: "
  {
    ls myoutput-$JOBNUM 2> /dev/null
  } || {
    echo "No results yet"
  }

  # sleep till next info
  sleep $i
  i=$(($i+1>120?120:$i+1))
done

echo "---------------------DONE"

