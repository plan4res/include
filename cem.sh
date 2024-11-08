#/bin/bash

if [ ! -d "${INSTANCE}/results_invest" ]; then
	echo "results_invest dir does not exist; SSV has not ran successfully"
	exit 1
fi

# remove previous  results
for file in $outputs ; do
	if [ -d ${INSTANCE}/results_invest/$file ]; then
		rm -rf ${INSTANCE}/results_invest/${file}
	fi
done
if [ -d ${INSTANCE}/results_invest/MarginalCosts ]; then
	rm -rf ${INSTANCE}/results_invest/MarginalCosts
fi
if [ -f ${INSTANCE}/results_invest/Solution_OUT.csv ]; then
	rm ${INSTANCE}/results_invest/Solution_OUT.csv
fi

if [ -f ${INSTANCE}/results_invest/BellmanValuesOUT.csv ]; then
	echo "BellmanValuesOUT.csv found in results_invest/"
	cp ${INSTANCE}/results_invest/BellmanValuesOUT.csv ${INSTANCE}/results_invest/bellmanvalues.csv
elif [ -f ${INSTANCE}/results_invest/cuts.txt ]; then
	echo "cuts.txt found in results_invest/"
	cp ${INSTANCE}/results_invest/cuts.txt ${INSTANCE}/results_invest/bellmanvalues.csv
else
	echo "None of ${INSTANCE}/results_invest/BellmanValuesOUT.csv and ${INSTANCE}/results_invest/cuts.txt is present in results_invest/"
	echo "SSV has not ran successfully"
	exit 1
fi

# bellman values may have been computed for more ssv timestpeps than required => remove them
LASTSTEP=$(ls -l ${INSTANCE}/nc4_invest/Block*.nc4 | wc -l)
echo $LASTSTEP
awk -F, -v laststep="$LASTSTEP" 'NR==1 || $1 < laststep' "${INSTANCE}/results_invest/bellmanvalues.csv" > "${INSTANCE}/results_invest/temp.csv"

echo -e "${print_blue} - remove Bellman values after $LASTSTEP steps since they will not be used by the CEM${no_color}\n"
cp ${INSTANCE}/results_invest/temp.csv ${INSTANCE}/results_invest/bellmanvalues.csv
 
for file in $outputs ; do
	if [ ! -d ${INSTANCE}/results_invest/$file ]; then
       		mkdir ${INSTANCE}/results_invest/$file
	fi
done

if [ ! -d ${INSTANCE}/results_invest/MarginalCosts ]; then
	mkdir ${INSTANCE}/results_invest/MarginalCosts
fi

# run investment solver
if [[ "$@" == *"HOTSTART"* ]]; then
    # run in hotstart
    if [ -e "save_state0.nc4" ]; then
    	# select which save_state is the most recent
    	if [[ "${INSTANCE_IN_P4R}/results_invest/save_state0.nc4" -nt "${INSTANCE}/results_invest/save_state1.nc4" ]]; then
		saved="${INSTANCE_IN_P4R}/results_invest/save_state0.nc4"
    	else
		saved="${INSTANCE_IN_P4R}/results_invest/save_state1.nc4"
    	fi
    	echo -e "\n${print_orange} - run CEM using investment_solver:${no_color}${P4R_ENV} investment_solver -n ${SLURM_NTASKS} -d ${INSTANCE_IN_P4R}/results_invest/ -l ${INSTANCE_IN_P4R}/results_invest/bellmanvalues.csv -b ${saved} -a save_state -o -e -S ${CONFIG_IN_P4R}/BSPar-Investment.txt -c ${CONFIG_IN_P4R} -p ${INSTANCE_IN_P4R}/nc4_invest/ ${INSTANCE_IN_P4R}/nc4_invest/InvestmentBlock.nc4"
    	time ${P4R_ENV} investment_solver -n ${SLURM_NTASKS} -d ${INSTANCE_IN_P4R}/results_invest/ -l ${INSTANCE_IN_P4R}/results_invest/bellmanvalues.csv -b ${saved} -a save_state -o -e -S ${CONFIG_IN_P4R}/BSPar-Investment.txt -c ${CONFIG_IN_P4R}/ -p ${INSTANCE_IN_P4R}/nc4_invest/ ${INSTANCE_IN_P4R}/nc4_invest/InvestmentBlock.nc4
    else
        echo -e "\n${print_orange} - run CEM using investment_solver:${no_color}${P4R_ENV} investment_solver -n ${SLURM_NTASKS} -d ${INSTANCE_IN_P4R}/results_invest/ -l ${INSTANCE_IN_P4R}/results_invest/bellmanvalues.csv -a save_state -o -e -S ${CONFIG_IN_P4R}/BSPar-Investment.txt -c ${CONFIG_IN_P4R} -p ${INSTANCE_IN_P4R}/nc4_invest/ ${INSTANCE_IN_P4R}/nc4_invest/InvestmentBlock.nc4"
    	time ${P4R_ENV} investment_solver -n ${SLURM_NTASKS} -d ${INSTANCE_IN_P4R}/results_invest/ -l ${INSTANCE_IN_P4R}/results_invest/bellmanvalues.csv -a save_state -o -e -S ${CONFIG_IN_P4R}/BSPar-Investment.txt -c ${CONFIG_IN_P4R}/ -p ${INSTANCE_IN_P4R}/nc4_invest/ ${INSTANCE_IN_P4R}/nc4_invest/InvestmentBlock.nc4
    fi
else
     echo -e "\n${print_orange} - run CEM using investment_solver:${no_color}${P4R_ENV} investment_solver -n ${SLURM_NTASKS} -d ${INSTANCE_IN_P4R}/results_invest/ -l ${INSTANCE_IN_P4R}/results_invest/bellmanvalues.csv -o -e -S ${CONFIG_IN_P4R}/BSPar-Investment.txt -c ${CONFIG_IN_P4R} -p ${INSTANCE_IN_P4R}/nc4_invest/ ${INSTANCE_IN_P4R}/nc4_invest/InvestmentBlock.nc4"
     time ${P4R_ENV} investment_solver -n ${SLURM_NTASKS} -d ${INSTANCE_IN_P4R}/results_invest/ -l ${INSTANCE_IN_P4R}/results_invest/bellmanvalues.csv -o -e -S ${CONFIG_IN_P4R}/BSPar-Investment.txt -c ${CONFIG_IN_P4R}/ -p ${INSTANCE_IN_P4R}/nc4_invest/ ${INSTANCE_IN_P4R}/nc4_invest/InvestmentBlock.nc4
fi

for file in $outputs ; do
    mv ${INSTANCE}/results_invest/$file*.csv ${INSTANCE}/results_invest/$file/
done
mv ${INSTANCE}/results_invest/MarginalCost*.csv ${INSTANCE}/results_invest/MarginalCosts/

rm uc.lp
invest_status ./
