
if __name__ == '__main__':
    gfa_data = open('../data/cactus/consensus.sv.gfa', 'r').read().strip().split('\n')
    gfa_data = [x.split('\t') for x in gfa_data]
    gfa_data = [a for a in gfa_data if a[0] in 'S']
    id_list = [a[1] for a in gfa_data]
    sequence_length = {a[1]: len(a[2]) for a in gfa_data}

    # All row where the 2nd column is in the column "loci" of the loci_df
    edges = {a:[] for a in id_list}
    gfa_data = open('../data/cactus/consensus.sv.gfa', 'r').read().strip().split('\n')
    gfa_data = [x.split('\t') for x in gfa_data]
    gfa_data = [a for a in gfa_data if a[0] in 'L']
    for row in gfa_data:
        edges[row[1]].append(row[3])

    potential_loci = []
    for k, v in edges.items():
        if(len(v) >= 2):
            potential_loci = potential_loci + v

    validated_loci = [a for a in potential_loci if sequence_length[a] < 200]
    print("\n".join(validated_loci))
    print()