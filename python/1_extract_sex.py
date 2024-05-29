import pandas as pd

# load TSV file
loci_df = pd.read_csv('../data/loci_list.txt', sep='\t')
loci_df = loci_df.set_index('id')


if __name__ == '__main__':
    # Open the GFA file
    gfa_data = open('../data/cactus/consensus.sv.gfa', 'r').read().strip().split('\n')
    gfa_data = [x.split('\t') for x in gfa_data]
    # All row where the 2nd column is in the column "loci" of the loci_df
    gfa_data = [x for x in gfa_data if x[1] in loci_df.index.values and x[0] in 'S']
    print()
    for row in gfa_data:
        sex = row[4].split('=')[1].split('|')[0].replace('consensus_', '')
        sequence = row[2]
        # Set the sex cell in the table
        loci_df.at[row[1], "sex"] = sex
        loci_df.at[row[1], "sequence"] = sequence

    # Save to TSV
    loci_df.to_csv('../data/loci_list.csv')
