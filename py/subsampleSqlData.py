#!/usr/bin/python

documentation = '''
 For an input [1] sqlite db file, [2] table name, [3] number of subsampled
 lines, [4] output csv file name, and [5] a string indicating which variables
 should be selected, this program creates a subsampled data set of the specified
 size in csv format.

 Argument 5 can be either 'all' or 'continuous'.

 Usage: python py/subsampleSqlData.py mydbname.db mytablename 2000 outfile.csv all

 Output: outfile.csv
'''

import sys
import random
import csv
import sqlite3 as sql

# change this if desired
random.seed(1234)

narg = len(sys.argv)
if narg < 5:
    print documentation
    print "INSUFFIENT NUMBER OF ARGUMENTS SUPPLIED (" + str(narg) + ")."
    print "Exiting."
    sys.exit()

print
print "Subsetting the data now..."
print

dbName = sys.argv[1]
tableName = sys.argv[2]
numSample = sys.argv[3]
outFileName = sys.argv[4]
whichVars = sys.argv[5]
validVarSelection = ('all','continuous')
if whichVars not in validVarSelection:
    print 'Argument 5 must be one of ' + str(validVarSelection)
    print 'You input ' + whichVars
    print 'Exiting.'
    sys.exit()

# get number of lines in data, and make sure the rowid column is complete.
con = sql.connect(dbName)
with con:
    cur = con.cursor()
    cur.execute('SELECT count(*) FROM ' + tableName)
    numLines = cur.fetchone()[0]
    cur.execute('SELECT max(rowid) FROM ' + tableName)
    maxRowid = cur.fetchone()[0]

if numLines != maxRowid:
    print 'The rowid variable in table ' + tableName + ' is missing values.'
    print 'Regenerate the table with complete rowid column.'
    print 'Exiting.'
    sys.exit()

# Generate random indices
inds = random.sample(xrange(1,long(numLines)+1),int(numSample))

# pull rows with rowid matching subset indices
indsString = ','.join([str(x) for x in inds])
subsetQuery = 'SELECT * FROM ' + tableName + ' WHERE ROWID IN (' + indsString + ')'
con = sql.connect(dbName)
with con:
    cur = con.cursor()
    cur.execute(subsetQuery)
    subsetTable = cur.fetchall()
    colNames = [description[0] for description in cur.description]

print "Column names:"
print colNames

# shuffle by random order in generated inds
random.shuffle(subsetTable)

# write out as csv file
with open(outFileName, 'w') as outFile:
    outFileWriter = csv.writer(outFile)
    # write header
    outFileWriter.writerow(colNames)
    for row in subsetTable:
        outFileWriter.writerow(row)

print "---------------"
print "JOB SUMMARY"
print "Input db name: " + dbName
print "Number of input data lines: " + str(numLines)
print "Number of sampled data lines: " + numSample
print "Output file name: " + outFileName
print "---------------"



