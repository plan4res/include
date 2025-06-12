#/bin/bash

source ${INCLUDE}/sh_utils.sh

check_results_dir "simul"
create_results_dir "simul"
if [ ! -d ${INSTANCE}/results_simul$OUT/Block_$block_id ]; then mkdir ${INSTANCE}/results_simul$OUT/Block_$block_id ; fi

# run simulation
echo -e "\n${print_blue}     - run simulation at [$start_time] for block $block_id ${no_color}"
P4R_CMD="srun --wckey=${WCKEY} --nodes=1 --ntasks=1 --ntasks-per-node=1 --cpus-per-task=${CPUS_PER_NODE} --mpi=pmix -l"
time ${P4R_ENV} ucblock_solver -c ${CONFIG_IN_P4R}/ -S uc_solverconfig.txt -o 2 -p ${INSTANCE_IN_P4R}/nc4_simul/ Block_$block_id.nc4
wait
for file in $outputs; do mv ${file}OUT.csv ${INSTANCE}/results_simul$OUT/Block_$block_id/ ; done
for file in $MarginalCosts; do mv ${file}OUT.csv ${INSTANCE}/results_simul$OUT/Block_$block_id/ ; done
echo -e "\n${print_green}- simulations completed [$start_time] ${no_color}"
