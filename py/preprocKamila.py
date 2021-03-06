#!/usr/bin/python

# A script that illustrates proper formatting of a dataset for use with the
# kamila.slurm clustering program. Outputs the necessary files, and also
# creates a sqlite3 data base which includes useful summary stats for
# subsequent analysis of the KAMILA clustering.
#
# Instructions: modify user-specified values below.
#
# Usage: python py/preprocKamila.py

import sqlite3 as sql
import sys
import os
import csv
import numpy as np
from operator import itemgetter

######################################
# User-specified info
######################################
inFileName = './csv/sample.csv'

# If a categorical variable has over maxNumCatLev levels, the remaining 
# LEAST frequent levels will be replaced with the string overThreshLevName.
maxNumCatLev = 20
overThreshLevName = 'Other'

# list of tuples:
# 1) variable names (any string), 2) type ('real' for continuous or 'text'
# for categorical), and 3) whether the variable should be included or dropped
# from the final data set (true for include, false otherwise).
varInfo = [
  ('Con1',  'real', True),
  ('Disc1', 'text', True),
  ('Con2',  'real', True),
  ('Disc2', 'text', True),
  ('Disc3', 'text', True),
]
######################################
# End of user-specified info
######################################

# Convenience function for printing sql tables
def printSqlTable(cursor):
    print
    print [x[0] for x in cursor.description]
    for row in cursor.fetchall():
        print row

# parse input data file
fileParsed = os.path.splitext(inFileName)
fileExt = fileParsed[1]
filePath,fileBase = os.path.split(fileParsed[0])

# create outfile names
outFileName = fileParsed[0] + "_KAM_rmvna_norm" + fileParsed[1]
dataBaseDirName = './db/'
sqlFileName = dataBaseDirName + fileBase + '.db'
catStatsFileName = fileParsed[0] + '_KAM_rmvna_catstats.tsv'
#conStatsFileName = fileParsed[0] + '_KAM_rmvna_constats' + fileParsed[1]

allVarName = [ x[0] for x in varInfo ]
allVarType = [ x[1] for x in varInfo ]
activeVarBool = [ x[2] for x in varInfo ]
activeVarInd = [ i for i,x in enumerate(varInfo) if x[2] ]
activeVarName = list(itemgetter(*activeVarInd)(allVarName))
activeVarType = list(itemgetter(*activeVarInd)(allVarType))
activeRealName = [ vv for (vv,tt) in zip(activeVarName,activeVarType) if tt=='real' ]
activeTextName = [ vv for (vv,tt) in zip(activeVarName,activeVarType) if tt=='text' ]
numActiveCon = len(activeRealName)

print
print "All variables:    " + str(allVarName)
print "Used variables:   " + str(activeVarName)
print "Used continuous:  " + str(activeRealName)
print "Used categorical: " + str(activeTextName)
print "Maximum allowed number of categorical levels: " + str(maxNumCatLev)
print

if not os.path.exists(dataBaseDirName):
    os.makedirs(dataBaseDirName)
try:
    os.remove(sqlFileName)
except OSError:
    pass

# Creates database if it doesn't exist
con = sql.connect(sqlFileName)

# Read in csv data to table.
# Note that the "with con:" syntax automatically handles closing files and
# handles transactions/commits.
with con:
    # get version info
    cur = con.cursor()
    cur.execute('SELECT SQLITE_VERSION()')
    versionInfo = cur.fetchone()
    print "SQLite version: %s" % versionInfo

    # Initialize data table
    commandStr1 = ('CREATE TABLE rawInput(' +
        ','.join([x+' '+y for x,y in zip(activeVarName,activeVarType) ]) +
        ')'
    )
    cur = con.cursor()
    cur.execute(commandStr1)

    # open csv
    with open(inFileName, 'r') as inFile:
        # iterate over lines: read in and insert into table
        inReader = csv.reader(inFile, delimiter=',', quotechar='"')
        next(inReader) # skip header row
        numVar = len(activeVarName)
        questionMarkString = ','.join(['?']*numVar)
        mygetter = itemgetter(*activeVarInd)
        for row in inReader:
            cur.execute('INSERT INTO rawInput VALUES (' + questionMarkString + ')', mygetter(row) )

    # print number of rows
    cur.execute('SELECT count(*) FROM rawInput')
    rawCount = cur.fetchone()[0]
    print "Read in " + str(rawCount) + " lines from " + inFileName

# Create table with column counts of missing values for selected variables.
# We define missing as a non-numeric entry in a numeric variable.
con = sql.connect(sqlFileName)
with con:
    cur = con.cursor()
    cur.execute('CREATE TABLE colMissing(variable text, numMissing integer)')
    for vv in activeRealName:
        cur.execute("INSERT INTO colMissing SELECT '" + vv + "',count(" + vv + ") FROM rawInput WHERE typeof(" + vv + ")=='text'")
    cur.execute('SELECT * FROM colMissing')
    colMiss = cur.fetchall()
    print
    print 'Missing values per variable:'
    for row in colMiss:
        print row

# Create table with tabulated number of missing values per row for selected
# variables.
con = sql.connect(sqlFileName)
with con:
    cur = con.cursor()
    cur.execute('''
        CREATE TABLE rowMissing AS
          SELECT numMissing, count(numMissing)
          FROM (
            SELECT ''' + '+'.join(["(typeof("+x+")=='text')" for x in activeRealName]) + ''' AS numMissing
            FROM rawInput
          )
          GROUP BY numMissing
    ''')
    cur.execute('SELECT * FROM rowMissing')
    rowMiss = cur.fetchall()
    print
    print 'Number of missing values in rows:'
    for row in rowMiss:
        print row

# optional data cleaning procedures should be put hereabouts

# Delete missing values: non-numeric values from real columns
con = sql.connect(sqlFileName)
with con:
    cur = con.cursor()
    cur.execute("DELETE FROM rawInput WHERE " +
        " OR ".join(["typeof("+x+")=='text'" for x in activeRealName]))
    cur.execute('SELECT count(*) FROM rawInput')
    procCount = cur.fetchone()[0]
    print
    print str(procCount) + " records remaining after NA removal."

# continuous summary stats
con = sql.connect(sqlFileName)
with con:
    cur = con.cursor()
    cur.execute('CREATE TABLE onePass (variable TEXT, minimum REAL, mean REAL, maximum REAL, n REAL)')
    cur.execute('CREATE TABLE twoPass (variable TEXT, variance REAL)')
    for vv in activeRealName:
        cur.execute("INSERT INTO onePass SELECT '" +
            vv +
            "', MIN(" + 
            vv + 
            "), AVG(" +
            vv + 
            "), MAX(" + 
            vv + 
            "), COUNT(" +
            vv + 
            ") FROM rawInput"
        )
    for vv in activeRealName:
        cur.execute("INSERT INTO twoPass SELECT '" +
            vv +
            "', total((" + 
            vv + 
            "-mean)*(" + 
            vv + 
            "-mean))/(n-1) FROM rawInput CROSS JOIN (SELECT mean, n FROM onePass WHERE variable=='" +
            vv + 
            "')"
        )
    # Create full stat table for continuous variables
    cur.execute('''CREATE TABLE conStats (
        VarName TEXT,
        VarIndex INTEGER,
        ConIndex INTEGER,
        Mean REAL,
        StandardDeviation REAL,
        Min REAL,
        Max REAL
    )''')
    cur.execute('SELECT * FROM onePass')
    onePassStats = cur.fetchall()
    cur.execute('SELECT * FROM twoPass')
    twoPassStats = cur.fetchall()
    allStats = tuple([(x[0], i+1, i+1, x[2], np.sqrt(y[1]), x[1], x[3]) for i,(x,y) in enumerate(zip(onePassStats,twoPassStats))])
    cur.executemany('INSERT INTO conStats VALUES(?, ?, ?, ?, ?, ?, ?)', allStats)
    cur.execute('SELECT * FROM conStats')
    print
    print 'Statistics for continuous variables'
    printSqlTable(cur)

# categorical summary stats
otherInds = {} # dict for storing index of "Other" category, if it exists
con = sql.connect(sqlFileName)
with con:
    cur = con.cursor()
    for vv in activeTextName:
        cur.execute("CREATE TABLE "
            + vv + "raw AS SELECT "
            + vv + " AS Level, COUNT("
            + vv + ") AS numObs FROM rawInput GROUP BY "
            + vv + " ORDER BY numObs DESC"
        )
        cur.execute("SELECT * FROM " + vv + "raw")
        print
        print 'Level counts for categorical variable: ' + vv
        printSqlTable(cur)
        cur.execute("SELECT MAX(rowid) FROM " + vv + "raw")
        thisNumRows = int(cur.fetchone()[0])
        print "Number of rows: " + str(thisNumRows)
        cur.execute("CREATE TEMPORARY TABLE tmp" + vv +
            " AS SELECT * FROM "
            + vv + "raw WHERE rowid <= " + str(maxNumCatLev)
        )
        if thisNumRows > maxNumCatLev:
            print "More than " + str(maxNumCatLev) + " rows:"
            print "Collapsing smallest and adding '" + overThreshLevName + "' category"
            cur.execute("INSERT INTO tmp" + vv +
                " SELECT '" + overThreshLevName + "', SUM(numObs) FROM "
                + vv + "raw WHERE rowid > " + str(maxNumCatLev)
            )
        cur.execute("CREATE TABLE "
            + vv + "thresh AS SELECT * FROM tmp" + vv +
            " ORDER BY numObs DESC"
        )
        if thisNumRows > maxNumCatLev:
            cur.execute('SELECT rowid FROM ' + vv + "thresh WHERE Level='" + overThreshLevName + "'")
            thisInd = cur.fetchone()[0]
            otherInds[vv] = thisInd
            cur.execute("SELECT * FROM " + vv + "thresh")
            print
            print 'Collapsed level counts:'
            printSqlTable(cur)
        else:
            otherInds[vv] = "'NA'"
    cur.execute("CREATE TABLE catSummary (VarName TEXT, VarIndex INTEGER, CatIndex INTEGER, NumLev INTEGER, LevNames TEXT, LevCounts TEXT)")
    for i,vv in enumerate(activeTextName):
        cur.execute("INSERT INTO catSummary " +
            "SELECT '" + vv + "', '" + str(numActiveCon+i+1) + "', '" + str(i+1) + "', COUNT(Level), GROUP_CONCAT(Level), GROUP_CONCAT(numObs,',') FROM " + vv + "thresh"
        )
    cur.execute("SELECT * FROM catSummary")
    printSqlTable(cur)

print
print "Indices of 'Other' variables, if applicable:"
print otherInds

# code categorical variables by integer
con = sql.connect(sqlFileName)
with con:
    cur = con.cursor()
    cur.execute('CREATE TABLE finalDataSet AS SELECT ' + 
        ', '.join([ '(t1.' + vv + ' - ' + str(allStats[i][3]) + ')/' + str(allStats[i][4]) + ' AS ' + vv for i,vv in enumerate(activeRealName)]) + ',' + 
        ', '.join([ 'ifnull(' + vv + "thresh.rowid," + str(otherInds[vv]) + ") AS " + vv for vv in activeTextName]) + 
        ' FROM rawInput AS t1 ' + 
        ' '.join([ 'LEFT JOIN ' + vv + 'thresh ON t1.' + vv + '=' + vv + 'thresh.Level' for vv in activeTextName])
    )

# Now write out data files
con = sql.connect(sqlFileName)
with con:
    cur = con.cursor()
    # write main data file
    cur.execute('SELECT * FROM finalDataSet')
    with open(outFileName, 'w') as outFileMain:
        outFileMainWriter = csv.writer(outFileMain)
        # write header
        outFileMainWriter.writerow(activeRealName + activeTextName)
        for row in cur:
            outFileMainWriter.writerow(['{:.8f}'.format(x) for x in row[0:numActiveCon]] + list(row[numActiveCon:]))
    # Write categorical summary stats
    cur.execute('SELECT * FROM catSummary')
    with open(catStatsFileName, 'w') as outFileCat:
        outFileCatWriter = csv.writer(outFileCat, delimiter='\t', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        outFileCatWriter.writerow(['VarName','VarIndex','CatIndex','NumLev','LevNames','LevCounts'])
        for row in cur:
            outFileCatWriter.writerow(row)
#    # Write continuous summary stats
#    cur.execute('SELECT * FROM conStats')
#    with open(conStatsFileName, 'w') as outFileCon:
#        outFileConWriter = csv.writer(outFileCon, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
#        outFileConWriter.writerow(['VarName','VarIndex','ConIndex','Mean','StandardDeviation','Min','Max'])
#        for row in cur:
#            outFileConWriter.writerow(row)





