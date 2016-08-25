#!/bin/bash
#SBATCH --output=preprocessingResults-%J.out
#SBATCH --job-name=samplePreproc
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

BASEFILE=sample
python py/preprocKamila.py

echo
echo Sqlite3 tables created:
echo
sqlite3 db/sample.db ".tables"

python py/subsampleSqlData.py ./db/"$BASEFILE".db finalDataSet 2000 ./csv/subsampled_2000_"$BASEFILE".csv 'all'

echo
echo "All done!"
echo

