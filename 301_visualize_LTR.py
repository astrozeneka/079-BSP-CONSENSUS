
male_path = "data/ltrpred/consensus-male_ltrpred/consensus-male_LTRpred.bed"
female_path = "data/ltrpred/consensus-female_ltrpred/consensus-female_LTRpred.bed"

if __name__ == '__main__':

    svg = "<svg width='1600' height='1600' xmlns='http://www.w3.org/2000/svg'>\n"
    chromosome_length =3.5E7
    scale = 0.0000241
    for i, file in enumerate([male_path, female_path]):
        data = open(file, 'r').read().strip().split('\n')
        data = [x.split('\t') for x in data]

        # Draw the chromosome
        offset_y = 50
        offset_x = 200 + i* 55
        svg += f"<rect x='{offset_x}' y='{offset_y}' width='50' stroke-width='0.2' height='{chromosome_length * scale}' stroke='black' fill='transparent'></rect>\n"

        # Draw the LTRs
        ltr_svgs = []
        for row in data:
            start = int(row[1])
            end = int(row[2])
            svg += f"<rect x='{offset_x}' y='{offset_y + start * scale}' width='50' height='{(end-start) * scale}' fill='red' fill-opacity='0.5'></rect>\n"
            if i == 1:
                ltr_svgs.append(f"<text x='{offset_x + 55}' y='{offset_y + start * scale}' font-size='5' fill='black'>{row[3]}</text>")
            if i ==0:
                ltr_svgs.append(f"<text x='{offset_x - 90}' y='{offset_y + start * scale}' font-size='5' fill='black'>{row[3]}</text>")
        svg += "".join(ltr_svgs) + "\n"

        # Draw the ticks
        ref_yticks = []
        for i in range(0, int(chromosome_length), 1000000):
            ref_yticks.append(f"<text x='{offset_x + 2 }' y='{i * scale + offset_y}' font-size='3' fill='black' text-anchor='start'>{int(i//1E6)} Mbp</text>")
            ref_yticks.append(f"<line x1='{offset_x - 3}' y1='{i * scale + offset_y}' x2='{offset_x}' y2='{i * scale + offset_y}' stroke='black' stroke-width='0.2'></line>")
        svg += "".join(ref_yticks) + "\n"

    svg += "</svg>"
    outfile = "figures/ltrpred.svg"
    open(outfile, "w").write(svg)
    print("Visualize the LTR predictions")
