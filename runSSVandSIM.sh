#/bin/bash

# this scripts:
# 1 - creates plan4res dataset, 
# 2 - creates nc4 files for SSV
# 3 - launches SSV 
# 4 - creates nc4 files for SIM
# 5 - launches SIM 
# 6 - launches post treatments

if [[ ! "$HOTSTART" = "HOTSTART" ]]; then
	remove_previous_ssv_results "simul"
fi
remove_previous_simulation_results "simul"

# run script to create plan4res input dataset (ZV_ZineValues.csv ...)
# comment if you are using handmade datasets
if [ "$CREATE" = "CREATE" ]; then
	mode1="simul"
	echo -e "\n${print_blue}    Step 1 - Create plan4res input files${no_color}"
	source ${INCLUDE}/create.sh 
	wait
	if ! create_status; then return 1; fi	
fi

# run script to create netcdf files for ssv
# comment if you are using aleady created nc4
if [ "$FORMAT" = "FORMAT" ]; then
	mode1="optim"
	mode2="simul"
	echo -e "\n${print_blue}    Step 2 - Create netcdf input files to run the SSV${no_color}"
	source ${INCLUDE}/format.sh 
	wait
	if ! format_status; then return 1; fi	
fi

# run sddp solver
echo -e "\n${print_blue}    Step 3 - run SSV ${no_color}"
mode1="simul"
mode1="simul"
source ${INCLUDE}/ssv.sh
wait
if ! sddp_status; then return 1; fi

# run formatting script to create netcdf input files for the SIM
if [ "$FORMAT" = "FORMAT" ]; then
	echo -e "\n${print_blue}    Step 4 - Create netcdf input files to run the SIM${no_color}"
	source ${INCLUDE}/format.sh
	wait
	if ! format_status; then return 1; fi	
fi

# run simulations using sddp_solver
echo -e "\n${print_blue}    Step 5 - run SIM using sddp_solver${no_color}"
source ${INCLUDE}/simCEM.sh
wait
if ! simulation_status; then return 1; fi

# run post treatment script
echo -e "\n${print_blue}    Step 6 - launch post treat${no_color}"
source ${INCLUDE}/postreat.sh
