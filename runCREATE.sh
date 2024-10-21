#/bin/bash

echo -e "\n${print_green}Launching plan4res dataset creation for $DATASET - [$start_time]${no_color}"

# run script to create plan4res input dataset (ZV_ZineValues.csv ...)
source ${INCLUDE}/create.sh 
