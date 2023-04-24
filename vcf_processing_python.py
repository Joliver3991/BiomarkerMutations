#!/usr/bin/env python


# Script for processing vcf files
# requires conda py_auto
# pdac_auto1.ipynb


import pysam
import pandas as pd
import numpy as np
import vcf
import os
import glob

# function to list all .vcf files
def list_vcf_files():
  '''List all .vcf.gz files in the directory bcf_files/ '''
  lst = []
  for i in os.listdir('./bcf_files/'):
    if i.endswith('.vcf.gz'):
      lst.append(i)
  return lst

print(list_vcf_files())


########################

# read in Homo_sapiens_gtf_pos.csv
skip = [i for i, line in enumerate(open('./index/Homo_sapiens_gtf_pos.csv')) if line.startswith(('K','G'))]
chr_locs = pd.read_csv('./index/Homo_sapiens_gtf_pos.csv',
	sep = '\t', skiprows = skip[0:])

chr_locs['Start'] = chr_locs['Start'].astype(int)
chr_locs['End'] = chr_locs['End'].astype(int)
chr_locs['Start'] = chr_locs['Start'] - 1

print(chr_locs)


# read in Homo_x_pos.csv
skip = [i for i, line in enumerate(open('./index/Homo_x_pos.csv')) if line.startswith(('K','G'))]
chr_x = pd.read_csv('./index/Homo_x_pos.csv', sep='\t', skiprows = skip[0:])
chr_x['Start'] = chr_x['Start'].astype(int)
chr_x['End'] = chr_x['End'].astype(int)
chr_x['Start'] = chr_x['Start'] - 1

print(chr_x)

###################################
# function to compile variants

def get_mutants(file_name, vcf_gz_file):
  '''Parse through each vcf.gz file - if no Y chromosome in vcf file
  Switch to alternate .csv file (Homo_x_pos.csv). Note that the imported
  vcf parser throws an error where there is discrepancy between the Chrs
  in the vcf file and Chrs in the positions file (Homo_sapiens_gtf_pos.csv)'''

  vcf_reader = vcf.Reader(filename = vcf_gz_file)
  f = open(file_name, 'w')
  try: # Look in Homo_sapiens_gtf_pos.csv first
    result = ((vcf_reader.fetch(str(i),j,k),v) for i,j,k,v in zip(chr_locs['Chr'], chr_locs['Start'],
	chr_locs['End'], chr_locs['Gene']))

  except ValueError: # if ValueError due to Chrs not mathcing try below
    print("A ValueError occured")
    print("Re-Running")


  try: # Look in Homo_x_pos.csv
    result = ((	vcf_reader.fetch(str(i),j,k),v) for i,j,k,v in zip(chr_x['Chr'], chr_x['Start'],
	chr_x['End'], chr_x['Gene']))

  except ValueError:
    print("Second attempt failed")


  for x,l in result:
    print(*x,l, file = f)
  f.close()



def create_many_vcf():
  return [get_mutants(i[0:-7]+'_vcf_calls', i) for i in list_vcf_files()]

create_many_vcf()


def get_call_files():
  lst = []
  for i in os.listdir('./'):
    if i.endswith('calls'):
      lst.append(i)
  return lst


# write file_name into call files
for i in get_call_files():
  with open(i, 'a') as f:
    f.seek(0)
    f.write(i)


# Build dict
def to_dict(file_name, dict_name):
  dict_name = {}
  with open(file_name, 'r') as f:
    for line in f.readlines():
      line = line.split()
      dict_name[line[-1]] = line[0:-1]
  return dict_name


def create_multi_dict():
 return [to_dict(i,i+'_dict') for i in get_call_files()]


# define the overall data frame and transpose data frame
frame = pd.DataFrame(create_multi_dict())
frame = frame.T



def list_dicts():
  '''Get the number of files containing the vcf data  '''
  lst = []
  for i in os.listdir('./'):
    if i.endswith('calls'):
      lst.append(i)
  return len(lst)



# create a temporary column and rename columns
lst1 = []
frame['temp'] = frame.index
for i in frame.iloc[-abs(list_dicts()):, -1]:
  lst1.append(i)
frame = frame.drop(columns={'temp'})
frame.columns = [lst1]


# change dtype of columns and count the occurance of ALT=
cols = frame.select_dtypes('object').columns
frame[cols] = frame[cols].apply(lambda x: x.astype(str))
frame = frame.apply(lambda x: x.str.count('ALT='))


# Drop rows containing column names
l_range = []
for i in range(1,list_dicts() + 1):
  l_range.append(-abs(i))

frame = frame.drop(frame.index[l_range])


frame.to_csv('vcf_datframe_mutation_counts.csv.gz', sep='\t', compression='gzip')
