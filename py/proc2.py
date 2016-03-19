#!usr/bin/env python
#
documentation = '''
 This program z-normalizes the input data set. That is, it calculates the
 sample mean and variance, and then subtracts the mean from each observation
 and divides each observation by the sample standard deviation. Requires 3
 passes through the data.

 Variance is calculated using the standard 2-pass algorithm. If variances are
 extremely small and sample size extremely large (in excess of quadrillions),
 Bjorck's algorithm could be considered:
 Equation 1.4 in: Chan, Golub, & LeVeque (1979). Updating formulae and a 
 pairwise algorithm for computing sample variances. Technical Report, Stanford
 Department of Computer Science, STAN-CS-79-773.

 Usage: python py/proc2.py DATA_FILE_NAME
   DATA_FILE_NAME is the pathway and file name of the data to be processed,
   in csv format.

 Output:
   [1] *_norm.csv, where * denotes the original filename. It is the original
       file after z-normalization.
   [2] *_norm_stats.csv, where * denotes the original filename. It is the 
       sample means and standard deviations calculated for each variable.

 Example:
   > python py/proc2.py csv/small2clust_rmvna.csv
'''

import sys
import os.path
import csv
import numpy as np

narg = len(sys.argv)
if narg < 2:
    print documentation
    print "INSUFFICIENT NUMBER OF ARGUMENTS SUPPLIED."
    print "Exiting."
    sys.exit()

DATA_FILE_NAME = sys.argv[1]
fileParsed = os.path.splitext(DATA_FILE_NAME)
outFileName = fileParsed[0] + "_norm" + fileParsed[1]
outFileNameStats = fileParsed[0] + "_norm_stats" + fileParsed[1]

# get number of rows in csv file
with open(DATA_FILE_NAME, 'r') as tmpFile:
    tmpReader = csv.reader(tmpFile, delimiter=',', quotechar='"')
    row1 = next(tmpReader)
    numCol = len(row1)
    if numCol != len(next(tmpReader)):
        print "The number of columns in row 1 does not match row 2."
        print "Exiting."
        sys.exit()

print "Infile: " + DATA_FILE_NAME
print "Outfile: " + outFileName
print "Number of columns: " + str(numCol)

sum1 = np.zeros(numCol, dtype=np.float64)
count = 0

with open(DATA_FILE_NAME, 'r') as inFile:
    inFileReader = csv.reader(inFile, delimiter=',', quotechar='"')
    for row in inFileReader:
        # add rows to sum1
        sum1 += np.asarray(row, dtype=np.float64)
        # increment count
        count += 1
means = sum1 / count

sum2 = np.zeros(numCol, dtype=np.float64)
with open(DATA_FILE_NAME, 'r') as inFile:
    inFileReader = csv.reader(inFile, delimiter=',', quotechar='"')
    for row in inFileReader:
        # add rows to sum1
        sum2 += np.power(np.asarray(row, dtype=np.float64) - means, 2)
stdevs = np.sqrt(sum2 / (count - 1))

with open(DATA_FILE_NAME, 'r') as inFile, open(outFileName, 'w') as outFile:
    inFileReader = csv.reader(inFile, delimiter=',', quotechar='"')
    outFileWriter = csv.writer(outFile, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
    for row in inFileReader:
        outFileWriter.writerow( (np.asarray(row, dtype=np.float64) - means) / stdevs )

# write out means, std
with open(outFileNameStats, 'w') as outStats:
    outStatsWriter = csv.writer(outStats, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
    outStatsWriter.writerow(['Variable Index', 'Mean', 'Standard Deviation'])
    for i in xrange(numCol):
        outStatsWriter.writerow([i+1, means[i], stdevs[i]])
