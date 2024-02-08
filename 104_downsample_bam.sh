#!/bin/bash
#SBATCH -p memory
#SBATCH -N 1 -c 48
#SBATCH -t 48:00:00
#SBATCH --mem=250G
#SBATCH -J BWAjob_ryan
#SBATCH -A proj5057

module purge
module load bzip2/1.0.8-GCCcore-10.2.0
module load ncurses/6.2-GCCcore-10.2.0
module load foss/2021b
export PATH=$PATH:/tarafs/data/home/hrasoara/softwares/samtools-1.18/

groups=(
  "male"
  "female"
)
mkdir -p data/downsampled
for group in "${groups[@]}"; do
    # Downsample
    echo "Downsampling ${group}..."
    # Downsample at 1/100 of the initial density the BAM file
    samtools view -s 0.01 -b "data/map_merged/merged-${group}.bam" > "data/downsampled/downsampled-${group}.bam"
done
echo "Done"