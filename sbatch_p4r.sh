#!/bin/bash -l
#SBATCH --job-name=p4r
#SBATCH --output=p4r_out%j.txt
#SBATCH --error=p4r_err%j.txt
#SBATCH --nodes=5
#SBATCH --exclusive
#SBATCH --export=ALL

hostname

module load openmpi/4.1.6
export SINGULARITY_BIND="$P4R_DIR,$P4R_DIR_LOCAL"
export SINGULARITYENV_LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}
export P4R_SINGULARITY_IMAGE_PRESERVE=1 # avoid update of the container
P4R_CMD="srun --wckey=${WCKEY} --nodes=1 --ntasks=1 --ntasks-per-node=1 --distribution=cyclic --cpus-per-task=1 -l --threads-per-core=1 --mpi=pmix"

export OMP_NUM_THREADS=1
export OMP_PROC_BIND=spread
export OMP_PLACES=threads

source $P4R_DIR/p4r-env/scripts/include/run_p4r.sh "${ARGS[@]}"
echo "Nb Node used : $SLURM_JOB_NUM_NODES"
echo "Nb tasks used : $SLURM_NTASKS"
echo "Nb CPUs used : $SLURM_CPUS_ON_NODE"
sstat -j $SLURM_JOB_ID.batch --format=JobID,MaxVMSize,MaxRSS,MaxPages,Nodelist,NTasks,AveCPUFreq,AveCPU,MaxDiskRead,MaxDiskWrite


