#/bin/bash

source ${INCLUDE}/sh_utils.sh

if [ "${mode1}" = "optimAfterInvest" ]; then
	rm -rf ${INSTANCE}/nc4_optim
else 
	rm -rf ${INSTANCE}/nc4_${mode1}
fi

if [ "${mode1}" = "simul" ] || [ "${mode1}" = "invest" ]; then
	if check_ssv_output "${mode1}"; then 
		cp ${INSTANCE}/results_${mode1}$OUT/bellmanvalues.csv ${INSTANCE}/csv_${mode1}/
	elif check_ssv_output "optim"; then 
		cp ${INSTANCE}/results_optim$OUT/bellmanvalues.csv ${INSTANCE}/csv_${mode1}/
	fi
fi
# run formatting script to create netcdf input files for running the cem
echo -e "\n${print_blue}        - Create netcdf input files: ${no_color}${P4R_ENV} python -W ignore${PYTHONSCRIPTS_IN_P4R}/format.py ${CONFIG_IN_P4R}/settings_format_${mode1}.yml ${CONFIG_IN_P4R}/settingsCreateInputPlan4res_${mode2}.yml ${DATASET}"

P4R_CMD="srun --wckey=${WCKEY}  --nodes=1 --ntasks=1 --ntasks-per-node=1 --cpus-per-task=1 -J Format --mpi=pmix -l"
${P4R_ENV} python -W ignore ${PYTHONSCRIPTS_IN_P4R}/format.py ${CONFIG_IN_P4R}/settings_format_${mode1}.yml ${CONFIG_IN_P4R}/settingsCreateInputPlan4res_${mode2}.yml ${DATASET} ${number_threads}

python_script_return_status=$(read_python_status ${INSTANCE}python_return_status)

if [[ $python_script_return_status -ne 0 ]]; then
    echo -e "${print_red}Script exited with error code ${python_script_return_status}. See above error messages.${no_color}"
    return $python_script_return_status
fi
echo -e "${print_green}        - netcdf input files created successfully [$start_time].${no_color}\n"

