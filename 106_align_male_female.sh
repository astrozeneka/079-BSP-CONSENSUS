#!/bin/bash
#SBATCH -p memory
#SBATCH -N 1 -c 32
#SBATCH -t 48:00:00
#SBATCH --mem=250G
#SBATCH -J BWAjob_ryan
#SBATCH -A proj5034

# if the --local flag is used
if [ "$1" == "--local" ]; then
  echo "Running locally"
  source /mnt/extra/Softwares/cactus/venv/bin/activate
else
  echo "Running on slurm"
  module purge
  module load bzip2/1.0.8-GCCcore-10.2.0
  module load ncurses/6.2-GCCcore-10.2.0
  module load foss/2021b
  module load Singularity/3.3.0
  source /tarafs/data/home/hrasoara/proj5057-AGBKUB/ryan/Softwares/cactus/venv/bin/activate
  export PATH=$PATH:/tarafs/data/project/proj5057-AGBKUB/24-ryan/Softwares/cactus/bin
fi

cat <<EOF > data/consensus.txt
consensus_male ./data/downsampled/consensus-male.fa
consensus_female ./data/downsampled/consensus-female.fa
EOF

cactus-pangenome ./js data/consensus.txt --outDir cactus --outName consensus --reference consensus_male \
	--binariesMode singularity
echo "Done"
