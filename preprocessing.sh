#!/bin/bash
# Use conda pipeline for this script
set -eu


echo "Building file structure: "
echo "Building directory fastqc_out"; mkdir fastqc_out
echo "Building directory fastq_files"; mkdir fastq_files
echo "Building directory fastq_files/trimmed"; mkdir ./fastq_files/trimmed/
#echo "Building directory index"; mkdir index
echo "Building sam_files"; mkdir sam_files
echo "Building sam_files/bam_files"; mkdir ./sam_files/bam_files/
echo "Building directory expression"; mkdir expression


# Create file called ids.txt which stores all fastq file names without extension
# Assumes fastq files are in same directory as this script
ls *.fastq | cut -d '_' -f 1 | sort | uniq >> ids.txt

# Decompress files in ./index
echo
echo "Unzipping files in ./index/, this may take a minute..."
gunzip ./index/*.gz

# Download SRR files
echo "downloading SRRs"

cat ids.txt | parallel ~/programs/sratoolkit.3.0.0-ubuntu64/bin/fastq-dump -X 10000 --split-files {}


# compress downloaded files:
gzip *.fastq


# Run Fastqc on fastq files to assess quality scores

#echo "Running Fastqc:"
fastqc -t 4 *.fastq.gz

# Check to see if fastq.gz files are in current working dir

echo "Looking for fastq.gz files in current directory"
(ls *.fastq.gz && mv *.fastq.gz fastq_files) || echo fastq files not in current directory

echo "Moved fastq.gz files to fastq_files"
mv *.zip fastqc_out
mv *.html fastqc_out

multiqc fastqc_out/
mv *.html fastqc_out

# generate ids file for parallel processing

cat ids.txt | parallel flexbar --adapter-min-overlap 7 --adapter-trim-end RIGHT --adapters ./illumina_multiplex.fa \
	--pre-trim-right 0 --max-uncalled 300 --min-read-length 25 --threads 4 --zip-output GZ \
	-r ./fastq_files/{}_1.fastq.gz -p ./fastq_files/{}_2.fastq.gz --target ./fastq_files/trimmed/{}


# Download HISAT2 index files
#wget https://genome-idx.s3.amazonaws.com/hisat/grch38_genome.tar.gz

# Run HISAT2
cd index

read -p "Would you like to process fastq files in parallel using HISAT2? Note that RAM requirements are higher [y/n]: "
if [[ $REPLY =~ [Yy]$ ]]
then

	cat ~/scripts/ids.txt | \
        	parallel hisat2 -p 2 --rg-id=ILC2 --rg SM:ILC --rg LB:ILC --rg PL:ILLUMINA --rg PU:CXX1234-ACTGAC.1 -x\
         	~/scripts/index/genome --dta --rna-strandness RF\
         	-1 ~/scripts/fastq_files/trimmed/{}_1.fastq.gz -2 ~/scripts/fastq_files/trimmed/{}_2.fastq.gz -S\
         	~/scripts/sam_files/{}.sam

else
	echo "Mapping fastq files without parallel - this may take some time"
	files=`cat ~/scripts/ids.txt`
	for i in $files
	do
		hisat2 -p 2 --rg-id=ILC2 --rg SM:ILC --rg LB:ILC --rg PL:ILLUMINA --rg PU:CXX1234-ACTGAC.1 -x\
		 ~/scripts/index/genome --dta --rna-strandness RF\
		 -1 ~/scripts/fastq_files/trimmed/$i'_1.fastq.gz' -2 ~/scripts/fastq_files/trimmed/$i'_2.fastq.gz' -S\
		 ~/scripts/sam_files/$i'.sam'
	done
fi


# Convert sam files to bam files

cd ~/scripts/

cat ids.txt | parallel samtools sort -@ 4 ~/scripts/sam_files/{}'.sam'\
	 -o ~/scripts/sam_files/bam_files/{}'.bam'

echo "sam to bam conversion done"
