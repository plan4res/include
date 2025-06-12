#/bin/bash

source ${INCLUDE}/sh_utils.sh

remove_previous_simulation_results "simul"
create_results_dir "simul"

if check_ssv_output "simul"; then 
    ssv_output="simul"
    echo -e "${print_grees}    - Bellman values found in ${INSTANCE}/results_simul$OUT/ .${no_color}" 
else
    if check_ssv_output "optim"; then 
	ssv_output="optim"
	copy_ssv_output_from_to "optim" "simul"
	echo -e "${print_orange}    - No Bellman values found in ${INSTANCE}/results_simul$OUT/ .${no_color}" 
	echo -e "${print_orange}    - Using Bellman values from ${INSTANCE}/results_optim$OUT/ .${no_color}" 
    else
       echo -e "${print_red}    - No Bellman values found in ${INSTANCE}/results_simul$OUT/ nor $INSTANCE}/results_optim$OUT/ .${no_color}" 
       return 1
    fi
fi

filter_cuts "simul"
solver=$(get_solver "${CONFIG}/uc_solverconfig.txt")
solver=$(echo "$solver" | sed 's/MILPSolver//')
echo -e "\n${print_blue}     - using $solver to solve MILPs ${no_color}"

N_PARAL_SIM=$NBSCEN_SIM
if [ "$NBSCEN_SIM" -gt "$NB_MAX_PARALLEL_SIMUL" ] ; then
	N_SEQ=$( ceil_division $NBSCEN_SIM $NB_MAX_PARALLEL_SIMUL )
	N_PARAL_SIM=$(  ceil_division $NBSCEN_SIM $N_SEQ   )
	echo -e "${print_blue} simulations will be ran in $N_SEQ sequences of $N_PARAL_SIM scenarios ${no_color}"
fi

if check_param "${CONFIG}/BSPar-Investment.txt" "intMaxThread"; then
	intMaxThread=$(get_param_value "intMaxThread" "${CONFIG}/BSPar-Investment.txt")
	if [[ $N_PARAL_SIM -gt $intMaxThread ]]; then
		replace_param "${CONFIG}/BSPar-Investment.txt" "intMaxThread" "$N_PARAL_SIM"
		echo -e "${print_blue}    - BSPar-Investment.txt config file : replaced value of intMaxThread: $intMaxThread by $N_PARAL_SIM.${no_color}" 
	fi
else
	increment_int_param_count "${CONFIG}/BSPar-Investment.txt"
	add_str_param "${CONFIG}/BSPar-Investment.txt" "intMaxThread" "$N_PARAL_SIM"
	echo -e "${print_blue}    - BSPar-Investment.txt config file : added param intMaxThread: $N_PARAL_SIM .${no_color}" 
fi

# run investment solver
P4R_CMD="srun --wckey=${WCKEY} --nodes=1 --ntasks=1 --ntasks-per-node=1 --cpus-per-task=${CPUS_PER_NODE} --mpi=pmix -l"

# run investment solver
echo -e "\n${print_blue}  Run simulation  [$start_time] : ${no_color} ${P4R_ENV} investment_solver -n ${N_PARAL_SIM} -s -d ${INSTANCE_IN_P4R}/results_simul$OUT/ -l ${INSTANCE_IN_P4R}/results_simul$OUT/bellmanvalues.csv -e uc_solverconfig.txt -o -S BSPar-Investment.txt -c ${CONFIG_IN_P4R}/ -p ${INSTANCE_IN_P4R}/nc4_simul/ InvestmentBlock.nc4"
if [ "$solver" = "HiGHS" ]; then
	time ${P4R_ENV} investment_solver -n ${N_PARAL_SIM} -s -d ${INSTANCE_IN_P4R}/results_simul$OUT/ -l ${INSTANCE_IN_P4R}/results_simul$OUT/bellmanvalues.csv -o -S BSPar-Investment.txt -c ${CONFIG_IN_P4R}/ -p ${INSTANCE_IN_P4R}/nc4_simul/ InvestmentBlock.nc4

else
	time ${P4R_ENV} investment_solver -n ${N_PARAL_SIM} -s -d ${INSTANCE_IN_P4R}/results_simul$OUT/ -l ${INSTANCE_IN_P4R}/results_simul$OUT/bellmanvalues.csv -e uc_solverconfig.txt -o -S BSPar-Investment.txt -c ${CONFIG_IN_P4R}/ -p ${INSTANCE_IN_P4R}/nc4_simul/ InvestmentBlock.nc4
fi

wait
move_simul_results "simul"


