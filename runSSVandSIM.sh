#/bin/bash

# this scripts:
# 1 - creates plan4res dataset, 
# 2 - creates nc4 files for SSV
# 3 - launches SSV 
# 4 - creates nc4 files for SIM
# 5 - launches SIM 
# 6 - launches post treatments


# run script to create plan4res input dataset (ZV_ZineValues.csv ...)
# comment if you are using handmade datasets
mode1="simul"
mode2="simul"
echo -e "\n${print_orange}Step 1 - Create plan4res input files${no_color}"
source ${INCLUDE}/create.sh 

# run script to create netcdf files for ssv
# comment if you are using aleady created nc4
mode1="optim"
echo -e "\n${print_orange}Step 2 - Create netcdf input files to run the SSV${no_color}"
source ${INCLUDE}/format.sh 

# run sddp solver
echo -e "\n${print_orange}Step 3 - run SSV "
source ${INCLUDE}/ssv.sh

# run formatting script to create netcdf input files for the SIM
mode1="simul"
echo -e "\n${print_orange}Step 4 - Create netcdf input files to run the SIM${no_color}"
source ${INCLUDE}/format.sh

# run simulations using sddp_solver
echo -e "\n${print_orange}Step 5 - run SIM using sddp_solver${no_color}"
source ${INCLUDE}/sim.sh
# alternative: run simulations using investment_solver
#echo -e "\n${print_orange}Step 5 - run SIM using investment_solver${no_color}"
#source scripts/include/simCEM.sh

# run post treatment script
echo -e "\n${print_orange}Step 6 - launch post treat${no_color}"
source ${INCLUDE}/postreat.sh
