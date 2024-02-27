import sys
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--output", type=str, help="Path to tsv output file") # Generated with GenAlex
args = parser.parse_args()

if __name__ == '__main__':

    output = {}

    # Read from the standard input
    for line in sys.stdin:
        # Split the line into words
        words = line.strip().split()
        # Print the words to the standard output
        ltr_name = "_".join(words[2].split("_")[-2:])
        if ltr_name not in output:
            output[ltr_name] = 0
        output[ltr_name] += 1

    # Write to the output file
    with open(args.output, "w") as f:
        for key, value in output.items():
            f.write(f"{key}\t{value}\n")
    print("Done")
