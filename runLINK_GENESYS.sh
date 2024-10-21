#/bin/bash

# this script launches linkage script to create a IAMC file out of GENeSYS-MOD inputs and outputs
source ${INCLUDE}/utils.sh

echo -e "\n${print_green}Launching GENeSYS-MOD linkage script for $DATASET - [$start_time]${no_color}"


echo -e "\n${print_orange}Step 1 - Create IAMC file from inputs/outputs of GENeSYS-MOD: ${no_color}${P4R_ENV} python -W ignore ${PYTHONSCRIPTS}LinkageGENeSYS.py /${CONFIG}settingsLinkageGENeSYS.yml ${DATASET}"
# run script to create plan4res input dataset (ZV_ZineValues.csv ...)
${P4R_ENV} python -W ignore ${PYTHONSCRIPTS_IN_P4R}LinkageGENeSYS.py /${CONFIG_IN_P4R}settingsLinkageGENeSYS.yml ${DATASET}
python_script_return_status=$(read_python_status ${INSTANCE}python_return_status)
if [[ $python_script_return_status -ne 0 ]]; then
    echo -e "${print_red}Script exited with error code ${python_script_return_status}. See above error messages.${no_color}"
    exit $python_script_return_status
fi
echo -e "${print_green}$(date +'%m/%d/%Y %H:%M:%S') - IAMC file created successfully.${no_color}\n"
