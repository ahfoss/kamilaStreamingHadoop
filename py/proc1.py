#!usr/bin/env python
#
documentation = '''
 This program removes rows with missing or non-numeric values. It also removes
 user-specified columns.

 Usage: python py/proc1.py DATA_FILE_NAME [integers separated by spaces]

 DATA_FILE_NAME is the pathway and file name of the data to be processed,
 in csv format. Optional integer inputs give index of column to be removed
 (1-based indexing).

 Example:
 > python py/proc1.py csv/small2clust.csv
 Processes csv/small2clust.csv, removing rows with non-numeric values.

 Example:
 > python py/proc1.py csv/small2clust.csv 2 4
 Processes csv/small2clust.csv as above, and also removes columns 2 and 4.
'''

import sys
import os.path

