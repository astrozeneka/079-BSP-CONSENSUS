#!/bin/bash
#SBATCH -p memory
#SBATCH -N 1 -c 32
#SBATCH -t 72:00:00
#SBATCH --mem=250G
#SBATCH -J BWAjob_ryan
#SBATCH -A proj5034

module load Singularity/3.3.0

SINGULARITY_CACHEDIR=./
export SINGULARITY_CACHEDIR
singularity pull EDTA.sif docker://oushujun/edta:2.0.0
export PYTHONNOUSERSITE=1
export LANGUAGE="C"
export LC_ALL="C"
export LANG="C"

groups=(
  "male"
  "female"
)
for group in "${groups[@]}"; do
  echo "Running EDTA for ${group}..."
  singularity exec EDTA.sif EDTA.pl --genome data/downsampled/consensus-${group}.fa --threads 32
done
echo "EDTA done"

