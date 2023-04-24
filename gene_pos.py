# restructure the gene positions file
# use conda pipeline2
import pandas as pd

g = pd.read_csv('index/Homo_sapiens_gtf_gene_pos.txt', sep='\t', header=None).rename(
	columns={0:'Chr',1:'Start',2:'End',3:'Gene'})

g['Gene'] = g['Gene'].str.replace('gene_name','')

g = g.drop_duplicates(subset=['Gene'])

g.to_csv('./index/Homo_sapiens_gtf_pos.csv', sep='\t', index=False)


# Restructure the homo_x_pos file

h = pd.read_csv('index/Homo_x_pos.txt', sep='\t', header=None).rename(
        columns={0:'Chr',1:'Start',2:'End',3:'Gene'})

h['Gene'] = h['Gene'].str.replace('gene_name','')

h = h.drop_duplicates(subset=['Gene'])

h.to_csv('./index/Homo_x_pos.csv', sep='\t', index=False)



