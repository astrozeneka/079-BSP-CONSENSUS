#!/bin/bash
#SBATCH -p memory
#SBATCH -N 1 -c 120
#SBATCH -t 48:00:00
#SBATCH --mem=250G
#SBATCH -J BWAjob_ryan
#SBATCH -A proj5034

source ~/.bashrc

groups=(
  "male"
  "female"
)
for group in "${groups[@]}"; do
  echo "Finding LTRs for ${group}..."
  ltr_finder "data/downsampled/consensus-${group}.fa" \
    > "data/ltr_finder/ltr-${group}.fa"
done
echo "Done"