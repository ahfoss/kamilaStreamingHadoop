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

python py/proc1.py csv/1987.csv 1 5 7 9 11 12 14 15 16 17 18 20 21 23 25 26 27 28 29

python py/proc2.py csv/1987_rmvna.csv

echo "All done!"

