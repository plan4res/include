#/bin/bash

source ${INCLUDE}/sh_utils.sh

check_results_dir "simul"
#remove_previous_simulation_results "simul"
check_ssv_output "simul"
filter_cuts "simul"
create_results_dir "simul"
solver=$(get_solver "${CONFIG}/uc_solverconfig.txt")
solver=$(echo "$solver" | sed 's/MILPSolver//')
echo -e "\n${print_blue}     - using $solver to solve MILPs ${no_color}"

# run simulation
#for (( scen=0; scen<$NBSCEN_SIM; scen++ ))
#do
echo -e "\n${print_blue}     - run simulation at [$start_time] for scenario $indexsim ${no_color}"
P4R_CMD="srun --wckey=${WCKEY} --nodes=1 --ntasks=1 --ntasks-per-node=1 --cpus-per-task=${CPUS_PER_NODE} --mpi=pmix -l"
echo -e "${P4R_ENV} sddp_solver -d ${INSTANCE_IN_P4R}/results_simul$OUT/ -l ${INSTANCE_IN_P4R}/results_simul$OUT/bellmanvalues.csv -s -i ${indexsim} -e uc_solverconfig.txt -S sddp_greedy.txt -c ${CONFIG_IN_P4R}/ -p ${INSTANCE_IN_P4R}/nc4_simul/$OUT SDDPBlock.nc4"
if [ "$solver" = "HiGHS" ]; then
	time ${P4R_ENV} sddp_solver -d ${INSTANCE_IN_P4R}/results_simul$OUT/ -l ${INSTANCE_IN_P4R}/results_simul$OUT/bellmanvalues.csv -s -i ${indexsim} -S sddp_greedy.txt -c ${CONFIG_IN_P4R}/ -p ${INSTANCE_IN_P4R}/nc4_simul/$OUT SDDPBlock.nc4

else
	time ${P4R_ENV} sddp_solver -d ${INSTANCE_IN_P4R}/results_simul$OUT/ -l ${INSTANCE_IN_P4R}/results_simul$OUT/bellmanvalues.csv -s -i ${indexsim} -e uc_solverconfig.txt -S sddp_greedy.txt -c ${CONFIG_IN_P4R}/ -p ${INSTANCE_IN_P4R}/nc4_simul/$OUT SDDPBlock.nc4	
fi
#done 

wait
#move_simul_results "simul"
echo -e "\n${print_green}- simulations completed [$start_time]  results NOT moved ${no_color}"
