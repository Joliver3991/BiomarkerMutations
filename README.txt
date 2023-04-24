This document details how to run the scripts which in turn produce a dataframe containing 
the sum of mutations per gene per sample.

The following packages are required:
Python 3.5 or above
FastQC v0.11.9
multiQC 1.0.dev0
Flexbar v2.31
Hisat2 v2.1.0
Stringtie v2.1.5
Samtools v1.10
BCFtools v1.9
Parallel v20220222
Vcftools 0.1.16
Tabix v1.10.2-3
Bgzip v1.10.3-3
Pysam v0.19.1
Pyvcf v0.6.8
Pandas v3.7.13

Note that the version numbers are not hard requirements and other versions of the same packages may be
installed instead.


The following scripts should be run in the following order:

preprocesing.sh

preprocessing_2.sh

preprocesing_3.sh

gene_pos.py

vcf_processing_python.py

 
