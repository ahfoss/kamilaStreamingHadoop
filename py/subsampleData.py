#!usr/bin/env python
#
# For an input [1] csv data filename [2] number of lines in input data set
# [3] number of subsampled points, this program creates a subsampled data set of
# the specified size.
#
# Number of lines can be obtained, e.g., at the BASH command line with the command:
# > file=2006.csv; cat "$file" | nl | tail -1|  awk -F' ' '{print $1}' > num_lines_"$file"

import os.path
import sys
import random

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
inds = random.sample(xrange(long(numLines)),int(numSample))

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

