#/bin/bash

echo "=================================================="
echo "=                                                ="
echo "=                    plan4res                    ="
echo "=                                                ="
echo "=================================================="


outputs="Demand Volume Flows ActivePower MaxPower Primary Secondary"
MarginalCosts="MarginalCostActivePowerDemand MarginalCostFlows MarginalCostInertia MarginalCostPrimary MarginalCostSecondary"

no_color='\033[0m' # No Color
print_red='\033[0;31m'
print_green='\033[0;32m'
print_orange='\033[0;33m'
print_blue='\033[0;34m'

export argumentsCREATE="invest simul"
export argumentsFORMAT="invest optim simul optimAfterInvest"
export argumentsPOSTREAT="invest simul"
export argumentsHOTSTART="hotstart"

# function to get the full path
no_symlinks='on'
function get_realpath() { # taken and adapted from bin/p4r,
    if [ ! -f "$1" ] && [ ! -d "$1" ]; then
        return 1 # failure : file or directory does not exist.
    fi
    [[ -n "$no_symlinks" ]] && local pwdp='pwd -P' || local pwdp='pwd' # do symlinks.
    echo "$( cd "$( echo "${1%/*}" )" 2>/dev/null; $pwdp )"/"${1##*/}" # echo result.
    return 0 # success
}

# function to display help
show_help() {
    echo "Usage: $0 runtype [dataset] [option1] [option2]"
    echo "Arguments:"
    echo "  runtype   Run type (CREATE, FORMAT, SSV, SIM, CEM, SSVandSIM, SSVandCEM, POSTTREAT)"
    echo "  dataset   Name of dataset"
	echo " 	The following arguments depend on the runtype: "
	echo "  	CREATE: simul or invest "
	echo "  		- simul : the dataset (csv files) will be created for a case study without investment optimisation "
	echo "  		          the csv files will be created in csv_simul using settingsCreate_simul.yml"
	echo "  		          i.e. the csv files will not include columns describing potential investment "
	echo "  		               nor technologies for which the capacity is 0 but it is possible to invest "
	echo "  		- invest : the dataset (csv files) will be created for a case study with investment optimisation "
	echo "  		          the csv files will be created in csv_invest using settingsCreate_invest.yml"
	echo "  		          i.e. the csv files will  include additionnal columns describing potential investment "
	echo "  		               and technologies for which the capacity is 0 but it is possible to invest: "
	echo "  		               the capacity of these technologies will be changed to a very low value;  "
	echo "  		               the size of the problem to be solved by SSV will be increased  "
	echo "  	FORMAT: optim, simul, invest or optimAfterInvest "
	echo "  		- optim : the nc4 files will be created in nc4_optim "
	echo "  		          this dataset is meant for running SSV "
	echo "			  FORMAT optim requires an additionnal option: simul or invest "
	echo "					- simul: use data in csv_simul, , settingsCreate_simul.yml and settings_format_optim.yml"
	echo "					- invest: use data in csv_invest, , settingsCreate_invest.yml and settings_format_optim.yml"
	echo "  		- simul : the dataset (nc4 files) will be created for a case study without investment optimisation "
	echo "  		          the nc4 files will be created in nc4_simul, using data in csv_simul, settingsCreate_simul.yml and settings_format_simul.yml "
	echo "  		          this dataset is meant for running SIM, and using results of an SSV ran with the simul option"
	echo "  		- invest : the dataset (nc4 files) will be created for a case study with investment optimisation "
	echo "  		          the nc4 files will be created in nc4_invest, using data in csv_invest, settingsCreate_invest.yml and settings_format_invest.yml "
	echo "  		          this dataset is meant for running CEM, and using results of an SSV ran with the option invest "
	echo "  		- optimAfterInvest : the dataset (nc4 files) will be created for a case study with investment optimisation "
	echo "  		          the nc4 files will be created in nc4_optim, using data in csv_invest, settingsCreate_invest.yml and settings_format_optimAfterInvest.yml "
	echo "  		          the csv files in csv_invest will be updated based on the results of CEM in results_invest "
	echo "  		          this dataset is meant for running SSV with the option invest, after a run of CEM "
	echo "  	SSV: simul or invest "
	echo "  		- simul : SSV will be ran for a case study without investment optimisation using nc4_optim"
	echo "  		          nc4 files in nc4_optim must have been created from csv_simul "
	echo "  		          the results of SSV will be in results_simul "
	echo "  		- invest : SSV will be ran for a case study with investment optimisation using nc4_optim"
	echo "  		          nc4 files in nc4_optim must have been created from csv_invest "
	echo "  		          the results of SSV will be in results_invest "
  	echo "           SSV may also use a second option: HOTSTART "
  	echo "                    in that case a first SSV run must have been performed; The current run will restart from the results of the previous run" 
	echo "  	SIM: no additionnal option "
	echo "  		          SIM will be ran for a case study without investment optimisation using nc4_simul and results of SSV without investment"
	echo "  		          the results of SIM will be in results_simul "
	echo "  	CEM: no additionnal option is mandatory "
  	echo "                CEM may also use a second option: HOTSTART "
	
	echo "  		          CEM will be ran using nc4_invest and results of SSV with investment "
	echo "  		          the results of CEM will be in results_invest "
	echo "  	POSTTREAT: simul or invest "
	echo "  		- simul : use results in results_simul"
	echo "  		- invest : use results in results_invest"
	echo "  	SSVandSIM: no additionnal option "
	echo "  		    runs the following workflow:	"
	echo "  		          - CREATE simul"
	echo "  		          - FORMAT optim simul"
	echo "  		          - SSV simul"
	echo "  		          - FORMAT simul"
	echo "  		          - SIM "
	echo "  		          - POSTTREAT simul "
	echo "  		    the results will be in results_simul "
	echo "  	SSVandCEM: no additionnal option "
	echo "  		    runs the following workflow:	"
	echo "  		          - CREATE invest"
	echo "  		          - FORMAT optim invest"
	echo "  		          - SSV invest"
	echo "  		          - FORMAT invest"
	echo "  		          - CEM "
	echo "  		          - POSTTREAT invest "
	echo "  		    the results will be in results_invest "	
    echo ""
    echo "Options:"
    echo "  -h, --help  Display this help and exit"
}

# Check help options
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help | more
    exit 0
fi

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 runtype [dataset] (optional)[option1] (optional)[option2]"
    echo "Usage: runtype is the tool you want to launch among"
    echo "   -CREATE [dataset] [option1]"
    echo "   -FORMAT [dataset] [option1] [option2]  (option2 only if option1 is optim)"
    echo "   -SSV [dataset] [option1]"
    echo "   -POSTTREAT [dataset] [option1]"
    echo "   -SIM [dataset] "
    echo "   -CEM [dataset] "
    echo "   -SSVandSIM [dataset] "
    echo "   -SSVandCEM [dataset] "
    exit 1
fi

# Store arguments in variables
runtype=$1
dataset=$2
DATASET=$dataset

echo "runtype: $runtype"
echo "dataset: $dataset"

if [ "$#" -gt 2 ]; then
    mode1=$3
	echo "option1: $mode1"
fi

if [ "$#" -gt 3 ]; then
    mode2=$4
	if [ "$#" -gt 4 ]; then
		echo "Beware, arguments after $4 won't be used"
	fi
	echo "option2: $mode2"
fi

HERE=$(pwd)
echo "Script called from : $HERE"
if [ -z "$P4R_DIR_LOCAL" ]; then
    isLocal="False"
else
    isLocal="True"
fi    

WHERE_IS_SCRIPT=$(dirname "$(readlink -f "$0")") # frome where script is called...
P4R_DIR=$(echo "$WHERE_IS_SCRIPT" | sed 's#/scripts/include##')

if [ -n "$P4R_DIR_LOCAL" ]; then
    LOCAL_P4R_DIR=$P4R_DIR_LOCAL
else
    LOCAL_P4R_DIR=$P4R_DIR
fi

echo "Main plan4res repo : $P4R_DIR"
echo "Local plan4res repo : $LOCAL_P4R_DIR"

export P4R_ENV="$P4R_DIR/bin/p4r"
export PYTHONSCRIPTS="${P4R_DIR}/scripts/python/plan4res-scripts"
export INCLUDE="$P4R_DIR/scripts/include"
export DATA="${LOCAL_P4R_DIR}/data/local"

echo "Path used:"
echo -e "\tP4R_ENV       = ${P4R_ENV}"
echo -e "\tINCLUDE       = ${INCLUDE}"
echo -e "\tPYTHONSCRIPTS = ${PYTHONSCRIPTS}"
echo -e "\tDATA          = ${DATA}"
export INSTANCE="${DATA}/${DATASET}"
export CONFIG="${DATA}/${DATASET}/settings"
echo -e "\tINSTANCE      = ${INSTANCE}"
echo -e "\tCONFIG        = ${CONFIG}"

vagrant_cwd_file=.vagrant/machines/default/virtualbox/vagrant_cwd
if [ -f ${vagrant_cwd_file} ]; then
    echo "Using a vagrant environment"
    vagrant_cwd=$(head -n 1 ${vagrant_cwd_file})
    vagrant_cwd=$(get_realpath $vagrant_cwd)
    p4r_vagrant_home="/vagrant"
    echo "Vagrant CWD is ${vagrant_cwd}"
    export PYTHONSCRIPTS_IN_P4R=$(echo "$PYTHONSCRIPTS" | sed "s|$vagrant_cwd|$p4r_vagrant_home|")
    export DATA_IN_P4R=$(echo "$DATA" | sed "s|$vagrant_cwd|$p4r_vagrant_home|")
    export INSTANCE_IN_P4R=$(echo "$INSTANCE" | sed "s|$vagrant_cwd|$p4r_vagrant_home|")
    export CONFIG_IN_P4R=$(echo "$CONFIG" | sed "s|$vagrant_cwd|$p4r_vagrant_home|")
    export INCLUDE_IN_P4R=$(echo "$INCLUDE" | sed "s|$vagrant_cwd|$p4r_vagrant_home|")
    echo "Path used in the Vagrant container:"
    echo -e "\tPYTHONSCRIPTS = ${PYTHONSCRIPTS_IN_P4R}"
    echo -e "\tDATA          = ${DATA_IN_P4R}"
    echo -e "\tINSTANCE      = ${INSTANCE_IN_P4R}"
    echo -e "\tCONFIG        = ${CONFIG_IN_P4R}"
else
    export PYTHONSCRIPTS_IN_P4R=${PYTHONSCRIPTS}
    export DATA_IN_P4R=${DATA}
    export INSTANCE_IN_P4R=${INSTANCE}
    export CONFIG_IN_P4R=${CONFIG}
    export INCLUDE_IN_P4R=${INCLUDE}
fi

function read_python_status {
	if [[ -f "$1" ]]; then	
		echo $(head -n 1 $1) 
	fi
}

function sddp_status {
    if [[ -f "${INSTANCE}results_${mode1}/BellmanValuesOUT.csv" ]]; then
        echo -e "${print_green}$(date +'%m/%d/%Y %H:%M:%S') - successfully ran SSV with SDDP solver (convergence OK).${no_color}"
    else
        if [[ -f "${INSTANCE}results_${mode1}cuts.txt" ]]; then
            echo -e "${print_orange}$(date +'%m/%d/%Y %H:%M:%S') - partially ran SSV with SDDP solver${no_color}${print_red} (no convergence).${no_color}"
        else
            echo -e "${print_red}$(date +'%m/%d/%Y %H:%M:%S') - error while running sddp_solver.${no_color}"
            exit 3
        fi
    fi
}

function invest_status {
    if [[ -f "${INSTANCE}/results_invest/Solution_OUT.csv" ]]; then
        echo -e "${print_green}$(date +'%m/%d/%Y %H:%M:%S') - successfully ran CEM with investment_solver.${no_color}"
    else
        echo -e "${print_red}$(date +'%m/%d/%Y %H:%M:%S') - error while running CEM with investment_solver.${no_color}"
        exit 4
    fi
}

start_time=$(date +'%m/%d/%Y %H:%M:%S')

rowsettings=$(awk -F ':' '$1=="    Scenarios"' ${CONFIG}/settings_format_optim.yml)
StrNbCommas=$(echo $rowsettings | grep -o ',' | wc -l)
let "NbCommas=$StrNbCommas"
NBSCEN_OPT=`expr $NbCommas + 1`
rowsettings=$(awk -F ':' '$1=="    Scenarios"' ${CONFIG}/settings_format_simul.yml)
StrNbCommas=$(echo $rowsettings | grep -o ',' | wc -l)
let "NbCommas=$StrNbCommas"
NBSCEN_SIM=`expr $NbCommas + 1`
rowsettings=$(awk -F ':' '$1=="    Scenarios"' ${CONFIG}/settings_format_invest.yml)
StrNbCommas=$(echo $rowsettings | grep -o ',' | wc -l)
let "NbCommas=$StrNbCommas"
NBSCEN_CEM=`expr $NbCommas + 1`
echo -e "${print_green}$(date +'%m/%d/%Y %H:%M:%S') - There are $NBSCEN_OPT scenarios for optimisation (bellman values computation) in this dataset ${no_color}"
echo -e "${print_green}$(date +'%m/%d/%Y %H:%M:%S') - There are $NBSCEN_SIM scenarios for simulation in this dataset ${no_color}"
echo -e "${print_green}$(date +'%m/%d/%Y %H:%M:%S') - There are $NBSCEN_CEM scenarios for investments optimisation in this dataset ${no_color}"


# function for launching script with good arguments
launch() {
    script=$1
    shift
	echo "script: $script"
    source ${INCLUDE}/"$script" "$@"
}

# Test runtype argument
case "$runtype" in
    CREATE|POSTTREAT)
        if [ "$#" -ge 4 ]; then
            echo "CREATE and POSTTREAT can only have 1 argument."
            exit 1
	elif [ "$#" -ge 3 ]; then
            if [ "$mode1" = "invest" ] || [ "$mode1" = "simul" ]; then
                launch "run${runtype}.sh" "$dataset" "$mode1"
            else
                echo "Error: option can only be 'invest' or 'simul'."
                exit 1
            fi
        else
            echo "Error: 2 arguments are necessary for $runtype."
            echo "usage $0 $runtype $dataset [mode1]."
            exit 1
        fi
        ;;
    SSV)
        if [ "$#" -ge 4 ]; then
	    if [ "$mode2" = "HOTSTART" ] ; then
		echo "run SSV with HOTSTART mode"
		launch "run${runtype}.sh" "$dataset" "$mode1" "$mode2"
	    else
		echo "Error: Second option can only be HOTSTART."
		exit 1
	    fi
	elif [ "$#" -ge 3 ]; then
            if [ "$mode1" = "invest" ] || [ "$mode1" = "simul" ]; then
                launch "run${runtype}.sh" "$dataset" "$mode1"
            else
                echo "Error: option can only be 'invest' or 'simul'."
                exit 1
            fi
        else
            echo "Error: 2 arguments are necessary for $runtype."
            echo "usage $0 $runtype $dataset [mode1]."
            exit 1
        fi
        ;;
    CEM)
	if [ "$mode1" = "HOTSTART" ] ; then
	    echo "run CEM with HOTSTART mode"
	    launch "run${runtype}.sh" "$dataset" "$mode1"
	else
	    launch "run${runtype}.sh" "$dataset"
	fi
	;;
    SIM|SSVandSIM|SSVandCEM|SIMCEM)
        launch "run${runtype}.sh" "$dataset"
        ;;
    FORMAT)
	echo "formatting"
        if [ "$mode1" = "optim" ]; then
	    echo "mode create optim"
            if [ "$mode2" = "simul" ] || [ "$mode2" = "invest" ]; then
		echo "launch runFORMAT.sh $dataset $mode1 $mode2"
                launch "runFORMAT.sh" "$dataset" "$mode1" "$mode2"
            else
                echo "Error: 4th argument must be 'simul' or 'invest'."
                exit 1
            fi
        elif [ "$mode1" = "simul" ] || [ "$mode1" = "invest" ] || [ "$mode1" = "optimAfterInvest" ]; then
	    if [ "$mode1" = "simul" ] || [ "$mode1" = "invest" ]; then
		mode2=$mode1
	    else
		mode2="invest"
		fi
		echo "launch runFORMAT $dataset $mode1 $mode2"			
            launch "runFORMAT.sh" "$dataset" "$mode1"
	else
            echo "Error: Third argument must be 'optim', 'simul', 'invest' or 'optimAfterInvest'"
            exit 1
        fi
        ;;
    *)
        echo "Error: First argument must be CREATE, FORMAT, SSV, SIM, CEM, POSTTREAT, SSVandSIM or SSVandCEM."
        exit 1
        ;;
esac

