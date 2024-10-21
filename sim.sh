#/bin/bash

if [ ! -d "${INSTANCE}/results_simul" ]; then
	echo "results_simul dir does not exist; SSV has not ran successfully"
	exit 1
fi

# remove previous simulation results
for file in $outputs ; do
	if [ -d ${INSTANCE}/results_simul/$file ]; then
		rm -rf ${INSTANCE}/results_simul/${file}
	fi
done
if [ -d ${INSTANCE}/results_simul/MarginalCosts ]; then
	rm -rf ${INSTANCE}/results_simul/MarginalCosts
fi

if [ -f "${INSTANCE}/results_simul/BellmanValuesOUT.csv" ]; then
	echo "BellmanValuesOUT.csv found in results_simul/"
	cp ${INSTANCE}/results_simul/BellmanValuesOUT.csv ${INSTANCE}/results_simul/bellmanvalues.csv
elif [ -f "${INSTANCE}/results_simul/cuts.txt" ]; then
	echo "cuts.txt found in results_simul/"
	cp ${INSTANCE}/results_simul/cuts.txt ${INSTANCE}/results_simul/bellmanvalues.csv
else
	echo "None of BellmanValuesOUT.csv and cuts.txt is present in results_simul/"
	echo "SSV has not ran successfully"
	exit 1
fi

# bellman values may have been computed for more ssv timestpeps than required => remove them
LASTSTEP=$(ls -l ${INSTANCE}/nc4_simul/Block*.nc4 | wc -l)
awk -F, -v laststep="$LASTSTEP" 'NR==1 || $1 < laststep' "${INSTANCE}/results_simul/bellmanvalues.csv" > "${INSTANCE}/results_simul/temp.csv"
echo -e "${print_blue} - remove Bellman values after $LASTSTEP steps since they will not be used by the CEM${no_color}\n"
mv ${INSTANCE}/results_simul/temp.csv ${INSTANCE}/results_simul/bellmanvalues.csv

for file in $outputs ; do
	if [ ! -d ${INSTANCE}/results_simul/$file ]; then
       		mkdir ${INSTANCE}/results_simul/$file
	fi
done
if [ ! -d ${INSTANCE}/results_simul/MarginalCosts ]; then
	mkdir ${INSTANCE}/results_simul/MarginalCosts
fi

# run simulation
for (( scen=0; scen<$NBSCEN_SIM; scen++ ))
do
	echo -e "\n${print_blue} - run simulation for scenario $scen ${no_color}"
	${P4R_ENV} sddp_solver -d ${INSTANCE_IN_P4R}/results_simul/ -l ${INSTANCE_IN_P4R}/results_simul/bellmanvalues.csv -s -i ${scen} -S ${CONFIG_IN_P4R}/sddp_greedy.txt -c ${CONFIG_IN_P4R}/ -p ${INSTANCE_IN_P4R}/nc4_simul/ ${INSTANCE_IN_P4R}/nc4_simul/SDDPBlock.nc4
	for file in $outputs ; do
		mv ${INSTANCE}/results_simul/$file*.csv ${INSTANCE}/results_simul/$file/
	done
	mv ${INSTANCE}/results_simul/MarginalCost*.csv ${INSTANCE}/results_simul/MarginalCosts/
	rm uc.lp
done 
echo -e "\n${print_blue}- simulations completed ${no_color}"
