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
source /tarafs/data/home/hrasoara/proj5057-AGBKUB/ryan/Softwares/cactus/venv/bin/activate

# write to file using cat and pipe
cat <<EOF > data/consensus.txt
consensus_male ./data/consensus/consensus-male.fa
consensus_female ./data/consensus/consensus-female.fa
EOF

cactus-pangenome ./js data/consensus.txt --outputDir data/cactus --outName consensus --reference consensus_male