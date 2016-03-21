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
mypartition=`squeue -u $1 -n $2 -o "%.9P" | tail -1 | xargs`

echo "Monitoring job name: "$2
echo "Truncated job name:  "$SHORT_JOBNAME
echo "Submitted by:        "$1
echo "Job id number:       "$JOBNUM

i=1
while squeue -u $1 | grep -q $SHORT_JOBNAME
  # print slurm info
  do squeue -n $2 -o "%.18i %.9P %.8j %.8u %.2t %.10M %.6D %.15R %p"

  # print kmeans progress
  mystate=`squeue -u $1 -n $2 -o "%.2t" | tail -1 | xargs`
  printf "             PROGRESS: "
  if [ $mystate = "PD" ]
  then
    mypriority=`squeue -u $1 -n $2 -o "%.15p" | tail -1 | xargs`
    currentPriorities=($(squeue -tPD -o "%.9P %.15p" | grep $mypartition | cut -c10-25))
    counter=0
    for elm in "${currentPriorities[@]}"
    do
      if [ $(echo "$elm>$mypriority" | bc) -eq 1 ]
      then
        counter=$((counter + 1))
      fi
    done
    echo "Job pending submission with "$counter" jobs with higher priority"
  elif [ $mystate = "R" ]
  then
    {
      ls myoutput-$JOBNUM 2> /dev/null
    } || {
      echo "Job submitted; no results yet"
    }
  elif [ $mystate = "CG" ]
  then
    echo "Terminating job"
  else
    echo "Uncertain job state: "$mystate
  fi

  # sleep till next info
  sleep $i
  i=$(($i+1>120?120:$i+1))
done

echo "---------------------DONE"

# TODO: if your job is not yet running, count the number of nodes in line
# before you.
#
# 1) get your own priority
# 2) get a list of priorities of all pending jobs (squeue -o "%.9P %.2t %.6D %.15p") gives partition, job state, num nodes, and priority
# 3) loop through list, compare partition to yours, if greater, add to running node count tally

# squeue -u ahfoss -n kmHadAir -o "%.2t %.15p" # gives status and priority of your own job
#mycheck=`squeue -u ahfoss -n kmHadAir -o "%.2t %.15p"`
#state=`echo $mycheck | cut -c1-3`
