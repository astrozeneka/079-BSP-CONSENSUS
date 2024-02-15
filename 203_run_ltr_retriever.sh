#!/bin/bash
#SBATCH -p memory
#SBATCH -N 1 -c 32
#SBATCH -t 48:00:00
#SBATCH --mem=250G
#SBATCH -J BWAjob_ryan
#SBATCH -A proj5034

# Run LTR retriever

source ~/.bashrc

# ANALYZE consensus using LTR_retriever
groups=(
  "male"
  #"female"
)
for group in "${groups[@]}": do
  echo "Running LTR_retriever for ${group}..."
  LTR_retriever -genome "data/consensus/consensus-${group}.fa" \
    -infinder "data/ltr_finder/ltr-${group}.fa" -threads 32
done
echo "Done"