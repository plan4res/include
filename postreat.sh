#/bin/bash

# run post treatment script
echo -e "\n${print_blue}        - Launch post treat:${no_color}${P4R_ENV} python -W ignore ${PYTHONSCRIPTS_IN_P4R}/PostTreatPlan4res.py ${CONFIG_IN_P4R}/settingsPostTreatPlan4res_${mode1}.yml ${CONFIG_IN_P4R}/settings_format_${mode1}.yml ${CONFIG_IN_P4R}/settingsCreateInputPlan4res_${mode1}.yml ${DATASET}"

if [ ! -d "${INSTANCE}/results_${mode1}$OUT" ]; then
	echo -e "${print_red}results_${mode1}$OUT dir does not exist${no_color}"
	return 1
fi

repos="IAMC OUT IMG Scenario*"
for dir in $repos ; do
	if [ -d "${INSTANCE}/results_${mode1}$OUT/$dir" ]; then
		echo -e "\n${print_blue}        - delete dir ${INSTANCE}/results_${mode1}$OUT/${dir}${no_color}"
		rm -rf ${INSTANCE}/results_${mode1}$OUT/${dir}
	fi
done

for dir in ${INSTANCE}/results_${mode1}$OUT/Scenario*/; do
    if [ -d "$dir" ]; then
		echo -e "\n${print_blue}        - delete dirs ${INSTANCE}/results_${mode1}$OUT/Scenario*/${no_color}"
        rm -rf ${INSTANCE}/results_${mode1}$OUT/Scenario*/
    fi
done

P4R_CMD="srun --wckey=${WCKEY}  --nodes=1 --ntasks=1 --ntasks-per-node=1 --cpus-per-task=1 -J Format --mpi=pmix -l"
${P4R_ENV} python -W ignore ${PYTHONSCRIPTS_IN_P4R}/PostTreatPlan4res.py ${CONFIG_IN_P4R}/settingsPostTreatPlan4res_${mode1}.yml ${CONFIG_IN_P4R}/settings_format_${mode1}.yml ${CONFIG_IN_P4R}/settingsCreateInputPlan4res_${mode1}.yml ${DATASET}
python_script_return_status=$(read_python_status ${INSTANCE}python_return_status)
if [[ $python_script_return_status -ne 0 ]]; then
    echo -e "${print_red}Script exited with error code ${python_return_status}. See above error messages.${no_color}"
    return $python_script_return_status
fi
echo -e "${print_green}        - post treat successful [$start_time] .${no_color}\n"
