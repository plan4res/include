#/bin/bash

# update sddp_solver configuration file to account for number of scenarios
echo -e "\n${print_blue} - Update sddp_solver configuration file to account for number of scenarios and location of results${no_color}"
newNbScen=$NBSCEN_OPT
rowconfig=$(grep "intNbSimulCheckForConv" ${CONFIG}/sddp_solver.txt)
intNbSimulCheckForConv=$(echo "$rowconfig" | cut -d ' ' -f 2-)
oldNbScen="$intNbSimulCheckForConv"								   
toreplace="$oldNbScen"
replacement="$newNbScen"
newrowconfig=${rowconfig/"$toreplace"/"$replacement"}
sed -i "s/$rowconfig/$newrowconfig/g" "${CONFIG}/sddp_solver.txt"

if grep -q "^strDirOUT" "${CONFIG}/sddp_solver.txt"; then
    sed -i "s|^strDirOUT.*|strDirOUT ${INSTANCE_IN_P4R}/results_${mode1}/|" "${CONFIG}/sddp_solver.txt"
else
    rowconfig=$(grep -n "number of string parameters$" "${CONFIG}/sddp_solver.txt" | cut -d: -f1)
    if [ -n "$rowconfig" ] ; then
	nbstringparam=$(sed -n "${rowconfig}p" "${CONFIG}/sddp_solver.txt" | awk '{print $1}')
	newnbstringparam=$((nbstringparam + 1))
	sed -i "${rowconfig}s/^$nbstringparam/$newnbstringparam/" "${CONFIG}/sddp_solver.txt"
    fi
    sed -i "/# now all the string parameters/a strDirOUT ${INSTANCE_IN_P4R}/results_${mode1}/" "${CONFIG}/sddp_solver.txt"
fi

echo -e "${print_blue} - successfully updated sddp_solver.txt configuration file to account for number of scenarios: $oldNbScen, replaced by $newNbScen.${no_color}"

# delete previous results
if [ -f ${INSTANCE}/results_${mode1}/BellmanValuesOUT.csv ]; then
	rm ${INSTANCE}/results_${mode1}/BellmanValuesOUT.csv
fi
if [ -f ${INSTANCE}/results_${mode1}/BellmanValuesAllOUT.csv ]; then
	rm ${INSTANCE}/results_${mode1}/BellmanValuesAllOUT.csv
fi
if [ -f ${INSTANCE}/results_${mode1}/cuts.txt ]; then
	rm ${INSTANCE}/results_${mode1}/cuts.txt
fi

# create repo if it does not exists
if [ ! -d ${INSTANCE}/results_${mode1} ]; then
	mkdir ${INSTANCE}/results_${mode1}
fi

# run sddp solver
if [[ "$@" == *"HOTSTART"* ]]; then
	# run in hotstart
	echo -e "\n${print_blue} - Run SSV with sddp_solver to compute Bellman values for storages: ${no_color}"
	
	echo -e "\n${P4R_ENV} sddp_solver -d ${INSTANCE_IN_P4R}/results_${mode1}/ -l ${INSTANCE_IN_P4R}/cuts.txt -S ${CONFIG_IN_P4R}/sddp_solver.txt -c ${CONFIG_IN_P4R}/ -p ${INSTANCE_IN_P4R}/nc4_optim/ ${INSTANCE_IN_P4R}/nc4_optim/SDDPBlock.nc4"
	
	${P4R_ENV} sddp_solver -d ${INSTANCE_IN_P4R}/results_${mode1}/ -l ${INSTANCE_IN_P4R}/results_${mode1}/cuts.txt -S ${CONFIG_IN_P4R}/sddp_solver.txt -c ${CONFIG_IN_P4R}/ -p ${INSTANCE_IN_P4R}/nc4_optim/ ${INSTANCE_IN_P4R}/nc4_optim/SDDPBlock.nc4
else
	echo -e "\n${print_blue} - Run SSV with sddp_solver to compute Bellman values for storages: ${no_color}"
	
	echo -e "\n${P4R_ENV} sddp_solver -d ${INSTANCE_IN_P4R}/results_${mode1}/ -S ${CONFIG_IN_P4R}/sddp_solver.txt -c ${CONFIG_IN_P4R}/ -p ${INSTANCE_IN_P4R}/nc4_optim/ ${INSTANCE_IN_P4R}/nc4_optim/SDDPBlock.nc4 "
	
	${P4R_ENV} sddp_solver -d ${INSTANCE_IN_P4R}/results_${mode1}/ -S ${CONFIG_IN_P4R}/sddp_solver.txt -c ${CONFIG_IN_P4R}/ -p ${INSTANCE_IN_P4R}/nc4_optim/ ${INSTANCE_IN_P4R}/nc4_optim/SDDPBlock.nc4
fi

rm uc.lp
sddp_status ./
