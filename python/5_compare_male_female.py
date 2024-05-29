import json

import numpy as np
import pandas as pd
from scipy.stats import ttest_ind

if __name__ == '__main__':
    # Load the read count
    read_count = {}
    data = open("../data/read_count.out").read().strip().split("\n")
    data = [data[i:i+3] for i in range(0, len(data), 3)]
    data = [a for a in data if len(a) == 3]
    for read in data:
        name = read[0].split()[1]
        count = int(read[1]) + int(read[2])
        read_count[name] = count

    # Load the genome with sex
    genomes = """ERR3332435  male
ERR3332436  male
ERR3332437  male
SRR18231392 male
SRR18231393 male
SRR18231394 male
SRR18231395 male
SRR18231396 male
SRR18231397 male
SRR18231399 male
SRR18231401 female
SRR18231402 female
SRR18231403 male
SRR18231404 female
SRR18231405 female
SRR18231406 male
SRR18231407 female
SRR18231408 female
SRR18231409 male
SRR18231410 male
SRR18231411 male
SRR18231412 female
SRR18231413 male
SRR18231414 male
SRR18231415 female
SRR18231416 female
SRR18231417 male
SRR18231418 male
SRR18231419 male
SRR18231420 male
SRR18231421 male
SRR18231422 female
SRR18231423 male
SRR18231424 male
SRR18231425 female
SRR18231426 female
SRR18231427 male
SRR18231428 female
SRR18231429 female
SRR18231430 female
SRR18231431 female
SRR19508262 male
SRR19508263 male
SRR19508264 male
SRR19508265 male
SRR19508266 male
SRR19508282 female
SRR19508283 female
SRR19508290 female
SRR19508291 female
SRR19508300 female
SRR19508463 male
SRR19508464 female
SRR19508465 female
SRR19508466 male
SRR19508467 male
SRR19508468 male
SRR19508469 male
SRR19508472 female
SRR19508480 female
SRR19508496 female
SRR6251350  male
SRR6251351  male
SRR6251352  male
SRR6251353  male
SRR6251354  male
SRR6251355  male
SRR6251356  male
SRR6251357  male
SRR6251358  male
SRR6251359  male
SRR6251360  male
SRR6251361  male
SRR6251362  male
SRR6251363  male
SRR6251364  male
SRR6251365  male
SRR6251366  male
SRR6251367  male
SRR7062760  male
SRR7062761  male
SRR7062762  male
SRR7062763  male"""
    genomes = genomes.strip().split("\n")
    genomes = [a.split() for a in genomes]

    output = []

    for ltr_sex in ["male", "female"]:
        # Get the list of sex-specific LTR
        ltrs = open(f"../data/sex-specific-ltr/ltr_complete_{ltr_sex}.fas").read().split("\n")
        ltrs = [a for a in ltrs if ">" in a]
        ltrs = ["_".join(a.split("_")[-2:]) for a in ltrs]

        for ltr in ltrs:
            for genome_sex in ["male", "female"]:
                same_sex_genomes = [a[0] for a in genomes if a[1] == genome_sex]
                opposite_sex_genomes = [a[0] for a in genomes if a[1] != genome_sex]
                # The same_sex are supposed to have higher percentage
                # The opposite sex are supposed to have lower percentage
                ltr_ratio = {a: 0 for a in read_count}
                for genome in ltr_ratio:
                    if genome == 'ERR3332434':
                        continue
                    file_data = open(f"../data/validate_ltr_v2/{ltr_sex}/{genome}.count.txt").read().strip().split("\n")
                    file_data = [a.split() for a in file_data]
                    c = [a for a in file_data if a[0] == ltr][0]
                    ltr_ratio[genome] = int(c[1])
                # Convert the count to ratio
                ltr_ratio = {a:ltr_ratio[a]/read_count[a] for a in ltr_ratio}

                ratio_in_same_sex = [ltr_ratio[a] for a in same_sex_genomes]        # Expected to be higher
                ratio_in_opposite_sex = [ltr_ratio[a] for a in opposite_sex_genomes] # Expected be lower
                # compare the mean of the average
                mean_diff = np.array(ratio_in_same_sex).mean() - np.array(ratio_in_opposite_sex).mean() # Expected to be positive
                # t-test
                t, p = ttest_ind(ratio_in_same_sex, ratio_in_opposite_sex)
                output.append({
                    "ltr": ltr,
                    "sex-specificity": ltr_sex,
                    "percentage-in-same": np.array(ratio_in_same_sex).mean(),
                    "persentage-in-opposite": np.array(ratio_in_opposite_sex).mean(),
                    "mean-diff": mean_diff,
                    "t-test": t,
                    "p-value": p
                })
                # Store the Series into JSON
                series = {
                    "same-sex": ratio_in_same_sex,
                    "opposite-sex": ratio_in_opposite_sex
                }
                # save to json
                with open(f"../data/validate_ltr_v2/json_series/{ltr}.json", "w") as f:
                    f.write(json.dumps(series))

    output = sorted(output, key=lambda x: x["p-value"])
    output = pd.DataFrame(output)
    # Filter only having meadndiff positiv
    output = output[output["mean-diff"] > 0]
    # Filter only having p-value less than 0.05
    output = output[output["p-value"] < 0.05]
    # write to csv
    output.to_csv("../data/sex-specific-ltr.csv", index=False)
    print("Done")


    print()