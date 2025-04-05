#/bin/bash

# this scripts:
# 1 - creates plan4res dataset, 
# 2 - creates nc4 files for SSV
# 3 - launches SSV 
# 4 - creates nc4 files for CEM
# 5 - launches CEM 
# 6 - launches post treatments

if [[ ! "$HOTSTART" = "HOTSTART" ]]; then
	remove_previous_ssv_results "invest"
fi
remove_previous_simulation_results "invest"

# run script to create plan4res input dataset (ZV_ZineValues.csv ...)
# comment if you are using handmade datasets
if [ "$LINKGENESYS" = "LINKGENESYS" ]; then
	echo -e "\n${print_green}Launching IAMC dataset creation for $DATASET - [$start_time]${no_color}"
	source ${INCLUDE}/runLINK_GENESYS.sh 
	if ! linkgenesys_status; then return 1; fi			
fi

if [ "$CREATE" = "CREATE" ]; then
	mode1="invest"
	echo -e "\n${print_blue}    Step 1 - Create plan4res input files ${no_color}"
	source ${INCLUDE}/create.sh 
	wait
	if ! create_status; then return 1; fi	
fi

# run script to create netcdf files for ssv
# comment if you are using aleady created nc4
if [ "$FORMAT" = "FORMAT" ]; then
	echo -e "\n${print_blue}    Step 2 - Create netcdf input files to run the SSV ${no_color}"
	mode1="optim"
	mode2="invest"
	source ${INCLUDE}/format.sh 
	wait
	if ! format_status; then return 1; fi	
fi

# run sddp solver
echo -e "\n${print_blue}    Step 3 - run SSV with sddp_solver to compute Bellman values for storages${no_color}"
mode1="invest"
mode2="invest"
source ${INCLUDE}/ssv.sh
wait
if ! sddp_status; then return 1; fi

# run formatting script to create netcdf input files for the investment model
if [ "$FORMAT" = "FORMAT" ]; then
	echo -e "\n${print_blue}     Step 4 - Create netcdf input files to run the CEM ${no_color}"
	rm -r ${INSTANCE}/nc4_invest
	source ${INCLUDE}/format.sh
	wait
	if ! format_status; then return 1; fi	
fi

# run investment solver
echo -e "\n${print_blue}    Step 5 - run CEM using investment_solver${no_color}"
source ${INCLUDE}/cem.sh
wait
if ! investment_status; then return 1; fi
if ! simulation_status; then return 1; fi
echo "$INVEST_OUTPUT"

# run post treatment script
echo -e "\n${print_blue}    Step 6 - launch post treat${no_color}"
source ${INCLUDE}/postreat.sh
