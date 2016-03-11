#!/util/academic/R/R-3.0.0/bin/Rscript

# convert output from reducing step (means formatted as plaintext parsed R objects) into actual R object

f <- file("stdin")
open(f)

myMeans <- list()

while(length(line <- readLines(f,n=1)) > 0) {
  this_kvpair <- unlist(strsplit(line,split="\t"))
  myMeans[[this_kvpair[1]]] <- eval(parse(text=this_kvpair[2]))
}

save(myMeans,file='currentMeans.RData')
