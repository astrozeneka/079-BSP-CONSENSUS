import json

import pandas as pd

scale = 0.0000241
colors = ["#8ACDD7", "#FF90BC"]
if __name__ == '__main__':
    # Load csv
    df = pd.read_csv("../data/sex-specific-ltr.csv")
    ltr_pos = []
    # Load the position data from fasta files
    for sex in ["male", "female"]:
        data = open(f"../data/sex-specific-ltr/ltr_complete_{sex}.fas").read().strip().split("\n")
        data = [a for a in data if ">" in a]
        start_end = [[int(b) for b in a.split("_")[2:4]] for a in data]
        chr_name = ["_".join(a.split("_")[-2:]) for a in data]
        subdata = list(zip(chr_name, start_end))
        ltr_pos += subdata
    ltr_pos = {a[0]: a[1] for a in ltr_pos}

    #print()

    # Load sample json file
    #data = json.loads(open(f"../data/plotly/sample.json").read())

    # Draw the chromosome using svg

    svg = "<svg width='1600' height='1600' xmlns='http://www.w3.org/2000/svg'>\n"
    chromosome_length = 3.123E7

    for i, sex in enumerate(["male", "female"]):
        print(f"Drawing {sex}")
        color = colors[i]
        # Draw the chromosome
        offset_y = 50
        offset_x = 200 + i*40
        svg += f"<rect x='{offset_x}' y='{offset_y}' width='35' fill='white' stroke-width='0.2' height='{chromosome_length * scale}' stroke='black'></rect>\n"

        sub_df = df[df["sex-specificity"] == sex]
        ltr_list = sub_df["ltr"].tolist()

        for ltr in ltr_list:
            start, end = ltr_pos[ltr]
            svg += f"<rect x='{offset_x}' y='{offset_y + start * scale}' width='35' height='{(end-start) * scale}' fill='{color}' fill-opacity='1' stroke='{color}' stroke-width='0.25'></rect>\n"
            if i == 1:
                svg += f"<text x='{offset_x + 37}' y='{offset_y + start * scale}' font-size='5' fill='black'>{ltr}</text>"
            if i == 0:
                svg += f"<text x='{offset_x - 2}' y='{offset_y + start * scale}' font-size='5' fill='black' text-anchor='end'>{ltr}</text>"

        # Draw the ticks
        ref_yticks = []
        for i in range(0, int(chromosome_length), 1000000):
            ref_yticks.append(f"<text x='{offset_x + 2 }' y='{i * scale + offset_y}' font-size='3' fill='black' text-anchor='start'>{int(i//1E6)} Mbp</text>")
            ref_yticks.append(f"<line x1='{offset_x - 3}' y1='{i * scale + offset_y}' x2='{offset_x}' y2='{i * scale + offset_y}' stroke='black' stroke-width='0.2'></line>")
        svg += "".join(ref_yticks) + "\n"
        offset_x+= 50
    svg += "</svg>"
    outfile = "../data/validate_ltr_v2/validated_ltr.svg"
    open(outfile, "w").write(svg)

    print("Done")