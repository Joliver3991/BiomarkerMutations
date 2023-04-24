#!/bin/bash
# use conda py_auto for this script
set - eu

# index the bam files
echo "Now indexing the bam files"

find ./sam_files/bam_files/*.bam -exec echo samtools index {} \; | sh

echo "Indexing Finished"

# remove .sam files
echo "Removing .sam files"

rm -i ./sam_files/*.sam

# Get expression values
echo

echo "Running Stringtie to obtain expression estimates"

cat ids.txt | parallel stringtie -p 6 -G ./index/Homo_sapiens.GRCh38.85.gtf -e -B -o \
	./expression/{}/transcripts.gtf -A ./expression/{}/gene_abundances.tsv \
	./sam_files/bam_files/{}.bam


echo
echo "Running bcftools mpileup"

BAM_LIST=`ls ./sam_files/bam_files/*.bam | cut -d '/' -f 4`

for i in ${BAM_LIST}
do
	bcftools mpileup --max-depth 1000 -f ./index/Homo_sapiens.GRCh38.dna.primary_assembly.fa ./sam_files/bam_files/$i \
	| bcftools call -mv -Ob -o $i'.bcf'
done


mkdir bcf_files

mv *.bcf bcf_files


# rename files in bcf_files/

BCF_FILES=`ls bcf_files/*.bcf | cut -d '/' -f 2 | cut -d '.' -f 1`

for i in ${BCF_FILES}
do
	mv ./bcf_files/$i'.bam.bcf' ./bcf_files/$i'.bcf'
done


echo

echo "Filtering and converting .bcf files to .vcf files"

BCF=`ls bcf_files/*.bcf | cut -d '/' -f 2`

for i in ${BCF}
do
	bcftools view -i '%QUAL>=20 && DP>10' ./bcf_files/$i > ./bcf_files/$i.vcf
done


VCF=`ls ./bcf_files/*.vcf | cut -d '/' -f 3 | cut -d '.' -f -1`
for i in ${VCF}
do
	mv ./bcf_files/$i'.bcf.vcf' ./bcf_files/$i'.vcf'
done

# isolate vcf files

VCFS=`ls ./bcf_files/*.vcf | cut -d '/' -f 3`


for i in ${VCFS}
do
	bgzip ./bcf_files/$i
done


for i in ${VCFS}
do
	tabix -p vcf ./bcf_files/$i'.gz'
done
