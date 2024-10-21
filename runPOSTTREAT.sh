#/bin/bash

# this script runs the posttreatment script on investment results
echo -e "\n${print_green}Launching post-treatment for $DATASET - [$start_time]${no_color}"

source ${INCLUDE}/postreat.sh
