#!/bin/bash -l
#SBATCH --job-name=p4r
#SBATCH --output=p4r_out%j.txt
#SBATCH --error=p4r_err%j.txt
#SBATCH --nodes=5
#SBATCH --exclusive
#SBATCH --export=ALL
##SBATCH -t 1:0:0  # if necessary limit computation time
##SBATCH --wckey=XXX   # if you need to use a wckey
##SBATCH --partition XX   # if there are different partitions
##SBATCH --enable-turbo   # if turbo available
#export OMPI_MCA_mtl=^ofi
#OMPI_MCA_mtl=^ofi
#SBATCH --ntasks=36                  # adapt to nb of cpu per node
#SBATCH --cpus-per-task=1   

hostname

module load openmpi/4.1.6
export SINGULARITY_BIND="$P4R_DIR,$P4R_DIR_LOCAL"
export SINGULARITYENV_LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}
export P4R_SINGULARITY_IMAGE_PRESERVE=1 # avoid update of the container

export OMP_NUM_THREADS=1
export OMP_PROC_BIND=spread
export OMP_PLACES=threads

export P4R_CMD="srun --wckey=${WCKEY} --nodes=1 --ntasks=1 --distribution=cyclic --cpus-per-task=1 -l --threads-per-core=1 --mpi=pmix --enable-turbo "
source $P4R_DIR/scripts/include/run_p4r.sh "${ARGS[@]}"
echo "Nb Node used : $SLURM_JOB_NUM_NODES"
echo "Nb tasks used : $SLURM_NTASKS"
echo "Nb CPUs used : $SLURM_CPUS_ON_NODE"
echo $P4R_CMD
sstat -j $SLURM_JOB_ID.batch --format=JobID,MaxVMSize,MaxRSS,MaxPages,Nodelist,NTasks,AveCPUFreq,AveCPU,MaxDiskRead,MaxDiskWrite


