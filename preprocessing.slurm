#!/bin/bash
#SBATCH --output=preprocessingResults-%J.out
#SBATCH --job-name=procJob
#SBATCH --cpus-per-task=1
#SBATCH --nodes=1
##SBATCH --mail-user=username@host.com
##SBATCH --mail-type=ALL
#SBATCH --partition=debug
#SBATCH --time=00:50:00
##SBATCH --partition=general-compute
##SBATCH --time=70:50:00

echo
echo "Starting now..."
echo

BASEFILE=smallMixed
python py/preprocKamila.py

#NLINES=`head -2 csv/"$BASEFILE"_KAM_rmvna_rowlog.csv | tail -1 | awk -F',' '{print $2}'`
NLINES=666
echo "NLINES is $NLINES"

#python py/subsampleData.py csv/"$BASEFILE"_HL_rmvna_norm.csv $NLINES 1000

echo "All done!"

