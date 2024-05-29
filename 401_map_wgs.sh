#!/bin/bash
#SBATCH -p memory
#SBATCH -N 1 -c 96
#SBATCH -t 1-00:00:00
#SBATCH -J MAPjob_ryan
#SBATCH -A proj5034

module purge
module load BWA/0.7.17-intel-2019b
module load SAMtools/1.9-intel-2019b

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
  "SRR18231401"
  "SRR18231402"
  "SRR18231403"
  "SRR18231404"
  "SRR18231405"
  "SRR18231406"
  "SRR18231407"
  "SRR18231408"
  "SRR18231409"
  "SRR18231410"
  "SRR18231411"
  "SRR18231412"
  "SRR18231413"
  "SRR18231414"
  "SRR18231415"
  "SRR18231416"
  "SRR18231417"
  "SRR18231418"
  "SRR18231419"
  "SRR18231420"
  "SRR18231421"
  "SRR18231422"
  "SRR18231423"
  "SRR18231424"
  "SRR18231425"
  "SRR18231426"
  "SRR18231427"
  "SRR18231428"
  "SRR18231429"
  "SRR18231430"
  "SRR18231431"
  "SRR19508262"
  "SRR19508263"
  "SRR19508264"
  "SRR19508265"
  "SRR19508266"
  "SRR19508282"
  "SRR19508283"
  "SRR19508290"
  "SRR19508291"
  "SRR19508300"
  "SRR19508463"
  "SRR19508464"
  "SRR19508465"
  "SRR19508466"
  "SRR19508467"
  "SRR19508468"
  "SRR19508469"
  "SRR19508472"
  "SRR19508480"
  "SRR19508496"
  "SRR6251350"
  "SRR6251351"
  "SRR6251352"
  "SRR6251353"
  "SRR6251354"
  "SRR6251355"
  "SRR6251356"
  "SRR6251357"
  "SRR6251358"
  "SRR6251359"
  "SRR6251360"
  "SRR6251361"
  "SRR6251362"
  "SRR6251363"
  "SRR6251364"
  "SRR6251365"
  "SRR6251366"
  "SRR6251367"
  "SRR7062760"
  "SRR7062761"
  "SRR7062762"
  "SRR7062763"
)

sex=$1
WGS_DIR="/tarafs/data/home/hrasoara/scratch/083-GATK-BETTA/data/cleaned_reads"
mkdir -p "date/validate_ltr/${sex}"
for genome in "${genomes[@]}"; do
  echo "Mapping ${genome}..."
  bwa mem -t 96 \
    "data/sex-specific-ltr/ltr_complete_${sex}.fas" \
    "${WGS_DIR}/${genome}_1.1.fq.gz" \
    "${WGS_DIR}/${genome}_2.2.fq.gz" \
    | samtools view -@ 96 -b -o "data/validate_ltr/${sex}/${genome}.all.bam"
  # Only keep the mapped reads
  samtools view -@ 96 -b -F 4 "data/validate_ltr/${sex}/${genome}.all.bam" \
    > "data/validate_ltr/${sex}/${genome}.unsorted.bam"
  # Sort the bam files
  samtools sort -@ 96 "data/validate_ltr/${sex}/${genome}.unsorted.bam" \
    -o "data/validate_ltr/${sex}/${genome}.bam"
  exit
done
echo "Done"
