#/bin/bash

source ${INCLUDE}/sh_utils.sh

check_results_dir "simul"
if [[ ($onesim -eq 0) ]]; then
	remove_previous_simulation_results "simul"
fi
check_ssv_output "simul"

create_results_dir "simul"
solver=$(get_solver "${CONFIG}/uc_solverconfig.txt")
solver=$(echo "$solver" | sed 's/MILPSolver//')
N_CPUS_PER_TASK=$number_threads
echo -e "\n${print_blue}     - using $solver to solve MILPs ${no_color}"

if [[ ($onesim -eq 0) && ($groupsim -eq 0) && ($onegroupsim -eq 0) ]]; then
	filter_cuts "simul"
	echo -e "\n${print_blue}     - run simulation at [$start_time] for all scenarios ${no_color}"
	# run simulation for all scenarios one after the other
	for (( scen=0; scen<$NBSCEN_SIM; scen++ ))
	do
		echo -e "\n${print_blue}     - run simulation at [$start_time] for scenario $indexsim ${no_color}"
		P4R_CMD="srun --wckey=${WCKEY} --nodes=1 --ntasks=1 --ntasks-per-node=1 --cpus-per-task=${CPUS_PER_NODE} --mpi=pmix -l"
		echo -e "${P4R_ENV} sddp_solver -d ${INSTANCE_IN_P4R}/results_simul${OUT}/ -l ${INSTANCE_IN_P4R}/results_simul${OUT}/bellmanvalues.csv -s -i ${scen} -e uc_solverconfig.txt -S sddp_greedy.txt -c ${CONFIG_IN_P4R}/ -p ${INSTANCE_IN_P4R}/nc4_simul/ SDDPBlock.nc4"
		if [ "$solver" = "HiGHS" ]; then
			time ${P4R_ENV} sddp_solver -d ${INSTANCE_IN_P4R}/results_simul${OUT}/ -l ${INSTANCE_IN_P4R}/results_simul${OUT}/bellmanvalues.csv -s -i ${scen} -S sddp_greedy.txt -c ${CONFIG_IN_P4R}/ -p ${INSTANCE_IN_P4R}/nc4_simul/ SDDPBlock.nc4

		else
			time ${P4R_ENV} sddp_solver -d ${INSTANCE_IN_P4R}/results_simul${OUT}/ -l ${INSTANCE_IN_P4R}/results_simul${OUT}/bellmanvalues.csv -s -i ${scen} -e uc_solverconfig.txt -S sddp_greedy.txt -c ${CONFIG_IN_P4R}/ -p ${INSTANCE_IN_P4R}/nc4_simul/ SDDPBlock.nc4	
		fi
		wait
	done 
	move_simul_results "simul"
fi
if [[ ($onesim -eq 1) && ($onegroupsim -eq 0) ]]; then
	filter_cuts "simul"
	# run one simulation
	echo -e "\n${print_blue}     - run simulation at [$start_time] for scenario $indexsim ${no_color}"
	P4R_CMD="srun --wckey=${WCKEY} --nodes=1 --ntasks=1 --ntasks-per-node=1 --cpus-per-task=${CPUS_PER_NODE} --mpi=pmix -l"
	echo -e "${P4R_ENV} sddp_solver -d ${INSTANCE_IN_P4R}/results_simul${OUT}/ -l ${INSTANCE_IN_P4R}/results_simul${OUT}/bellmanvalues.csv -s -i ${indexsim} -e uc_solverconfig.txt -S sddp_greedy.txt -c ${CONFIG_IN_P4R}/ -p ${INSTANCE_IN_P4R}/nc4_simul/ SDDPBlock.nc4"
	if [ "$solver" = "HiGHS" ]; then
		time ${P4R_ENV} sddp_solver -d ${INSTANCE_IN_P4R}/results_simul${OUT}/ -l ${INSTANCE_IN_P4R}/results_simul${OUT}/bellmanvalues.csv -s -i ${indexsim} -S sddp_greedy.txt -c ${CONFIG_IN_P4R}/ -p ${INSTANCE_IN_P4R}/nc4_simul/ SDDPBlock.nc4
	else
		time ${P4R_ENV} sddp_solver -d ${INSTANCE_IN_P4R}/results_simul${OUT}/ -l ${INSTANCE_IN_P4R}/results_simul${OUT}/bellmanvalues.csv -s -i ${indexsim} -e uc_solverconfig.txt -S sddp_greedy.txt -c ${CONFIG_IN_P4R}/ -p ${INSTANCE_IN_P4R}/nc4_simul/ SDDPBlock.nc4	
	fi
	wait
fi
if [[ ($groupsim -eq 1) && ($sizegroupsim -ge 1) && ($onegroupsim -eq 0) ]]; then
	echo -e "\n${print_blue}     - run format and simulation at [$start_time] for groups of scenarios of size $sizegroupsim ${no_color}"
	update_yaml_param "${CONFIG}/settingsCreateInputPlan4res.yml" 2 "ParametersCreate invest" no
	if check_ssv_output "simul"; then 
		cp ${INSTANCE}/results_${mode1}${OUT}/bellmanvalues.csv ${INSTANCE}/csv_${mode1}/
	fi
	# run groups of simulations in parallel
	
	# compute number of groups
	BASE=$(( NBSCEN_SIM / sizegroupsim ))
	RESTE=$(( NBSCEN_SIM % sizegroupsim ))
	if [ $RESTE -ge 1 ]; then
		nb_group_sim=$(( BASE + 1 ))
	else	
		nb_group_sim=$BASE
	fi
	
	current_first_scen=0
	sizecurrentgroup=$sizegroupsim
	number_remaining_scen=$NBSCEN_SIM
	for ((grp=0; grp<$nb_group_sim; grp++)); do
		# format for current group of scenarios
		if [ $number_remaining_scen -lt $sizegroupsim ] ; then
			sizecurrentgroup=$number_remaining_scen
		else
			sizecurrentgroup=$sizegroupsim
		fi
		echo -e "\n${print_blue}     - run group of scenario $grp of size $sizecurrentgroup starting at scenario $current_first_scen ${no_color}"

		if [ $sizecurrentgroup -gt 0 ]; then
			
			create_format_settings_group "${CONFIG_IN_P4R}/settings_format_${mode1}.yml" "${INSTANCE_IN_P4R}/results_simul${OUT}/settings_format_${mode1}_$grp.yml" $grp $current_first_scen $sizecurrentgroup
					
			# create netcdf
			if [[ ! -d "${INSTANCE_IN_P4R}/results_simul${OUT}_${grp}" ]]; then
				mkdir "${INSTANCE_IN_P4R}/results_simul${OUT}_${grp}"
			fi
			if [[ ! -d "${INSTANCE_IN_P4R}/nc4_simul_${grp}" ]]; then
				mkdir "${INSTANCE_IN_P4R}/nc4_simul_${grp}"
			fi
			echo -e "\n${print_blue}        - Create netcdf input files: ${no_color}${P4R_ENV} python -W ignore${PYTHONSCRIPTS_IN_P4R}/format.py ${CONFIG_IN_P4R}/settings_format_${mode1}_${grp}.yml ${CONFIG_IN_P4R}/settingsCreateInputPlan4res.yml ${DATASET} ${no_color}"

			if [ "$FORMAT" = "FORMATGROUP" ]; then
				P4R_CMD="srun --wckey=${WCKEY}  --nodes=1 --ntasks=1 --ntasks-per-node=1 --cpus-per-task=1 -J Format --mpi=pmix -l"
				cp ${INSTANCE}/results_${mode1}${OUT}/bellmanvalues.csv ${INSTANCE_IN_P4R}/results_simul${OUT}_${grp}/
				${P4R_ENV} python -W ignore ${PYTHONSCRIPTS_IN_P4R}/format.py "${INSTANCE_IN_P4R}/results_simul${OUT}/settings_format_${mode1}_$grp.yml" "${CONFIG_IN_P4R}/settingsCreateInputPlan4res.yml" ${DATASET} ${number_threads}
				wait
			fi
			filter_cuts "simul" "$grp"
			
			# run simulation 
			if [[ -d "${INSTANCE_IN_P4R}/nc4_simul_${grp}" ]]; then 
				P4R_CMD="srun --wckey=${WCKEY} --nodes=1 --ntasks=1 --ntasks-per-node=1 --cpus-per-task=${CPUS_PER_NODE} --mpi=pmix -l"		
				for (( scen=0; scen<$sizecurrentgroup; scen++ ))
				do
					if [ "$solver" = "HiGHS" ]; then
						time ${P4R_ENV} sddp_solver -d "${INSTANCE_IN_P4R}/results_simul${OUT}_${grp}/" -l "${INSTANCE_IN_P4R}/results_simul${OUT}_${grp}/bellmanvalues.csv" -s -i ${scen} -S sddp_greedy.txt -c ${CONFIG_IN_P4R}/ -p "${INSTANCE_IN_P4R}/nc4_simul_${grp}/" SDDPBlock.nc4
					else
						time ${P4R_ENV} sddp_solver -d "${INSTANCE_IN_P4R}/results_simul${OUT}_${grp}/" -l "${INSTANCE_IN_P4R}/results_simul${OUT}_${grp}/bellmanvalues.csv" -s -i ${scen} -e uc_solverconfig.txt -S sddp_greedy.txt -c ${CONFIG_IN_P4R}/ -p "${INSTANCE_IN_P4R}/nc4_simul_${grp}/" SDDPBlock.nc4	
					fi
					wait
				done
				
				
				# renumber scenarios
				move_simul_results_group $grp $current_first_scen $sizecurrentgroup
			else
				echo -e "\n${print_red}        - ${INSTANCE_IN_P4R}/nc4_simul_${grp} does not exist, run with option -F ${no_color}"			
			fi
			old_current_first_scen=$current_first_scen
			current_first_scen=$(( old_current_first_scen + sizecurrentgroup ))
			number_remaining_scen=$(( number_remaining_scen - sizecurrentgroup ))
		fi
	done
	move_simul_results "simul"
fi

if [[ ($onegroupsim -eq 1) ]]; then
	echo -e "\n${print_blue}     - run format and simulation at [$start_time] for the group $numgroupsim of scenarios of size $sizegroupsim ${no_color}"
	update_yaml_param "${CONFIG}/settingsCreateInputPlan4res.yml" 2 "ParametersCreate invest" no
	if check_ssv_output "simul"; then 
		cp ${INSTANCE}/results_${mode1}${OUT}/bellmanvalues.csv ${INSTANCE}/csv_${mode1}/
	fi
	# run groups of simulations in parallel
	
	# compute number of groups
	BASE=$(( NBSCEN_SIM / sizegroupsim ))
	RESTE=$(( NBSCEN_SIM % sizegroupsim ))
	if [ $RESTE -ge 1 ]; then
		nb_group_sim=$(( BASE + 1 ))
	else	
		nb_group_sim=$BASE
	fi
	
	current_first_scen=0
	sizecurrentgroup=$sizegroupsim
	number_remaining_scen=$NBSCEN_SIM
	for ((grp=0; grp<$numgroupsim; grp++)); do
		# format for current group of scenarios
		if [ $number_remaining_scen -lt $sizegroupsim ] ; then
			sizecurrentgroup=$number_remaining_scen
		else
			sizecurrentgroup=$sizegroupsim
		fi
		old_current_first_scen=$current_first_scen
		current_first_scen=$(( old_current_first_scen + sizecurrentgroup ))
		number_remaining_scen=$(( number_remaining_scen - sizecurrentgroup ))
	done

	if [ $sizecurrentgroup -gt 0 ]; then
		
		create_format_settings_group "${CONFIG_IN_P4R}/settings_format_${mode1}.yml" "${INSTANCE_IN_P4R}/results_simul${OUT}/settings_format_${mode1}_$numgroupsim.yml" $numgroupsim $current_first_scen $sizecurrentgroup
				
		# create netcdf
		if [[ ! -d "${INSTANCE_IN_P4R}/results_simul${OUT}_${numgroupsim}" ]]; then
			mkdir "${INSTANCE_IN_P4R}/results_simul${OUT}_${numgroupsim}"
		fi
		if [[ ! -d "${INSTANCE_IN_P4R}/nc4_simul_${numgroupsim}" ]]; then
			mkdir "${INSTANCE_IN_P4R}/nc4_simul_${numgroupsim}"
		fi

		if [ "$FORMAT" = "FORMATGROUP" ]; then
			echo -e "\n${print_blue}        - Create netcdf input files: ${no_color}${P4R_ENV} python -W ignore${PYTHONSCRIPTS_IN_P4R}/format.py ${CONFIG_IN_P4R}/settings_format_${mode1}_${numgroupsim}.yml ${CONFIG_IN_P4R}/settingsCreateInputPlan4res.yml ${DATASET}"
			P4R_CMD="srun --wckey=${WCKEY} --nodes=1 --ntasks=1 --ntasks-per-node=1 --cpus-per-task=1 -J Format --mpi=pmix -l"
			cp ${INSTANCE}/results_${mode1}${OUT}/bellmanvalues.csv ${INSTANCE_IN_P4R}/results_simul${OUT}_${numgroupsim}/
			${P4R_ENV} python -W ignore ${PYTHONSCRIPTS_IN_P4R}/format.py "${INSTANCE_IN_P4R}/results_simul${OUT}/settings_format_${mode1}_$numgroupsim.yml" "${CONFIG_IN_P4R}/settingsCreateInputPlan4res.yml" ${DATASET} ${number_threads}
			wait
		fi
		filter_cuts "simul" "$numgroupsim"
		
		# run simulation 
		if [[ -d "${INSTANCE_IN_P4R}/nc4_simul_${numgroupsim}" ]]; then 
			P4R_CMD="srun --wckey=${WCKEY} --nodes=1 --ntasks-per-node=1 --cpus-per-task=${N_CPUS_PER_TASK} --mpi=pmix -l"					
			for (( scen=0; scen<$sizecurrentgroup; scen++ ))
			do
				if [ "$solver" = "HiGHS" ]; then
					time ${P4R_ENV} sddp_solver -d "${INSTANCE_IN_P4R}/results_simul${OUT}_${numgroupsim}/" -l "${INSTANCE_IN_P4R}/results_simul${OUT}_${numgroupsim}/bellmanvalues.csv" -s -i ${scen} -S sddp_greedy.txt -c ${CONFIG_IN_P4R}/ -p "${INSTANCE_IN_P4R}/nc4_simul_${numgroupsim}/" SDDPBlock.nc4
				else
					time ${P4R_ENV} sddp_solver -d "${INSTANCE_IN_P4R}/results_simul${OUT}_${numgroupsim}/" -l "${INSTANCE_IN_P4R}/results_simul${OUT}_${numgroupsim}/bellmanvalues.csv" -s -i ${scen} -e uc_solverconfig.txt -S sddp_greedy.txt -c ${CONFIG_IN_P4R}/ -p "${INSTANCE_IN_P4R}/nc4_simul_${numgroupsim}/" SDDPBlock.nc4	
				fi
				wait
			done
			
			
			# renumber scenarios
			move_simul_results_group $numgroupsim $current_first_scen $sizecurrentgroup
			move_simul_results "simul"
		else
			echo -e "\n${print_red}        - ${INSTANCE_IN_P4R}/nc4_simul_${numgroupsim} does not exist, run with option -F ${no_color}"			
		fi
	fi
	
fi

wait

echo -e "\n${print_green}- simulations completed [$start_time] ${no_color}"
