#/bin/bash

source ${INCLUDE}/sh_utils.sh

check_results_dir "simul"
remove_previous_simulation_results "simul"
check_ssv_output "simul"
filter_cuts "simul"
create_results_dir "simul"

# run simulation
for (( scen=0; scen<$NBSCEN_SIM; scen++ ))
do
	echo -e "\n${print_blue}     - run simulation at [$start_time] for scenario $scen ${no_color}"
	P4R_CMD="srun --wckey=${WCKEY} --nodes=1 --ntasks=1 --ntasks-per-node=1 --cpus-per-task=${CPUS_PER_NODE} --mpi=pmix -l"
	time ${P4R_ENV} sddp_solver -d ${INSTANCE_IN_P4R}/results_simul$OUT/ -l ${INSTANCE_IN_P4R}/results_simul$OUT/bellmanvalues.csv -s -i ${scen} -S ${CONFIG_IN_P4R}/sddp_greedy.txt -c ${CONFIG_IN_P4R}/ -p ${INSTANCE_IN_P4R}/nc4_simul/ ${INSTANCE_IN_P4R}/nc4_simul/SDDPBlock.nc4
done 

wait
move_simul_results "simul"
echo -e "\n${print_green}- simulations completed [$start_time] ${no_color}"
