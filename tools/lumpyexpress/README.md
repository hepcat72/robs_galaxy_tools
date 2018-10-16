# lumpyexpress - a simple wrapper for galaxy

lumpyexpress is a wrapper for lumpy.  This galaxy wrapper includes a shell script which wraps lumpyexpress (and lumpy).  The shell script sorts bam files (if they are not sorted) and indexes bam files (if they are not indexed).  lumpyexpress however only works on paired-end data, therefor, in order to provide simplified processing of split-read data, a simplified call to lumpy with split-read data is made if the data is indicated to be single-end read data (i.e. not paired-end data).

Only required options are used.  Everything else uses the lumpy/lumpyexpress defaults.  If you would like support for additional lumpy/lumpyexpress options, please submit an issue to request it.

lumpy and lumpyexpress were not written by me.  Please refer to the lumpy repository for issues with lumpy itself:

https://github.com/arq5x/lumpy-sv

Issues with this wrapper can be submitted here.
