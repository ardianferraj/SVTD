#!/bin/bash
#SBATCH --job-name=liftoff   # Job name
#SBATCH --ntasks=1                    # Run on a single CPU
#SBATCH --cpus-per-task=1            # Number of CPU cores per task
#SBATCH --mem=48G                     # Job memory request
#SBATCH --time=48:00:00               # Time limit hrs:min:sec
#SBATCH --qos batch
#SBATCH -o slurm.%x.%j.out # STDOUT
#SBATCH -e slurm.%x.%j.err # STDERR
pwd; hostname; date
set -x

# load liftoff container
module load singularity

# inputs
gencode_gtf=/projects/chesler-lab/csna/sv_ferraj/SVTD/data/ref/gencode.vM36.annotation.gtf
grcm39=/projects/chesler-lab/csna/sv_ferraj/SVTD/data/ref/mm39.fa

tmp_dir=/flashscratch/c-ferraa/liftoff_tmp/${sample}
wd=/projects/csna/sv_ferraj/SVTD/analysis/liftoff/${sample}
assembly_gzip=/projects/csna/sv_ferraj/SVTD/data/ferraj_et_al/genome_assemblies/${sample}_flye_gcpp.fa.gz
tmp_assembly=${tmp_dir}/${sample}_flye_gcpp.fa

# use mm39 for B6
if [ $sample = 'B6' ]
then
        tmp_assembly=${grcm39}
fi

# make tmp directory
mkdir -p ${tmp_dir}

if [ ${sample} != 'B6' ]
then
        # cp assembly to tmp dir and unzip
        cp ${assembly_gzip} ${tmp_dir}
        gunzip ${tmp_assembly}.gz
fi

# make and cd to working directory
mkdir -p ${wd}
cd ${wd}

# creat sym linnk for gencode gtf
ln -s ${gencode_gtf} ${wd}/gencode.vM32.annotation.gtf

singularity exec /projects/csna/sv_ferraj/SVTD/repo/containers/liftoff.sif liftoff \
  -g ${wd}/gencode.vM32.annotation.gtf \
  -o ${wd}/${sample}_liftoff_mapped.gtf \
  -u ${wd}/${sample}_liftoff_unmapped.gtf \
  ${tmp_assembly} \
  ${grcm39}