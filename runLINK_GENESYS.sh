#/bin/bash

# this script launches linkage script to create a IAMC file out of GENeSYS-MOD inputs and outputs

echo -e "\n${print_blue}        - Create IAMC files from GENeSYS-MOD native inputs and outputs: ${no_color} ${P4R_ENV} python -W ignore ${PYTHONSCRIPTS_IN_P4R}/LinkageGENeSYS.py ${CONFIG_IN_P4R}/settingsLinkageGENeSYS.yml ${DATASET}"


P4R_CMD="srun --wckey=${WCKEY}  --nodes=1 --ntasks=1 --ntasks-per-node=1 --cpus-per-task=1 -J Format --mpi=pmix -l"
${P4R_ENV} python -W ignore ${PYTHONSCRIPTS_IN_P4R}/LinkageGENeSYS.py ${CONFIG_IN_P4R}/settingsLinkageGENeSYS.yml ${DATASET}
python_script_return_status=$(read_python_status ${INSTANCE}/python_return_status)
if [[ $python_script_return_status -ne 0 ]]; then
    echo -e "${print_red}Script $0 exited with error code ${python_script_return_status}. See above error messages.${no_color}"
    return $python_script_return_status
fi

echo -e "${print_green}        - IAMC files created successfully [$start_time].${no_color}"
