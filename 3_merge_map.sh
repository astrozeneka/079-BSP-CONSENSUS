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

sex=$1 # male, female
if [ $sex = "male" ]; then
  genomes=(
    "ERR3332434"
    "ERR3332435"
    "ERR3332436"
    "ERR3332437"
    "SRR18231392"
    "SRR18231393"
    "SRR18231394"
    "SRR18231395"
    "SRR18231396"
    "SRR18231397"
    "SRR18231399"
    "SRR18231403"
    "SRR18231406"
    "SRR18231409"
    "SRR18231410"
    "SRR18231411"
    "SRR18231413"
    "SRR18231414"
    "SRR18231417"
    "SRR18231418"
    "SRR18231419"
    "SRR18231420"
    "SRR18231421"
    "SRR18231423"
    "SRR18231424"
    "SRR18231427"
    "SRR7062760"
    "SRR7062761"
    "SRR7062762"
    "SRR7062763"
  )
elif [ $sex = "female" ]; then
  genomes=(
    "SRR18231401"
    "SRR18231402"
    "SRR18231404"
    "SRR18231405"
    "SRR18231407"
    "SRR18231408"
    "SRR18231412"
    "SRR18231415"
    "SRR18231416"
    "SRR18231422"
    "SRR18231425"
    "SRR18231426"
    "SRR18231428"
    "SRR18231429"
    "SRR18231430"
    "SRR18231431"
  )
fi

mkdir -p data/map_merged
# Merge all of the bam files into one merged bam
args=""
for genome in "${genomes[@]}"; do
  args+="data/map_sorted/${genome}.sorted.bam "
done
echo "Merging ${args} ..."
samtools merge -@ 120 "data/map_merged/merged-${sex}.bam" $args
echo "Merging done"