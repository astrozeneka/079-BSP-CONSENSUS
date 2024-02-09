import pandas as pd


if __name__ == '__main__':
    loci_df = open("../data/exhaustive_list/loci_list.txt").read().strip().split("\n")[1:]
    loci_df = [{'id':a} for a in loci_df]
    loci_df = pd.DataFrame(loci_df)
    loci_df = loci_df.set_index('id')

    # Open the GFA file

    gfa_data = open('../data/cactus/consensus.sv.gfa', 'r').read().strip().split('\n')
    gfa_data = [x.split('\t') for x in gfa_data]
    # All row where the 2nd column is in the column "loci" of the loci_df
    gfa_data = [x for x in gfa_data if x[1] in loci_df.index.values and x[0] in 'S']

    for row in gfa_data:
        sex = row[4].split('=')[1].split('|')[0].replace('consensus_', '')
        sequence = row[2]
        loci_df.at[row[1], "sex"] = sex
        loci_df.at[row[1], "sequence"] = sequence

    def n_ration(seq):
        return seq.count('N')/len(seq)
    loci_df['n_ratio'] = loci_df['sequence'].apply(n_ration)
    loci_df = loci_df[loci_df['n_ratio'] < 0.01]
    # Write to TSV
    loci_df.to_csv('../data/exhaustive_list/loci_list.csv')
    print()


    print()