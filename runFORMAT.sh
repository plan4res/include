#/bin/bash

echo -e "\n${print_green}Launching plan4res dataset formatting for $DATASET - [$start_time]${no_color}"

# run formatting script to create netcdf input files
source ${INCLUDE}/format.sh
