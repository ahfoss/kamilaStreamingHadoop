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

BASEFILE=cat1987-2008_v1


# 1987 command
python py/preprocMixed.py csv/1987.csv csv/1987_types.csv 1 5 7 11 12 14 15 16

# 21 year commands
#python py/proc1.py csv/"$BASEFILE".csv 2 3 4 9 10 11 17 18 20 21 22 23 24 25 26 27 28 29
#python py/proc2.py csv/"$BASEFILE"_rmvna.csv

NLINES=`head -2 csv/"$BASEFILE"_rmvna_rowlog.csv | tail -1 | awk -F',' '{print $2}'`
echo "NLINES is $NLINES"

python py/subsampleData.py csv/"$BASEFILE"_rmvna_norm.csv $NLINES 2000

echo "All done!"

#Year,
#Month,
#DayofMonth,
#DayOfWeek,
#DepTime,
#CRSDepTime,
#ArrTime,
#CRSArrTime,
#UniqueCarrier,
#FlightNum,
#TailNum,
#ActualElapsedTime,
#CRSElapsedTime,
#AirTime,
#ArrDelay,
#DepDelay,
#Origin,
#Dest,
#Distance,
#TaxiIn,
#TaxiOut,
#Cancelled,
#CancellationCode,
#Diverted,
#CarrierDelay,
#WeatherDelay,
#NASDelay,
#SecurityDelay,
#LateAircraftDelay

