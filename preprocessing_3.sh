#!/bin/bash
# switch to conda pipeline
set -eu

# create file of gene positions from gtf file

cat ./index/*.gtf | awk 'NR > 5 {gsub(";","\t",$0); print;}' \
	| awk 'BEGIN{FS="\t"; OFS="\t"}{if($3 == "gene") print $1, $4, $5, $11}' \
	| sed 's/"//g' > ./index/Homo_sapiens_gtf_gene_pos.txt



awk '! ( $1 ~ /Y/ )' ./index/Homo_sapiens_gtf_gene_pos.txt > ./index/Homo_x_pos.txt


