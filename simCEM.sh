#/bin/bash

if [ ! -d "${INSTANCE}/results_simul" ]; then
	echo "results_simul dir does not exist; SSV has not ran successfully"
	exit 1
fi

# remove previous simulation results
for file in $outputs ; do
	if [ -d ${INSTANCE}/results_simul/$file ]; then
		echo "delete dir ${INSTANCE}/results_simul/${file}"
		rm -rf ${INSTANCE}/results_simul/${file}
	fi
done
if [ -d ${INSTANCE}/results_simul/MarginalCosts ]; then
	echo "delete dir ${INSTANCE}/results_simul/MarginalCosts"
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

# run investment solver
#time ${P4R_ENV} investment_solver -d ${INSTANCE_IN_P4R}/results_simul/ -s -l ${INSTANCE_IN_P4R}/results_simul/bellmanvalues.csv -o -S ${CONFIG_IN_P4R}BSPar-Investment.txt -c ${CONFIG_IN_P4R} -p ${INSTANCE_IN_P4R}/nc4_simul/ ${INSTANCE_IN_P4R}/nc4_simul/InvestmentBlock.nc4
time ${P4R_ENV} investment_solver -d ${INSTANCE_IN_P4R}/results_simul/ -s -l ${INSTANCE_IN_P4R}/results_simul/bellmanvalues.csv -o -S ${CONFIG_IN_P4R}BSPar-Investment.txt -c ${CONFIG_IN_P4R} -p ${INSTANCE_IN_P4R}/nc4_simul/ ${INSTANCE_IN_P4R}/nc4_simul/InvestmentBlock.nc4

for file in $outputs ; do
    mv ${INSTANCE}/results_simul/$file*.csv ${INSTANCE}/results_simul/$file/
done
mv ${INSTANCE}/results_simul/MarginalCost*.csv ${INSTANCE}/results_simul/MarginalCosts/
rm uc.lp
