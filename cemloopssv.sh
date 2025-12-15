#/bin/bash

# this scripts:
# 1 - optionnally creates plan4res dataset (if used with -C), 
# 2 - initial runs of ssv and cem:
# 	2.1 - creates nc4 files for SSV based on csv_simul
# 	2.2 - launches SSV 
# 	2.3 - creates nc4 files for CEM based on csv_invest and cuts in results_simul
# 	2.4 - launches CEM 
# 3 - loop SSV-CEM
#	3.1 - run convergence test and exit loop if test succeeded
#	3.2 - update csv files in csv_simul and csv_invest based on previous results of CEM
#	3.3	- creates nc4 files for ssv based on csv_simul
#	3.4 - run SSV 
# 	3.5 - creates nc4 files for CEM based on csv_invest and cuts in results_simul
# 	3.6 - launches CEM 
# 4 - launches post treatments from results_invest

source ${INCLUDE}/sh_utils.sh
remove_previous_ssv_results "invest"
create_results_dir "invest"
HOTSTART_USER="$HOTSTART"

if [ "$HOTSTART_USER" = "" ]; then
	remove_previous_ssv_results "optim"
fi

FORMAT="" # option -F cannot be used
if [ -z "$EPSILON" ]; then
	EPSILON=0.01
fi
INVEST_OUTPUT=""

# change max nb of iterations in config files using number_cem_iters
if check_param "${CONFIG}/BSPar-Investment.txt" "intMaxIter"; then
	replace_param "${CONFIG}/BSPar-Investment.txt" "intMaxIter" "$number_cem_iters"
	echo -e "${print_blue}    - BSPar-Investment.txt config file : replaced value of intMaxIter by $number_cem_iters.${no_color}" 
else
	increment_int_param_count "${CONFIG}/BSPar-Investment.txt"
	add_str_param "${CONFIG}/BSPar-Investment.txt" "intMaxIter" "$number_cem_iters"
	echo -e "${print_blue}    - BSPar-Investment.txt config file : added param intMaxIter: $number_cem_iters .${no_color}" 
fi

# run script to create plan4res input dataset (ZV_ZineValues.csv ...) if used with option -C
if [[ "${CREATE}" = "CREATE" && index_scen -eq 0 ]]; then
	mode1="invest"
	echo -e "\n${print_blue}    - Create plan4res input files ${no_color}"
	source ${INCLUDE}/create.sh 
	wait
	if ! create_status; then return 1; fi	

	mode1="simul"
	source ${INCLUDE}/create.sh 
	wait
	if ! create_status; then return 1; fi	
	CREATE=""
fi

# create netcdf files for first run of ssv from csv_simul
echo -e "\n${print_orange}    - ITERATION 0 ${no_color}"
echo -e "\n${print_blue}        - Create netcdf input files to run the SSV at iteration 0 ${no_color}"
mode1="optim"
mode2="simul"
source ${INCLUDE}/format.sh 
wait
if ! format_status; then return 1; fi	

# initial run of sddp solver
echo -e "\n${print_blue}        - Initial SSV with sddp_solver to compute Bellman values for storages${no_color}"
source ${INCLUDE}/ssv.sh
wait
if ! sddp_status; then return 1; fi	

# create netcdf files for first run of investment model from csv_invest
echo -e "\n${print_blue}        - Create netcdf input files to run the CEM at iteration 0 ${no_color}"
mode1="invest"
mode2="invest"
old_number_threads=${number_threads}
number_threads=1
source ${INCLUDE}/format.sh
number_threads=${old_number_threads}
wait
if ! format_status; then return 1; fi	

# run investment solver
echo -e "\n${print_blue}        - copy Bellman values from results_optim$OUT to results_invest$OUT and run CEM at iteration 0 using investment_solver${no_color}"
copy_ssv_output_from_to "optim" "invest"
old_number_threads=${number_threads}
number_threads=$CPUS_PER_NODE
if [[ $NBSCEN_CEM -lt $number_threads ]]; then 
		number_threads=$NBSCEN_CEM
fi
source ${INCLUDE}/cem.sh
wait
if ! investment_status; then return 1; fi	
invest_output="$INVEST_OUTPUT"
number_threads=${old_number_threads}

# compute cost of current solution  
cost_before=$(solution_value "$invest_output") 
echo -e "\n${print_orange}        - value of CEM at iteration 0: $cost_before ${no_color}" 

iteration=0
# Loop for subsequent iterations, checking and waiting for each job to finish
while true; do
	HOTSTART="save" 

    # Save file cuts.txt
	echo -e "\n${print_blue}        - save cuts and Solution_OUT for iteration $iteration ${no_color}"
    cp ${INSTANCE}/results_optim$OUT/cuts.txt ${INSTANCE}/results_optim$OUT/cuts_${index_scen}_${iteration}.txt
    cp ${INSTANCE}/results_invest$OUT/Solution_OUT.csv ${INSTANCE}/results_invest$OUT/Solution_OUT_${index_scen}_${iteration}.csv
    
	P4R_CMD="srun --wckey=${WCKEY} --nodes=1 --ntasks=1 --ntasks-per-node=1 --cpus-per-task=1 --mpi=pmix -l"
	case ${index_check_distance} in
		1)
			retVal=$(${P4R_ENV} python -W ignore ${PYTHONSCRIPTS_IN_P4R}/check_distance_${index_check_distance}.py ${INSTANCE_IN_P4R}/results_invest$OUT/Solution_OUT.csv ${EPSILON})
			;;
		2)
			retVal=$(${P4R_ENV} python -W ignore ${PYTHONSCRIPTS_IN_P4R}/check_distance_${index_check_distance}.py ${INSTANCE_IN_P4R}/csv_invest/ ${INSTANCE_IN_P4R}/results_invest$OUT/Solution_OUT.csv ${EPSILON})
			;;
		3)
			retVal=$(${P4R_ENV} python -W ignore ${PYTHONSCRIPTS_IN_P4R}/check_distance_${index_check_distance}.py ${invest_output} ${EPSILON})
			;;
		*)
			echo -e "\n${print_red}        - value of distance: ${index_check_distance} is not valid ${no_color}"
			return 1
			;;
	esac
    wait
    echo -e "\n${print_blue}        - Compute distance (${index_check_distance}) : ${retVal} ${no_color}"
	
	# compute cost of current solution 	
	if [ $iteration -gt 0 ]; then
		cost_after=$(solution_value "$invest_output")  # Get the solution cost from the output
		echo -e "\n${print_blue}        - Compare previous cost $cost_before and current cost $cost_after  ${no_color}"
		compare_costs "$cost_before" "$cost_after" "$EPSILON"  # Compare the costs 
		result=$?
		cost_before=$cost_after  # Update the cost for the next iteration 
	else
		result=1
	fi
	
	# test convergence of investment_solver
	if [[ "${invest_output}" == *"stop (optimal)"* ]]; then
		RetConv="stop (optimal)"
	else
		RetConv="Not converged"
	fi
	
    # Assuming the script exits with 0 when distance and difference of costs are less than epsilon and convergence reached, or max number of iterations reached
    if [[ ( "${retVal}" == *"less"* && $result -eq 0 && "${invest_output}" == *"stop (optimal)"* ) || $iteration -ge $maxnumberloops ]]; then
		if [[ $iteration -ge $maxnumberloops ]]; then 
			echo -e "\n${print_green} Max number of iterations (cem/ssv) reached ${no_color}"
		else
			echo -e "\n${print_green} Optimal solution of investment (within cem/ssv loop) found ${no_color}"
		fi
		echo -e "\n${print_orange}        - Test1 (distance): ${retVal} ${no_color}"
		echo -e "\n${print_orange}        - Test2 (comparecost): ${result} ${no_color}"
		echo -e "\n${print_orange}        - Test3 (investment log): ${RetConv} ${no_color}"
		echo -e "\n${print_orange}        - Test4 (max iteration): iteration ${iteration}  max: ${maxnumberloops}  ${no_color}" 
		break
    else
        echo -e "\n${print_orange}        - Optimal solution of investment (within cem/ssv loop) not found => next iteration ${no_color}"
		echo -e "\n${print_orange}        - Test1 (distance): ${retVal} ${no_color}"
		echo -e "\n${print_orange}        - Test2 (comparecost): ${result} ${no_color}"
		echo -e "\n${print_orange}        - Test3 (investment log): ${RetConv} ${no_color}"
		echo -e "\n${print_orange}        - Test4 (max iteration): iteration ${iteration}  max: ${maxnumberloops}  ${no_color}" 

		iteration=$((iteration + 1))
		echo -e "\n${print_orange}    - ITERATION $iteration ${no_color}"
	
		# if the distance to the former generation mix is big or the difference between costs is big, then recompute SSV
		if [[  ("${retVal}" == *"greater"*) && ($result -eq 1)   ]]; then		
			echo -e "\n${print_orange}        - Distance to previous mix is big =>rerun SSV ${no_color}"	
			# create new netcdf files for ssv from csv_simul and results_invest
			# this will also update files in csv_simul and csv_invest from results of cem
			echo -e "\n${print_blue}        - Create netcdf input files to run SSV at iteration $iteration ${no_color}"	
			mode1="postinvest"
			mode2="simul"
			source ${INCLUDE}/format.sh
			wait 
			mode1="optim"
			if ! format_status; then return 1; fi	
    
			HOTSTART=""       
			echo -e "\n${print_blue}        - Run SSV at iteration $iteration ${no_color}"
			source ${INCLUDE}/ssv.sh
			wait
			if ! sddp_status; then return 1; fi	
    
			echo -e "\n${print_blue}        - copy Bellman values from results_optim$OUT to results_invest$OUT and run CEM at iteration $iteration ${no_color}"
			copy_ssv_output_from_to "optim" "invest"		
		else
			echo -e "\n${print_orange}        - Distance to previous mix is low, no need to rerun SSV, rerun CEM in HOTSTART mode ${no_color}"
		fi
		if [[ $iteration -le $maxnumberloops ]]; then 		
			HOTSTART="save"			
			# run cem and return invest_output
			old_number_threads=${number_threads}
			number_threads=$CPUS_PER_NODE
			if [[ $NBSCEN_CEM -lt $number_threads ]]; then 
				number_threads=$NBSCEN_CEM
			fi
			source ${INCLUDE}/cem.sh
			wait
			if ! investment_status; then return 1; fi
			
			invest_output="$INVEST_OUTPUT"	
			number_threads=${old_number_threads}
			HOTSTART=$HOTSTART_USER
		fi
		
	fi
done
# when loop is finished: re-run CEM if optimum not reached

if [[ "${invest_output}" == *"stop (optimal)"* ]]; then
	RetConv="stop (optimal)"
else
	RetConv="Not converged"
fi

if [[ RetConv != "stop (optimal)" ]]; then
	echo -e "\n${print_orange}    - Restart CEM in hotstart mode ${no_color}"
	# restart cem in hotstart
	HOTSTART="$HOTSTART_USER"
	if [[ -z "$NumberOfCemIterations" ]]; then
		replace_param "${CONFIG}/BSPar-Investment.txt" "intMaxIter" "50"
		echo -e "${print_blue}        - BSPar-Investment.txt config file : replaced value of intMaxIter by 50.${no_color}"	
	else		
		if [[ $NumberOfCemIterations == 0 ]]; then 
			echo -e "no last CEM"
		else 
			replace_param "${CONFIG}/BSPar-Investment.txt" "intMaxIter" "$NumberOfCemIterations"
			echo -e "${print_blue}        - BSPar-Investment.txt config file : replaced value of intMaxIter by $NumberOfCemIterations.${no_color}"
		fi
	fi
	old_number_threads=${number_threads}
	number_threads=$CPUS_PER_NODE
	if [[ $NBSCEN_CEM -lt $number_threads ]]; then 
		number_threads=$NBSCEN_CEM
	fi
	source ${INCLUDE}/cem.sh
	number_threads=${old_number_threads}
	wait
	if ! investment_status; then return 1; fi	
	invest_output="$INVEST_OUTPUT"	
fi

# run post treatment script
# Solution_OUT contains the global solution of the investment, starting from the initial mix
# posttreat had been modified to use the saved version of the csv files before the last iteration of cemloop
# posttreat should be changed back and SOlutionOUT used in a further versiuon
number_threads=1
mode1="postinvest"
mode2="simul"
source ${INCLUDE}/format.sh
cp ${INSTANCE}/results_invest$OUT/Solution_ONES.csv ${INSTANCE}/results_invest$OUT/Solution_OUT.csv

echo -e "\n${print_blue}    - launch post treat${no_color}"
mode1="invest"
source ${INCLUDE}/postreat.sh
wait

# Job completion and diagnostic output
#job_id=$SLURM_JOB_ID
#echo "Job ID: $job_id"
#sacct -j $job_id --format=JobID,JobName%30,P  artition,Account,AllocCPUS,State,ExitCode,Elapsed,TotalCPU,UserCPU,SystemCPU,MaxRSS,NodeList
#scontrol show job $job_id

