#/bin/bash


if [ -d "${INSTANCE}/csv_${mode1}" ]; then
	rm -rf ${INSTANCE}/csv_${mode1}
fi

# run script to create plan4res input dataset (ZV_ZoneValues.csv ...)
echo -e "\n${print_blue}        - Create plan4res input files: ${no_color} ${P4R_ENV} python -W ignore ${PYTHONSCRIPTS_IN_P4R}/CreateInputPlan4res.py ${CONFIG_IN_P4R}/settingsCreateInputPlan4res_${mode1}.yml ${DATASET}"
P4R_CMD="srun --wckey=${WCKEY}  --nodes=1 --ntasks=1 --ntasks-per-node=1 --cpus-per-task=1 -J Format --mpi=pmix -l"
${P4R_ENV} python -W ignore ${PYTHONSCRIPTS_IN_P4R}/CreateInputPlan4res.py ${CONFIG_IN_P4R}/settingsCreateInputPlan4res_${mode1}.yml ${DATASET}
python_script_return_status=$(read_python_status ${INSTANCE}/python_return_status)

if [[ $python_script_return_status -ne 0 ]]; then
    echo -e "${print_red}Script $0 exited with error code ${python_script_return_status}. See above error messages.${no_color}"
    return $python_script_return_status
fi

echo -e "${print_green}        - plan4res input files created successfully [$start_time].${no_color}"
