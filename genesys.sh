#/bin/bash

echo -e "\n${print_green}Launching GENeSYS-MOD - [$start_time]${no_color}"
export GENESYS_IN_P4R="${GENESYS_IN_P4R}"
export DATA_IN_P4R="${DATA_IN_P4R}"
export DATASET="${DATASET}"
export ADDONS_IN_P4R=${ADDONS_IN_P4R}

${P4R_ENV} julia ${DATA_IN_P4R}/${DATASET}/runGENESYS.jl "${GENESYS_IN_P4R}" "${DATA_IN_P4R}" "${DATASET}"


#P4R_CMD="srun --wckey=${WCKEY} --nodes=${SLURM_JOB_NUM_NODES} --ntasks=${SLURM_JOB_NUM_NODES} --cpus-per-task=36 --mpi=pmix -l"


#echo "julia --banner=no ${DATA_IN_P4R}/${DATASET}/runGENESYS.jl"
#${P4R_ENV} julia --banner=no ${DATA_IN_P4R}/${DATASET}/runGENESYS.jl 
