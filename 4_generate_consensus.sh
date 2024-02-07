#!/bin/bash
#SBATCH -p memory
#SBATCH -N 1 -c 120
#SBATCH -t 48:00:00
#SBATCH --mem=250G
#SBATCH -J BWAjob_ryan
#SBATCH -A proj5034

module purge
module load bzip2/1.0.8-GCCcore-10.2.0
module load ncurses/6.2-GCCcore-10.2.0
module load foss/2021b
export PATH=$PATH:/tarafs/data/home/hrasoara/softwares/samtools-1.18/

groups=(
  "male"
  "female"
)
mkdir -p data/consensus
for group in "${groups[@]}"; do
    # Generate consensus
    echo "Generating consensus for ${group}..."
    samtools consensus -a "data/map_merged/merged-${group}.bam" > "data/consensus/consensus-${group}.fa"
done
echo "Done"