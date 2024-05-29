

# Run this BASH command to open docker container
docker run --rm -ti -v /root/Projects/079-BSP-CONSENSUS/data:/app/data drostlab/ltrpred

# set R working directory
# setwd("/app/data/downsampled")

# R code
library("LTRpred")
LTRpred::LTRpred(genome.file="/app/data/downsampled/consensus-male.fa")
LTRpred::LTRpred(genome.file="/app/data/downsampled/consensus-female.fa")