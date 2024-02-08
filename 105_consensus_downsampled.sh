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
for group in "${groups[@]}"; do
  echo "Extracting consensus from the bam file ..."
  samtools consensus -a "data/downsampled/downsampled-${group}.bam" > "data/downsampled/consensus-${group}.fa"
done
echo "Done"