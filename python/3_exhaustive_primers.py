import primer3.bindings as p3
import pandas as pd

# load the csv data
loci_df = pd.read_csv('../data/exhaustive_list/loci_list.csv')

if __name__ == '__main__':
    total_primers = 0
    for index, row in loci_df.iterrows():
        res = {}
        print("Designing primers for locus ", index, "...")
        try:
            res = p3.design_primers(
                {
                    'SEQUENCE_ID': 'test',
                    'SEQUENCE_TEMPLATE': row['sequence'],
                    'PRIMER_OPT_SIZE': 20,
                    'PRIMER_MIN_SIZE': 18,
                    'PRIMER_MAX_SIZE': 25,
                    'PRIMER_OPT_TM': 60.0,
                    'PRIMER_MIN_TM': 57.0,
                    'PRIMER_MAX_TM': 63.0,
                    'PRIMER_MAX_DIFF_TM': 1.0,
                    'PRIMER_OPT_GC_PERCENT': 50.0,
                    'PRIMER_MIN_GC': 20.0,
                    'PRIMER_MAX_GC': 80.0,
                    'PRIMER_MAX_NS_ACCEPTED': 0,
                    'PRIMER_PRODUCT_SIZE_RANGE': [[75, 150]]
                },
                {
                    'PRIMER_TASK': 'pick_pcr_primers',
                    'PRIMER_PICK_LEFT_PRIMER': 1,
                    'PRIMER_PICK_INTERNAL_OLIGO': 0,
                    'PRIMER_PICK_RIGHT_PRIMER': 1,
                    'PRIMER_NUM_RETURN': 5,
                    'PRIMER_EXPLAIN_FLAG': 1
                }
            )
        except Exception as e:
            print("Exception with locus ", index)

        # Add two primer pair in the dataframe
        if 'PRIMER_LEFT_0_SEQUENCE' in res and 'PRIMER_RIGHT_0_SEQUENCE' in res:
            total_primers += 1
            keys = ['PRIMER_PAIR_0_PENALTY',
                 'PRIMER_LEFT_0_PENALTY',
                 'PRIMER_RIGHT_0_PENALTY',
                 'PRIMER_LEFT_0_SEQUENCE',
                 'PRIMER_RIGHT_0_SEQUENCE',
                 'PRIMER_LEFT_0_TM',
                 'PRIMER_RIGHT_0_TM',
                 'PRIMER_LEFT_0_GC_PERCENT',
                 'PRIMER_RIGHT_0_GC_PERCENT',
                 'PRIMER_LEFT_0_SELF_ANY_TH',
                 'PRIMER_RIGHT_0_SELF_ANY_TH',
                 'PRIMER_LEFT_0_SELF_END_TH',
                 'PRIMER_RIGHT_0_SELF_END_TH',
                 'PRIMER_LEFT_0_HAIRPIN_TH',
                 'PRIMER_RIGHT_0_HAIRPIN_TH',
                 'PRIMER_LEFT_0_END_STABILITY',
                 'PRIMER_RIGHT_0_END_STABILITY',
                 'PRIMER_PAIR_0_COMPL_ANY_TH',
                 'PRIMER_PAIR_0_COMPL_END_TH',
                 'PRIMER_PAIR_0_PRODUCT_SIZE',
                 'PRIMER_PAIR_0_PRODUCT_TM']
            for key in keys:
                # Add a new column to the dataframe
                loci_df.at[index, key] = res[key]

        if 'PRIMER_LEFT_1_SEQUENCE' in res and 'PRIMER_RIGHT_1_SEQUENCE' in res:
            keys = ['PRIMER_PAIR_1_PENALTY',
                 'PRIMER_LEFT_1_PENALTY',
                 'PRIMER_RIGHT_1_PENALTY',
                 'PRIMER_LEFT_1_SEQUENCE',
                 'PRIMER_RIGHT_1_SEQUENCE',
                 'PRIMER_LEFT_1_TM',
                 'PRIMER_RIGHT_1_TM',
                 'PRIMER_LEFT_1_GC_PERCENT',
                 'PRIMER_RIGHT_1_GC_PERCENT',
                 'PRIMER_LEFT_1_SELF_ANY_TH',
                 'PRIMER_RIGHT_1_SELF_ANY_TH',
                 'PRIMER_LEFT_1_SELF_END_TH',
                 'PRIMER_RIGHT_1_SELF_END_TH',
                 'PRIMER_LEFT_1_HAIRPIN_TH',
                 'PRIMER_RIGHT_1_HAIRPIN_TH',
                 'PRIMER_LEFT_1_END_STABILITY',
                 'PRIMER_RIGHT_1_END_STABILITY',
                 'PRIMER_PAIR_1_COMPL_ANY_TH',
                 'PRIMER_PAIR_1_COMPL_END_TH',
                 'PRIMER_PAIR_1_PRODUCT_SIZE',
                 'PRIMER_PAIR_1_PRODUCT_TM']
            for key in keys:
                loci_df.at[index, key] = res[key]


    # Write to CSV
    loci_df.to_csv('../data/exhaustive_list/primers.csv')
    print("Done, ", total_primers, " primers designed.")

    # Design primers
    print()