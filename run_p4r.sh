#/bin/bash

echo "=================================================="
echo "=                                                ="
echo "=                    plan4res                    ="
echo "=                                                ="
echo "=================================================="

echo "plan4res launched with arguments : $@"

# if script launched without SLURM, fill SLURM variables with 1
if [[ ! -n "$SLURM_JOB_ID" ]]; then
  SLURM_JOB_NUM_NODES=1
  SLURM_JOB_CPUS_PER_NODE=$(nproc)
fi
echo "Number Nodes: $SLURM_JOB_NUM_NODES"
echo "Number CPUs per node: $SLURM_JOB_CPUS_PER_NODE"

CPUS_PER_NODE_STR=$SLURM_JOB_CPUS_PER_NODE
CPUS_PER_NODE=$(echo $CPUS_PER_NODE_STR | grep -oP '^\d+')
TOTAL_NB_CPUS=$((CPUS_PER_NODE * SLURM_JOB_NUM_NODES))
echo "Total Number CPUs : $TOTAL_NB_CPUS"

NB_MAX_PARALLEL_SIMUL=$CPUS_PER_NODE
echo "The total number of CPUs available is $TOTAL_NB_CPUS"

WHERE_IS_SCRIPT=$1
shift
if [[ ! -n "$P4R_DIR" ]]; then
    P4R_DIR=$WHERE_IS_SCRIPT
fi
    
if [ -n "$P4R_DIR_LOCAL" ]; then
    LOCAL_P4R_DIR=$P4R_DIR_LOCAL
else
    LOCAL_P4R_DIR=$P4R_DIR
fi

echo "Main plan4res repo : $P4R_DIR"
echo "Local plan4res repo : $LOCAL_P4R_DIR"

P4R_ENV="$P4R_DIR/bin/p4r"
PYTHONSCRIPTS="${P4R_DIR}/scripts/python/plan4res-scripts"
ADDONS="${P4R_DIR}/scripts/add-ons/install"
GENESYS="${P4R_DIR}/scripts/add-ons/GENeSYS_MOD.jl"
INCLUDE="$P4R_DIR/scripts/include"
DATA="${LOCAL_P4R_DIR}/data"

inputs="TU_ThermalUnits IN_Interconnections RES_RenewableUnits STS_ShortTermStorage"
outputs="Demand Volume Flows ActivePower MaxPower Primary Secondary"
MarginalCosts="MarginalCostActivePowerDemand MarginalCostFlows MarginalCostInertia MarginalCostPrimary MarginalCostSecondary"

no_color='\033[0m' 
print_red='\033[0;31m'
print_green='\033[0;32m'
print_orange='\033[0;33m'
print_blue='\033[0;34m'

source ${INCLUDE}/sh_utils.sh
source ${INCLUDE}/main_functions.sh

# function to get the full path
no_symlinks='on'
function get_realpath() { # taken and adapted from bin/p4r,
    if [[ ! -f "$1" ]] && [[ ! -d "$1" ]]; then
        return 1 # failure : file or directory does not exist.
    fi
    [[ -n "$no_symlinks" ]] && local pwdp='pwd -P' || local pwdp='pwd' # do symlinks.
    echo "$( cd "$( echo "${1%/*}" )" 2>/dev/null; $pwdp )"/"${1##*/}" # echo result.
    return 0 # success
}

# Check help options
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help | more
    return 0
fi

if [ "$#" -lt 2 ]; then
    echo "Usage: p4r [runtype] [dataset name] [options]"    
    echo "Usage: sp4r -n [number nodes requested] [runtype] [dataset name] [options]"
    echo "runtype is the tool you want to launch among"
    echo "   -CREATE "    
    echo "   -CONFIG "
    echo "   -FORMAT "
    echo "   -SSV "
    echo "   -POSTTREAT"
    echo "   -SIM "
    echo "   -CEM "
    echo "   -SSVandSIM "
    echo "   -SSVandCEM "
    echo "   -CLEAN "
    echo " -h or --help to get detailed help "
    return 1
fi

mode1=""
mode2=""
OUT=""
number_threads=1
runtype=$1
dataset=$2
DATASET=$dataset
HOTSTART=""
STEPS=0
ITERCONV=0
CREATE=""
FORMAT=""
number_cem_iters=1
index_check_distance=2
cem_config_file=""
LOOPCEM=""
maxnumberloops=10
block_id=0
indexsim=0
sizegroupsim=1
onesim=0
groupsim=0
numgroupsim=0 
onegroupsim=0

shift 2

echo -e "runtype: ${runtype}"
echo -e "dataset: ${dataset}"
echo -e "Dataset and results location: $DATA/$DATASET"
echo "Path used:"
echo -e "\tP4R_ENV       = ${P4R_ENV}"
echo -e "\tINCLUDE       = ${INCLUDE}"
echo -e "\tPYTHONSCRIPTS = ${PYTHONSCRIPTS}"
echo -e "\tDATA          = ${DATA}"
INSTANCE="${DATA}/${DATASET}"
CONFIG="${DATA}/${DATASET}/settings"
echo -e "Configuration files in: ${CONFIG}"
read_settings
read_options $@
result=$?
if [ $result -eq 1 ]; then
	echo -e "${print_red}exiting script, bad options${no_color}"
	return 1
fi

echo "The maximum number of simulations in parallel is $NB_MAX_PARALLEL_SIMUL"

vagrant_cwd_file=.vagrant/machines/default/virtualbox/vagrant_cwd
if [ -f ${vagrant_cwd_file} ]; then
    echo "Using a vagrant environment"
    vagrant_cwd=$(head -n 1 ${vagrant_cwd_file})
    vagrant_cwd=$(get_realpath $vagrant_cwd)
    p4r_vagrant_home="/vagrant"
    echo "Vagrant CWD is ${vagrant_cwd}"
    PYTHONSCRIPTS_IN_P4R=$(echo "$PYTHONSCRIPTS" | sed "s|$vagrant_cwd|$p4r_vagrant_home|")
    DATA_IN_P4R=$(echo "$DATA" | sed "s|$vagrant_cwd|$p4r_vagrant_home|")
    INSTANCE_IN_P4R=$(echo "$INSTANCE" | sed "s|$vagrant_cwd|$p4r_vagrant_home|")
    CONFIG_IN_P4R=$(echo "$CONFIG" | sed "s|$vagrant_cwd|$p4r_vagrant_home|")
    INCLUDE_IN_P4R=$(echo "$INCLUDE" | sed "s|$vagrant_cwd|$p4r_vagrant_home|")
    echo "Path used in the Vagrant container:"
    echo -e "\tPYTHONSCRIPTS = ${PYTHONSCRIPTS_IN_P4R}"
    echo -e "\tDATA          = ${DATA_IN_P4R}"
    echo -e "\tINSTANCE      = ${INSTANCE_IN_P4R}"
    echo -e "\tCONFIG        = ${CONFIG_IN_P4R}"
else
    PYTHONSCRIPTS_IN_P4R=${PYTHONSCRIPTS}
    DATA_IN_P4R=${DATA}
    INSTANCE_IN_P4R=${INSTANCE}
    CONFIG_IN_P4R=${CONFIG}
    INCLUDE_IN_P4R=${INCLUDE}
	GENESYS_IN_P4R=${GENESYS}
    ADDONS_IN_P4R=${ADDONS}
fi

start_time=$(date +'%m/%d/%Y %H:%M:%S')

rowsettings=$(awk -F ':' '$1=="    Scenarios"' ${CONFIG}/settings_format_optim.yml)
StrNbCommas=$(grep -o "," <<< "$rowsettings" | wc -l)
let "NbCommas=$StrNbCommas"
NBSCEN_OPT=`expr $NbCommas + 1`
rowsettings=$(awk -F ':' '$1=="    Scenarios"' ${CONFIG}/settings_format_simul.yml)
StrNbCommas=$(grep -o "," <<< "$rowsettings" | wc -l)
let "NbCommas=$StrNbCommas"
NBSCEN_SIM=`expr $NbCommas + 1`
rowsettings=$(awk -F ':' '$1=="    Scenarios"' ${CONFIG}/settings_format_invest.yml)
StrNbCommas=$(grep -o "," <<< "$rowsettings" | wc -l)
let "NbCommas=$StrNbCommas"
NBSCEN_CEM=`expr $NbCommas + 1`
echo -e "There are $NBSCEN_OPT scenarios for optimisation (bellman values computation) in this dataset"
echo -e "There are $NBSCEN_SIM scenarios for simulation in this dataset"
echo -e "There are $NBSCEN_CEM scenarios for investments optimisation in this dataset"

# function for launching script with good arguments
function launch() {
    script=$1
    shift
    source ${INCLUDE}/"$script" "$@"
}

if [ "$dataset" = "" ]; then
	echo -e "${print_red}Usage: $0 runtype [dataset] [options] ${no_color}"
	echo -e "${print_red}[dataset] missing ${no_color}"
	return 1
fi
 
test_run_argument
