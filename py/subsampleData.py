#!/usr/bin/python
#
documentation = '''
 For an input [1] csv data filename [2] number of lines in input data set
 [3] number of subsampled points, this program creates a subsampled data set of
 the specified size.
 Note that the file is expected to have an initial header row, which is counted
 in [2] but not in [3].

 Usage: python py/subsampleData.py csv/small2clust.csv 2000 250

 Output: subsampled_*.csv, where * is the original filename.

 Number of lines can be obtained, e.g., at the BASH command line with the command:
 > file=2006.csv; cat "$file" | nl | tail -1|  awk -F' ' '{print $1}' > num_lines_"$file"
'''

import os.path
import sys
import random

# change this if desired
random.seed(1234)

narg = len(sys.argv)
if narg < 3:
    print documentation
    print "INSUFFIENT NUMBER OF ARGUMENTS SUPPLIED."
    print "Exiting."
    sys.exit()

subsampleExtension = "subsampled_"

dataFileName = sys.argv[1]
numLines = sys.argv[2]
numSample = sys.argv[3]
parsedInFileName = os.path.split(dataFileName)
outFileName = parsedInFileName[0] + '/' + subsampleExtension + numSample + '_' + parsedInFileName[1]

print "---------------"
print "Input file name: " + dataFileName
print "Number of input data lines: " + numLines
print "Number of sampled data lines: " + numSample
print "Output file name: " + outFileName
print "---------------"

print "Now generating random row indices"
# generate random row numbers
inds = random.sample(xrange(1,long(numLines)+1),int(numSample))
inds = list([0]) + inds # include initial header row

# open new file
outFile = open(outFileName, 'w')

print "Now writing rows to file"
numWritten = 0
# write rows to new file

with open(dataFileName,'r') as inFile:
	for i, line in enumerate(inFile):
		if i in inds:
			outFile.write(line)
			numWritten += 1
			if numWritten % 50 == 0:
				print '%d/%s complete...' % (numWritten, numSample)

# cleanup
inFile.close()
outFile.close()

