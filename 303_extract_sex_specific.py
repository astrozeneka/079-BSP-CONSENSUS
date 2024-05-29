import Bio.SeqIO

male_sequences = "data/ltrpred/consensus-male_ltrpred/consensus-male_ltrdigest/consensus-male-ltrdigest_complete.fas"
female_sequences = "data/ltrpred/consensus-female_ltrpred/consensus-female_ltrdigest/consensus-female-ltrdigest_complete.fas"

male_specific_LTRs = [
    "consensus-male_LTR_retrotransposon13",
    "consensus-male_LTR_retrotransposon12",
    "consensus-male_LTR_retrotransposon10",
    "consensus-male_LTR_retrotransposon19",
    "consensus-male_LTR_retrotransposon18",
    "consensus-male_LTR_retrotransposon15",
    "consensus-male_LTR_retrotransposon24",
    "consensus-male_LTR_retrotransposon26",
    "consensus-male_LTR_retrotransposon23",
    "consensus-male_LTR_retrotransposon8",
    "consensus-male_LTR_retrotransposon2",
    "consensus-male_LTR_retrotransposon31",
    "consensus-male_LTR_retrotransposon29",
    "consensus-male_LTR_retrotransposon27",
    "consensus-male_LTR_retrotransposon37",
    "consensus-male_LTR_retrotransposon72",
    "consensus-male_LTR_retrotransposon71",
    "consensus-male_LTR_retrotransposon70",
    "consensus-male_LTR_retrotransposon77",
    "consensus-male_LTR_retrotransposon76",
    "consensus-male_LTR_retrotransposon75",
    "consensus-male_LTR_retrotransposon65",
    "consensus-male_LTR_retrotransposon64",
    "consensus-male_LTR_retrotransposon63",
    "consensus-male_LTR_retrotransposon81",
    "consensus-male_LTR_retrotransposon83",
    "consensus-male_LTR_retrotransposon86",
    "consensus-male_LTR_retrotransposon52",
    "consensus-male_LTR_retrotransposon50"
]
female_specific_LTRs = [
    "consensus-female_LTR_retrotransposon30",
    "consensus-female_LTR_retrotransposon16",
    "consensus-female_LTR_retrotransposon13",
    "consensus-female_LTR_retrotransposon10",
    "consensus-female_LTR_retrotransposon20",
    "consensus-female_LTR_retrotransposon5",
    "consensus-female_LTR_retrotransposon26",
    "consensus-female_LTR_retrotransposon21",
    "consensus-female_LTR_retrotransposon64",
    "consensus-female_LTR_retrotransposon60",
    "consensus-female_LTR_retrotransposon66",
    "consensus-female_LTR_retrotransposon68",
    "consensus-female_LTR_retrotransposon67",
    "consensus-female_LTR_retrotransposon69",
    "consensus-female_LTR_retrotransposon56",
    "consensus-female_LTR_retrotransposon58",
    "consensus-female_LTR_retrotransposon55",
    "consensus-female_LTR_retrotransposon73",
    "consensus-female_LTR_retrotransposon81",
    "consensus-female_LTR_retrotransposon50",
    "consensus-female_LTR_retrotransposon41"
]
male_specific_LTRs = list(set(male_specific_LTRs))
female_specific_LTRs = list(set(female_specific_LTRs))

male_bed = "data/ltrpred/consensus-male_ltrpred/consensus-male_LTRpred.bed"
female_bed = "data/ltrpred/consensus-female_ltrpred/consensus-female_LTRpred.bed"

if __name__ == '__main__':
    for sex, file, LTRs, bed in zip(
            ["male", "female"],
            [male_sequences, female_sequences],
            [male_specific_LTRs, female_specific_LTRs],
            [male_bed, female_bed]):
        # Load the bed file
        bed_data = open(bed, 'r').read().strip().split('\n')
        bed_data = [x.split('\t') for x in bed_data]

        output_sequences = []
        for LTR in LTRs:
            bed_row = [a for a in bed_data if a[3] == LTR][0]
            seq_name = f"NC_040889.2_{bed_row[1]}_{bed_row[2]}"
            seq = Bio.SeqIO.parse(file, "fasta")
            for record in seq:
                if record.id == seq_name:
                    # Update the name of the record
                    record.id = record.id + "_" + LTR
                    record.description = ""
                    output_sequences.append(record)
                    break

        # Write the sequences to a file
        Bio.SeqIO.write(output_sequences, f"data/ltr_complete_{sex}.fas", "fasta")
        print(f"Done for {sex}")
    print("Done")

