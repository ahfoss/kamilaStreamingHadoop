#!usr/bin/env python
#
documentation = '''
 This program removes rows with missing or non-numeric values. It also removes
 user-specified columns.

 Usage: python py/proc1.py DATA_FILE_NAME [optional integers]
   DATA_FILE_NAME is the pathway and file name of the data to be processed,
   in csv format. Optional integer inputs separated by spaces give index of
   column to be removed (1-based indexing).

 Output:
   [1] *_rmvna.csv, where * denotes original filename. The original file with
       the specified rows and columns removed.
   [2] *_rmvna_rowlog.csv, where * denotes original filename. A file containing
       the tabulated number of missing elements per row. Does NOT count missing
       values in columns flagged for removal.
   [3] *_rmvna_collog.csv, where * denotes original filename. A file containing
       the number of missing elements for each column in the data set.

 Example:
   > python py/proc1.py csv/small2clust.csv
   Processes csv/small2clust.csv, removing rows with non-numeric values.

 Example:
   > python py/proc1.py csv/small2clust.csv 2 4
   Processes csv/small2clust.csv as above, and also removes columns 2 and 4.
'''

import sys
import os.path
import csv

narg = len(sys.argv)
if narg < 2:
    print documentation
    print "INSUFFICIENT NUMBER OF ARGUMENTS SUPPLIED."
    print "Exiting."
    sys.exit()

DATA_FILE_NAME = sys.argv[1]
RMV_COL = [ int(elm) for elm in sys.argv[2:narg]]
fileParsed = os.path.splitext(DATA_FILE_NAME)
outFileName = fileParsed[0] + "_rmvna" + fileParsed[1]
outFileNameRowLog = fileParsed[0] + "_rmvna_rowlog" + fileParsed[1]
outFileNameColLog = fileParsed[0] + "_rmvna_collog" + fileParsed[1]

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
if len(RMV_COL) > 0:
    print "Removing columns: " + str(RMV_COL)
print "Outfile: " + outFileName
print "Number of columns: " + str(numCol)

# Store number missing in each column
numMissingInCol = [0] * numCol

# Store table of number of missing values in rows: Position [0] gives the count
# of rows with zero missing, position [1] gives the number of rows with 1
# missing value, etc.
rowMissingTable = [0] * (numCol + 1)

# process rows
with open(DATA_FILE_NAME,'r') as inFile, open(outFileName, 'w') as outFile:
    inFileReader  = csv.reader(inFile,  delimiter=',', quotechar='"')
    outFileWriter = csv.writer(outFile, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
    for row in inFileReader:
        #print row
        numMissingInRow = 0
        for i, elm in enumerate(row):
            #print '\b' + str(i) + ':' + elm
            if (i+1) not in RMV_COL:
                try:
                    elm = float(elm)
                except ValueError:
                    #elm = 'NA'
                    numMissingInRow += 1
                    numMissingInCol[i] += 1
        rowMissingTable[numMissingInRow] += 1
        if numMissingInRow == 0:
            # write row minus flagged columns
            outFileWriter.writerow([elm for j, elm in enumerate(row) if (j+1) not in RMV_COL])

print "rowMissingTable"
print rowMissingTable
print "numMissingInCol"
print numMissingInCol

# Write out table of row missing values
with open(outFileNameRowLog, 'w') as outRow:
    outRowWriter = csv.writer(outRow, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
    outRowWriter.writerow(['Number of missing values','Number of rows'])
    for i, elm in enumerate(rowMissingTable):
        outRowWriter.writerow([i, elm])

# Write out column missing values
with open(outFileNameColLog, 'w') as outCol:
    outColWriter = csv.writer(outCol, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
    outColWriter.writerow(['Column index','Number of missing values in column'])
    for i, elm in enumerate(numMissingInCol):
        outColWriter.writerow([i+1, elm])


