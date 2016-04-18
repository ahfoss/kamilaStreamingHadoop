#!usr/bin/env python

documentation = '''
Insert general description here.

We use dummy coding as described in Hennig & Liao, (2013), JRSS-C 62(3),
309--369, equation 6.1, with the recommended assumtions of level
probabilities of 1/I and q = 1/2. Thus, we solve for c in:
    sum_{i=1}^I E(cYi1 - cYi1)^2 := 1,
which leads to weights c = sqrt(1 / (2 - 1/I)).

Usage: python py/preprocMixed.py DATA_FILE_NAME TYPE_FILE_NAME [optional integers]
  For consistency, we recommend naming the type file *_types.csv, where *
  denotes original file name.

Input:

Output:
  Note "*" denotes the original file name.

  [1] *_proc.csv, the processed data file.

  [2] *_rmvna_rowlog.csv, a file containing the tabulated number of missing
      elements per row. Does NOT count missing values in columns flagged for
      removal. Note values "NA" or any other in the categorical variables are
      simply treated as a separate level.

  [3] *_rmvna_collog.csv, a file containing the number of missing elements for
      each column in the data set.

Example:
  > python py/preprocMixed.py csv/smallMixed.csv smallMixedTypes.csv
'''

# Set maximum number of dummy vars per categorical variable
MAX_NUM_LEV = 12

# Set minimum number of observations a level must have to be included
MIN_NUM_LEV_OBS = 10

# String to use for "other" category
otherString = "Other_"

# Formatting string for floats
floatFormatStr = '{:0.8f}'

import sys
import os.path
import csv
import bisect
import numpy as np

narg = len(sys.argv)
if narg < 2:
    print documentation
    print "INSUFFICIENT NUMBER OF ARGUMENTS SUPPLIED."
    print "Exiting."
    sys.exit()

DATA_FILE_NAME = sys.argv[1]
TYPE_FILE_NAME = sys.argv[2]
RMV_COL = [ int(elm) for elm in sys.argv[3:narg] ]
fileParsed = os.path.splitext(DATA_FILE_NAME)
outFileNameNoNA    = fileParsed[0] + "_rmvna" + fileParsed[1]
outFileNameRowLog  = fileParsed[0] + "_rmvna_rowlog" + fileParsed[1]
outFileNameColLog  = fileParsed[0] + "_rmvna_collog" + fileParsed[1]
outFileLevelCounts = fileParsed[0] + "_rmvna_levelcounts" + fileParsed[1]
outFileFinal       = fileParsed[0] + "_rmvna_norm" + fileParsed[1]
outFileConStats    = fileParsed[0] + "_rmvna_constats" + fileParsed[1]
outFileCatStats    = fileParsed[0] + "_rmvna_catstats" + fileParsed[1]

# type file with flagged vars removed
typeFileParsed = os.path.splitext(TYPE_FILE_NAME)
typeFileNameNoNA = typeFileParsed[0] + "_rmvcols" + typeFileParsed[1]

# get number of columns in csv file
with open(DATA_FILE_NAME, 'r') as tmpFile:
    tmpReader = csv.reader(tmpFile, delimiter=',', quotechar='"')
    varNamesPre = next(tmpReader)
    numColumnPre = len(varNamesPre)
    if numColumnPre != len(next(tmpReader)):
        print "The number of columns in row 1 does not match row 2."
        print "Exiting."
        sys.exit()

# make sure number of rows in type file matches, extract type info.
with open(TYPE_FILE_NAME, 'r') as typeFile:
    typeReader = csv.reader(typeFile, delimiter=',', quotechar='"')
    typeHeader = next(typeReader)
    typeListPre = next(typeReader)
    if (len(typeHeader) != numColumnPre) or (len(typeListPre) != numColumnPre):
        print "The number of columns in " + TYPE_FILE_NAME + " doesn't match"
        print "the number of columns in " + DATA_FILE_NAME
        print "Exiting."
        sys.exit()

# Number of each variable type in non-removed columns
numCon = typeListPre.count('C')
boolConPre = [ (elm == 'C') and ((i+1) not in RMV_COL) for i,elm in enumerate(typeListPre) ]
numCat = typeListPre.count('D')
boolCatPre = [ (elm == 'D') and ((i+1) not in RMV_COL) for i,elm in enumerate(typeListPre) ]
if (numCon+numCat) != numColumnPre:
    print "Type list must be only Cs and Ds"
    print "Exiting."
    sys.exit()

# Indices of categorical vars
processedCatInds = [ ind for ind, elm in enumerate(typeListPre) if (elm == 'D' and (ind+1) not in RMV_COL) ]

# print input info
print "Infile: " + DATA_FILE_NAME
if len(RMV_COL) > 0:
    print "Removing columns: " + str(RMV_COL)
#print "Outfile: "
print "Number of columns before removal: " + str(numColumnPre)
print str(numCon) + " continuous variables and " + str(numCat) + " categoricals."
print "Data types: " + str([ str(a)+b for a,b in zip(xrange(1,len(typeListPre)+1,1), typeListPre) ])

# Store number missing in each column
numMissingInCol = [0] * numColumnPre

# Store table of number of missing values in rows: Position [0] gives the count
# of rows with zero missing, position [1] gives the number of rows with 1
# missing value, etc.
rowMissingTable = [0] * (numColumnPre + 1)

# Store list of dicts, where each dict corresponds to one variable, and each
# dict matches level names to counts.
varTables = [ {} for _ in xrange(numColumnPre) ]

###############################################
# Data pass 1
# 1. Tally counts of each level for categorical variables
# 2. Calculate one pass stats for continuous variables.
# 3. Remove and tally rows with missing values
# 4. Drop columns flagged for removal by user
# 5. Reorganize so that all continuous precede all categorical
###############################################
colSums = np.zeros(numColumnPre,dtype=np.float64)
colMins = np.ones(numColumnPre) * np.inf
colMaxs = np.ones(numColumnPre) * (-np.inf)
progress1 = 0
with open(DATA_FILE_NAME,'r') as inFile1, open(outFileNameNoNA, 'w') as outFile1:
    inFile1Reader  = csv.reader(inFile1,  delimiter=',', quotechar='"')
    outFileWriter = csv.writer(outFile1, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
    # write row of headers
    fullHeaderNames = next(inFile1Reader)
    subsettedHeaderNames = [elm for j, elm in enumerate(fullHeaderNames) if (j+1) not in RMV_COL]
    conHeader = [elm for j,elm in enumerate(fullHeaderNames) if boolConPre[j]]
    catHeader = [elm for j,elm in enumerate(fullHeaderNames) if boolCatPre[j]]
    outFileWriter.writerow(conHeader + catHeader)
    for row in inFile1Reader:
        numMissingInRow = 0
        for i, elm in enumerate(row):
            # Only process continuous vars not flagged for removal
            if boolConPre[i]:
                try:
                    elm = float(elm)
                except ValueError:
                    numMissingInRow += 1
                    numMissingInCol[i] += 1
        rowMissingTable[numMissingInRow] += 1
        # if this row has no missing values, write it out
        if numMissingInRow == 0:
            # tabulate categorical vars not flagged for removal
            for i, elm in enumerate(row):
                if boolCatPre[i]:
                    if elm not in varTables[i]:
                        varTables[i][elm] = 0
                    varTables[i][elm] += 1
            # write row minus flagged columns to file
            nonFlaggedCon = [elm for j, elm in enumerate(row) if boolConPre[j]]
            nonFlaggedCat = [elm for j, elm in enumerate(row) if boolCatPre[j]]
            outFileWriter.writerow(nonFlaggedCon + nonFlaggedCat)
            # update 1-pass stats for continuous vars
            for i, elm in enumerate(row):
                if boolConPre[i]:
                    elmFloat = np.float64(elm)
                    colSums[i] += elmFloat
                    colMins[i] = min(colMins[i],elmFloat)
                    colMaxs[i] = max(colMaxs[i],elmFloat)
        progress1 += 1
        if progress1 % 10000 == 0:
            print '%d lines processed for missing values...' % (progress1)

print "Row missing table:"
print rowMissingTable
print "Number missing in each column (before reorganization by variable type)"
print numMissingInCol

# calculate column means
numFullLines = rowMissingTable[0]
colMeans = colSums / numFullLines
colMeans = [ xx for (xx,tt) in zip(colMeans, boolConPre) if tt ]
print "Column Means:"
print colMeans

print "Column minima"
colMins = [ xx for (xx,tt) in zip(colMins,boolConPre) if tt ]
print colMins
print "Column maxima"
colMaxs = [ xx for (xx,tt) in zip(colMaxs,boolConPre) if tt ]
print colMaxs

# Get raw level counts
rawCounts = []
for i in [ ind for ind,tt in enumerate(boolCatPre) if tt ]:
    # sort levels by counts
    sortedIthTable = zip(*sorted(zip(varTables[i].values(),varTables[i].keys()),reverse=False))
    rawCounts.append([
        varNamesPre[i], list(sortedIthTable[1]), list(sortedIthTable[0])
    ])

# Threshold level counts
threshCounts = []
for vName, lName, lCount in rawCounts:
    lName = lName[:]
    lCount = lCount[:]
    # threshold by max num lev
    otherCount = 0
    numLev = len(lName)
    if numLev > MAX_NUM_LEV:
        # Drop smallest levels until MAX_NUM_LEV left.
        # Note Python's kooky indexing scheme.
        lName = lName[(numLev-MAX_NUM_LEV+1):numLev]
        otherCount += sum(lCount[0:(numLev-MAX_NUM_LEV+1)])
        lCount = lCount[(numLev-MAX_NUM_LEV+1):numLev]
    # threshold by min num obs, but only if more than one are under threshold
    if sum([x < MIN_NUM_LEV_OBS for x in lCount]) > 1:
        while lCount[0] < MIN_NUM_LEV_OBS:
            otherCount += lCount.pop(0)
            lName = lName[1:]
    # if necessary, insert other count into lists
    if otherCount > 0:
        ind = bisect.bisect(lCount,otherCount)
        lCount[ind:ind] = [otherCount]
        lName[ind:ind]  = [otherString] # just in case 'other' already exists
    # append to threshCounts
    lName.reverse()
    lCount.reverse()
    threshCounts.append([vName,lName,lCount])

# Write out type file with flagged columns removed
varNamesPostCon = [elm for (elm,tt) in zip(varNamesPre,boolConPre) if tt]
varNamesPostCat = [elm for (elm,tt) in zip(varNamesPre,boolCatPre) if tt]
varNamesPost = varNamesPostCon + varNamesPostCat
typeListPost = ['C']*len(varNamesPostCon) + ['D']*len(varNamesPostCat)
boolConPost = [ x == 'C' for x in typeListPost ]

#print "varNamesPostCon"
#print varNamesPostCon
#print "varNamesPostCat"
#print varNamesPostCat
#print "varNamesPost"
#print varNamesPost
#print "typeListPost"
#print typeListPost
#print "boolConPost"
#print boolConPost

# Write out file with new variable types
with open(typeFileNameNoNA, 'w') as typeOut:
    typeOutWriter = csv.writer(typeOut, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
    typeOutWriter.writerow(varNamesPost)
    typeOutWriter.writerow(typeListPost)

print "Raw level counts"
for i,j,k in rawCounts:
    print i
    print j
    print k

print "Thresholded counts"
for i,j,k in threshCounts:
    print i
    print j
    print k

# Write out table of row missing values
with open(outFileNameRowLog, 'w') as outRow:
    outRowWriter = csv.writer(outRow, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
    outRowWriter.writerow(['Number of missing values','Number of rows'])
    for i, elm in enumerate(rowMissingTable):
        outRowWriter.writerow([i, elm])

# Write out column missing values
with open(outFileNameColLog, 'w') as outCol:
    outColWriter = csv.writer(outCol, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
    outColWriter.writerow(['Column index','Variable Name','Number of missing values in column'])
    for i, elm in enumerate(numMissingInCol):
        outColWriter.writerow([i+1, fullHeaderNames[i], elm])

# Write out categorical variable level counts
with open(outFileLevelCounts, 'w') as outLev:
    outLevWriter = csv.writer(outLev, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
    outLevWriter.writerow(['VarIndex','VarNames','RawLevCount','ThreshLevCount'])
    for i in xrange(len(processedCatInds)):
        outLevWriter.writerow([processedCatInds[i], rawCounts[i][0], len(rawCounts[i][1]), len(threshCounts[i][1])])

###############################################
# Data pass 2
# Calculate standard deviation for continuous vars.
# Efficiency could be improved somewhat to take advantage of organization (i.e.
# first all continuous then all categorical).
###############################################
print
print 'Calculating variances...'
progress2 = 0
sum2 = np.zeros(numColumnPre, dtype=np.float64)
with open(outFileNameNoNA, 'r') as inFile2:
    inFile2Reader = csv.reader(inFile2, delimiter=',', quotechar='"')
    next(inFile2Reader) # skip header row
    for row in inFile2Reader:
        # add squared differences to sum2
        for i, elm in enumerate(row):
            if boolConPost[i]:
                sum2[i] += np.power(np.float64(elm) - colMeans[i], 2)
        progress2 += 1
        if progress2 % 10000 == 0:
            print '%d/%d lines processed...' % (progress2,numFullLines)

colStdevs = np.sqrt(sum2 / (numFullLines-1))
colStdevs = [ xx for (xx,tt) in zip(colStdevs, boolConPost) if tt ]
print "Column standard deviations"
print colStdevs

# Write out continuous stat table
conIndex = np.cumsum(boolConPost)
with open(outFileConStats, 'w') as outConStats:
    outConStatsWriter = csv.writer(outConStats, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
    outConStatsWriter.writerow(['VarName','VarIndex','ConIndex','Mean','StandardDeviation','Min','Max'])
    for i, elm in enumerate(boolConPost):
        if elm:
            outConStatsWriter.writerow([varNamesPost[i],i+1,conIndex[i], colMeans[i], colStdevs[i], colMins[i], colMaxs[i]]) 

# Write out categorical stat table
catIndex = np.cumsum([ not tt for tt in boolConPost ])
with open (outFileCatStats, 'w') as outCatStats:
    outCatStatsWriter = csv.writer(outCatStats, delimiter='\t', quotechar='"', quoting=csv.QUOTE_MINIMAL)
    outCatStatsWriter.writerow(['VarName','VarIndex','CatIndex','NumLev','LevNames','LevCounts'])
    for i, elm in enumerate([ not tt for tt in boolConPost ]):
        if elm:
            thisLevInfo = threshCounts[catIndex[i]-1]
            levCountsStr = [ str(x) for x in thisLevInfo[2] ]
            outCatStatsWriter.writerow([varNamesPost[i], i+1, catIndex[i], len(thisLevInfo[1]), ','.join(thisLevInfo[1]) , ','.join(levCountsStr)])

###############################################
# Data pass 3
# 1. Z-normalize continuous vars
# 2. Threshold and dummy code categorical vars
# 3. Scale dummy vars using Hennig Liao weighting
###############################################

print
print 'Transforming and writing final data set...'
progress3 = 0

def hlCalc(nLev):
    return floatFormatStr.format(np.sqrt( 1 / (2 - 1/np.float64(nLev)) ))
hennigLiaoWeights = [ hlCalc(len(x[1])) for x in threshCounts ]
print "hennigLiaoWeights"
print hennigLiaoWeights

with open(outFileNameNoNA, 'r') as inFile3, open(outFileFinal, 'w') as outFile2:
    inFile3Reader = csv.reader(inFile3, delimiter=',', quotechar='"')
    outFile2Writer = csv.writer(outFile2, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
    rawVarNames = next(inFile3Reader)
    conVarNames = [x for x,tt in zip(rawVarNames,boolConPost) if tt]
    catVarNames = [x for x,tt in zip(rawVarNames,boolConPost) if not tt]
    catDumNames = []
    for i in xrange(len(catVarNames)):
        catDumNames += [ threshCounts[i][0] + '_' + x for x in threshCounts[i][1] ]
    outFile2Writer.writerow(conVarNames + catDumNames)
    for row in inFile3Reader:
        conList = np.asarray([x for x,tt in zip(row,boolConPost) if tt], dtype=np.float64)
        catList = [x for x,tt in zip(row,boolConPost) if not tt]
        conZnorm = [ 0.0 if s==0 else floatFormatStr.format((x-m)/s) for x,m,s in zip(conList,colMeans,colStdevs) ]
        allHlDummies = []
        for i,elm in enumerate(catList):
            dumVec = [0]*len(threshCounts[i][1])
            if elm in threshCounts[i][1]:
                elmThresh = elm
            else:
                elmThresh = otherString
            levelIndex = [ j for j,x in enumerate(threshCounts[i][1]) if x==elmThresh ][0]
            dumVec[levelIndex] = hennigLiaoWeights[i]
            allHlDummies += dumVec
        outFile2Writer.writerow(conZnorm+allHlDummies)
        progress3 += 1
        if progress3 % 10000 == 0:
            print '%d/%d lines processed...' % (progress3,numFullLines)

print
print "Done!"
