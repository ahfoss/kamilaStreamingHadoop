#!/bin/bash
#SBATCH --error=preprocessingResults.err
#SBATCH --output=preprocessingResults.out
#SBATCH --job-name=procJob
#SBATCH --cpus-per-task=1
#SBATCH --nodes=1
#SBATCH --mail-user=ahfoss@buffalo.edu
#SBATCH --mail-type=ALL
#SBATCH --partition=debug
#SBATCH --time=00:50:00
##SBATCH --partition=general-compute
##SBATCH --time=70:50:00

BASEFILE=1987

python py/proc1.py csv/"$BASEFILE".csv 1 5 7 9 11 12 14 15 16 17 18 20 21 23 25 26 27 28 29

python py/proc2.py csv/"$BASEFILE"_rmvna.csv

NLINES=`head -2 csv/"$BASEFILE"_rmvna_rowlog.csv | tail -1 | awk -F',' '{print $2}'`
echo "NLINES is $NLINES"

python py/subsampleData.py csv/"$BASEFILE"_rmvna_norm.csv $NLINES 1500

echo "All done!"

