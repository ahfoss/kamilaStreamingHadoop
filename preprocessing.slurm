#!/bin/bash
#SBATCH --output=preprocessingResults-%J.out
#SBATCH --job-name=procJob
#SBATCH --cpus-per-task=1
#SBATCH --nodes=1
#SBATCH --mail-user=ahfoss@buffalo.edu
#SBATCH --mail-type=ALL
#SBATCH --partition=debug
#SBATCH --time=00:50:00
##SBATCH --partition=general-compute
##SBATCH --time=70:50:00

echo
echo "Starting now..."
echo

# new 21 year commands
# added here for 1987 data only: 25--29
BASEFILE=1987
python py/preprocHL.py csv/"$BASEFILE".csv csv/"$BASEFILE"_types.csv 3 10 11 14 17 18 20 21 22 23 24 1 25 26 27 28 29

NLINES=`head -2 csv/"$BASEFILE"_HL_rmvna_rowlog.csv | tail -1 | awk -F',' '{print $2}'`
echo "NLINES is $NLINES"

python py/subsampleData.py csv/"$BASEFILE"_HL_rmvna_norm.csv $NLINES 2000

echo "All done!"

# 1) Year,
# 2) Month,
# 3) DayofMonth,
# 4) DayOfWeek,
# 5) DepTime,
# 6) CRSDepTime,
# 7) ArrTime,
# 8) CRSArrTime,
# 9) UniqueCarrier,
# 10) FlightNum,
# 11) TailNum,
# 12) ActualElapsedTime,
# 13) CRSElapsedTime,
# 14) AirTime,
# 15) ArrDelay,
# 16) DepDelay,
# 17) Origin,
# 18) Dest,
# 19) Distance,
# 20) TaxiIn,
# 21) TaxiOut,
# 22) Cancelled,
# 23) CancellationCode,
# 24) Diverted,
# 25) CarrierDelay,
# 26) WeatherDelay,
# 27) NASDelay,
# 28) SecurityDelay,
# 29) LateAircraftDelay

