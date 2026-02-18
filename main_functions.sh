#/bin/bash


source ${INCLUDE}/sh_utils.sh

function read_settings() {

    main_config_file="${CONFIG}/plan4res_settings.yml"
    echo "read configuration file in $main_config_file"

    while IFS=: read -r var_name var_value; do
        # remove spaces
        var_name=$(echo "$var_name" | xargs)
        var_value=$(echo "$var_value" | xargs)
        # ignore comments, empty rows, and scenarios rows
		[[ -z "$var_name" ]] && continue
        [[ "$var_name" =~ ^#.*$ ]] && continue
        [[ "$var_name" =~ ^\[.*$ ]] && continue

        var_value=$(echo "$var_value" | cut -d'#' -f1 | xargs)
		eval "$var_name=\"$var_value\""
		# print to screen
		value=$(eval echo "$var_name")
		echo "found parameter $var_name with value ${!var_name}"

	done < <(grep -v '^#' "$main_config_file")
}


function read_options() {
# Reading options
	while [[ "$#" -gt 0 ]]; do
		case $1 in
        	-T|--timeseries) 				
				test_option $1 $2
				test=$?
				if [ $test -eq 0 ]; then timeseries="$2" ; shift; fi
				shift
				;;
			-M|--mode1) 				
				test_option $1 $2
				test=$?
				if [ $test -eq 0 ]; then mode1="$2" ; shift; fi
				shift
				;;
        	-m|--mode2) 
				test_option $1 $2
				test=$?
				if [ $test -eq 0 ]; then mode2="$2" ; shift; fi
				shift
				;;
			-B|--block) 				
				test_option $1 $2
				test=$?
				if [ $test -eq 0 ]; then block_id="$2" ; shift; fi
				shift
				;;
        	-o|--out) 				
				test_option $1 $2
				test=$?
				if [ $test -eq 0 ]; then 
					OUT="/$2"
					echo "results will be in ${INSTANCE}/results_$mode1${OUT}"
					shift
				else
					OUT=""
				fi
				shift
				;;
        	-H|--hotstart) 
				if [ "$2" = "save" ] ; then	
					echo "Run in hotstart mode, using saved states for CEM"
					HOTSTART="save"
					shift 2
				else
					echo "Run in hotstart mode"
					HOTSTART="HOTSTART"
					shift
				fi 
				;;
			-s|--sim)
				onesim=1
				test_option $1 $2
				test=$?
				if [ $test -eq 0 ]; then indexsim="$2" ; shift; fi
				echo "Run simulation for scenario $indexsim"
				shift
				;;
			-g|--group)
				test_option $1 $2
				test=$?
				if [ $test -eq 0 ]; then 
					sizegroupsim="$2" 
					groupsim=1
					echo "Run simulation per group of scenarios of size $sizegroupsim"
					shift					
				fi				
				shift
				;;
			-k|--numgroup)
				test_option $1 $2
				test=$?
				if [ $test -eq 0 ]; then 
					numgroupsim="$2" 
					onegroupsim=1
					echo "Run simulation for group of scenarios $numgroupsim"
					shift					
				fi				
				shift
				;;				
        	-C|--create) CREATE="CREATE"; echo "csv dataset will be created before running ${runtype}"; shift ;;
        	-G|--linkgenesys) LINKGENESYS="LINKGENESYS"; echo "IAMC files from GENeSYS-MOD native inputs/outputs will be created before running ${runtype}"; shift ;;
        	-F|--format) FORMAT="FORMAT"; echo "nc4 dataset will be created before running ${runtype}" ; shift ;;
        	-f|--formatgroups) FORMAT="FORMATGROUP"; echo "nc4 dataset for groups of scenarios will be created before running ${runtype}" ; shift ;;
        	-S|--steps) 
				echo "main_fu -S testfill NumberSSVIterationsFirstStep $1 $2"
				test_fill_option "NumberSSVIterationsFirstStep" "$1" "$2"
				test=$?
				if [ $test -eq 0 ]; then 
					STEPS=$NumberSSVIterationsFirstStep
				else 
					echo -e "${print_red} option -S requested but parameter NumberIterationsFirstStep not present in command nor ${CONFIG}/plan4res_settings.yml${no_color}"
					return 1
				fi	
				echo "main_fu -S testfill CheckConvEachXIterInFirstStep $1 $3"
				test_fill_option "CheckConvEachXIterInFirstStep" "$1" "$3"
				test=$?
				if [ $test -eq 0 ]; then 
					ITERCONV=$CheckConvEachXIterInFirstStep
				else 
					echo -e "${print_red} option -S requested but parameter CheckConvEachXIterInFirstStep not present in command nor ${CONFIG}/plan4res_settings.yml${no_color}"
					return 1      
				fi
				echo "main_fu -S testfill NumberSSVForwardFirstStep $1 $4"
				test_fill_option "NumberSSVForwardFirstStep" "$1" "$4"
				test=$?
				if [ $test -eq 0 ]; then 
					SSVFORWARD=$NumberSSVForwardFirstStep
				else 
					echo -e "${print_red} option -S requested but parameter NumberSSVForwardFirstStep not present in command nor ${CONFIG}/plan4res_settings.yml${no_color}"
					return 1
				fi
				if [[ "${runtype}" = "SSV" || "${runtype}" = "CEM" ]]; then
					echo "SSV will be ran in 2 steps"
				fi
				shift
				echo "SSV ran with params STEPS=${STEPS}, ITERCONV=${ITERCONV},  SSVFORWARD=${SSVFORWARD}"
				;;
        	-t|--nbthreads) 				
				test_option "number_threads" $2
				test=$?
				number_threads=$2
				if [ $test -eq 0 ]; then 
					if [[ "${runtype}" = "FORMAT" || "$FORMAT" = "FORMAT" ]]; then
						echo "nc4 will be created with ${number_threads} subblocks ="
					fi

					shift			
				fi
				shift
				;;
        	-L|--loopssv) 
				LOOPCEM="LOOPCEM"
				echo "main_fu -L testfill NumberOfCemIterationsInLoopCEM $1 $2"
				test_fill_option "NumberOfCemIterationsInLoopCEM" "$1" "$2"
				test=$?
				if [ $test -eq 0 ]; then 
					number_cem_iters=$NumberOfCemIterationsInLoopCEM
				else 
					echo -e "${print_red} option -L requested but parameter NumberOfCemIterationsInLoopCEM not present in command nor in ${CONFIG}/plan4res_settings.yml; STOP${no_color}"					
					return 1; 
				fi
				echo "main_fu -L testfill MaxNumberOfLoops $1 $3"
				test_fill_option "MaxNumberOfLoops" "$1" "$3"
				test=$?
				if [ $test -eq 0 ]; then  
					maxnumberloops=$MaxNumberOfLoops
				else
					echo -e "${print_red} option -L requested but parameter MaxNumberOfLoops not present in command nor ${CONFIG}/plan4res_settings.yml; STOP${no_color}"					
					return 1
				fi
				if [ "${runtype}" = "CEM" ]; then
					echo " CEM will be ran as a loop SSV/CEM, with ${number_cem_iters} (max) iterations in CEM and ${maxnumberloops} (max) loops"
				fi
				shift
				;;
        	-D|--distance) 
				test_fill_option "Distance" "$1" "$2"
				test=$?
				if [ $test -eq 0 ]; then 
					index_check_distance=$Distance
				else
					echo -e "${print_red} option -D requested but parameter Distance not present in command nor ${CONFIG}/plan4res_settings.yml; Distance 2 will be used${no_color}"				
				fi
				shift
				;;
        	-E|--epsilon) 
				test_fill_option "EpsilonCEM" "$1" "$2"
				test=$?				
				if [ $test -eq 0 ]; then 
					EPSILON=$EpsilonCEM
				else 
					echo -e "${print_red} option -E requested but parameter EpsilonCEM not present in command nor ${CONFIG}/plan4res_settings.yml${no_color}"					
					return 1
				fi
				shift
				;;
        	-U|--scenarios) 
				cem_config_file=$2
				test_fill_option "ScenariosLists" "$1" "$2"
				test=$?
				if [ $test -eq 0 ]; then 
					cem_config_file=$ScenariosLists 
					if [ "${runtype}" = "CEM" ]; then
						echo " CEM will be launched many times in sequence with different lists of scenarios and hotstart between each run "
					fi
				else 
					echo -e "${print_red} option -U requested but parameter ScenariosLists not present in command nor ${CONFIG}/plan4res_settings.yml; run will be without loop on scenarios lists${no_color}"					
				fi
				
				shift
				;;
			-P|--procs) 				
				test_option $1 $2
				test=$?
				if [ $test -eq 0 ]; then 
					NB_CPUS_PER_SIMUL="$2"
					if [ "$NB_CPUS_PER_SIMUL" -gt "$TOTAL_NB_CPUS" ] ; then
						echo -e "${print_orange} The requested number of CPUs per Simulation ($NB_CPUS_PER_SIMUL) is bigger than the total number of CPUs available ($TOTAL_NB_CPUS), using $TOTAL_NB_CPUS ${no_color}"
						NB_CPUS_PER_SIMUL=$TOTAL_NB_CPUS	
					fi
					NB_MAX_PARALLEL_SIMUL=$(( TOTAL_NB_CPUS / NB_CPUS_PER_SIMUL ))
					echo " CEM, SIM and SSV will use $NB_CPUS_PER_SIMUL for each simulation "
					shift			
				fi
				shift 
				;;
        	*) echo -e "${print_red}Unknown option: $1 ${no_color}"; return 1 ;;
    	esac
	done
}

function test_run_argument() {
	# Test runtype argument
	case "$runtype" in
    	CLEAN) clean;;
		CONFIG) read_settings;;
		CREATE)
			if [ "$mode1" = "" ]; then
				mode1="simul"
				echo -e "${print_orange} option -M not provided, chosing simul ${no_color}"
			fi
			if [[ "$mode1" != "simul" && "$mode1" != "invest" ]]; then
		    	echo -e "${print_red}Usage: $0 runtype [dataset] -M [option1] ${no_color}"
				echo -e "${print_red}[option1] must be simul or invest ${no_color}"
		    	return 1
			fi
			echo -e "\n${print_green}Launching plan4res dataset creation for $DATASET - [$start_time]${no_color}"
			source ${INCLUDE}/create.sh 
			create_status
			;;
		LINKGENESYS)
			echo -e "\n${print_green}Launching IAMC dataset creation for $DATASET - [$start_time]${no_color}"
			source ${INCLUDE}/runLINK_GENESYS.sh 
			linkgenesys_status
			;;
		POSTTREAT)
			if [ "$mode1" = "" ]; then
				mode1="simul"
				echo -e "${print_orange} option -M not provided, chosing simul ${no_color}"
			fi
			if [[ "$mode1" != "simul" && "$mode1" != "invest" ]]; then
		    	echo -e "${print_red}Usage: $0 runtype [dataset] -M [option1]${no_color}"
				echo -e "${print_red}[option1] must be simul or invest${no_color}"
		    	return 1
			fi
			echo -e "\n${print_green}Launching post-treatment for $DATASET - [$start_time]${no_color}"
			source ${INCLUDE}/postreat.sh
			;;
	    SSV)
			if [ "$mode1" = "" ]; then
				mode1="simul"
				mode2="simul"
				echo -e "${print_orange} option -M not provided, chosing simul ${no_color}"
			fi
			if [[ "$mode1" != "" && "$mode1" != "simul" && "$mode1" != "invest" && "$mode1" != "optim" ]]; then        	    		echo -e "${print_red}Usage: $0 runtype [dataset] -M [option1] optionnal: -o [Dir] -H -S${no_color}"
				echo -e "${print_red}[option1] must be simul or invest${no_color}"
		    	return 1			
			fi
			if [ "$LINKGENESYS" = "LINKGENESYS" ]; then
				echo -e "\n${print_green}Launching IAMC dataset creation for $DATASET - [$start_time]${no_color}"
				source ${INCLUDE}/runLINK_GENESYS.sh 
				if ! linkgenesys_status; then return 1; fi			
			fi
			if [ "$CREATE" = "CREATE" ]; then
				echo -e "\n${print_green}Launching plan4res dataset creation for $DATASET - [$start_time]${no_color}"
				source ${INCLUDE}/create.sh 
				if ! create_status; then return 1; fi			
			fi
			if [ "$FORMAT" = "FORMAT" ]; then
				if [ "$mode2" = "" ]; then
					mode2=$mode1
					echo -e "${print_orange} option -m not provided, chosing $mode1 ${no_color}"
				fi
				mode1="optim"
				echo -e "\n${print_green}Launching plan4res dataset formatting for $DATASET - [$start_time]${no_color}"
				source ${INCLUDE}/format.sh 
				if ! format_status; then return 1; fi	
			fi
			echo -e "\n${print_green}Launching computation of bellman values with SSV - [$start_time]${no_color}"
			source ${INCLUDE}/ssv.sh 
			sddp_status 
			;;
	    CEM)
			echo -e "\n${print_green}Launching computation of capacity expansion with CEM - [$start_time]${no_color}"
			if [ "$mode1" = "" ]; then mode1="invest" ; fi
			launch "run${runtype}.sh"
			investment_status
			mode1="invest"
			simulation_status
			;;
		SIMBLOCK)
			echo -e "\n${print_green}Launching simulation for 1 block- [$start_time]${no_color}"
			if [ "$mode1" = "" ]; then mode1="simul" ; fi
			source ${INCLUDE}/blocksolver.sh 
			;;
	    SIM)
			mode1="simul"
			mode2="simul"
			if [ "$FORMAT" = "FORMAT" ]; then
				echo -e "\n${print_green}Launching plan4res dataset formatting for $DATASET - [$start_time]${no_color}"
				source ${INCLUDE}/format.sh 
				if ! format_status; then return 1; fi	
			fi
			echo -e "\n${print_green}Launching simulation with SIM - [$start_time]${no_color}"
			source ${INCLUDE}/simCEM.sh
			wait
			simulation_status
			;;
		SIMsddp)
			mode1="simul"
			mode2="simul"
			if [ "$FORMAT" = "FORMAT" ]; then
				echo -e "\n${print_green}Launching plan4res dataset formatting for $DATASET - [$start_time]${no_color}"
				source ${INCLUDE}/format.sh 
				if ! format_status; then return 1; fi	
			fi
			echo -e "\n${print_green}Launching simulation with SIM - [$start_time]${no_color}"
			source ${INCLUDE}/sim.sh
			wait
			simulation_status
			;;
		SSVandSIM)
			mode1="simul"
			mode2="simul"
			echo -e "\n${print_green}Launching computation of bellman values with SSV and simulation with SIM - [$start_time]${no_color}"
			launch "run${runtype}.sh"
			;;
	    SSVandCEM)
			mode1="invest"
			mode2="invest"
			echo -e "\n${print_green}computation of bellman values with SSV and computation of capacity expansion with CEM - [$start_time]${no_color}"
			launch "run${runtype}.sh"
			;;
	    FORMAT)
			if [ "$mode1" = "" ]; then
				mode1="simul"
				mode2="simul"
				echo -e "${print_blue} option -M not provided, chosing simul ${no_color}"
			fi
			if [ "$mode1" = "optim" ]; then
				if [[ "$mode2" != "simul" && "$mode2" != "invest" ]]; then
					mode2="simul"
					echo -e "${print_blue} option -m not provided or not accepted, chosing simul ${no_color}"
				fi
			elif [[ "$mode1" = "simul" || "$mode1" = "invest" ]] ; then
				mode2=$mode1
				echo -e "${print_blue} option -m forced to $mode2 ${no_color}"
			elif [ "$mode1" = "postinvest" ]; then
				if [ "$mode2" != "invest" ]; then
					mode2="simul"
					echo -e "${print_blue} option -m forced to $mode2 ${no_color}"
				fi
			else
		    	echo -e "\n${print_red}option1 must be 'optim', 'simul', 'invest' or 'postinvest'${no_color}"
		    	return 1
			fi
			if [ "$LINKGENESYS" = "LINKGENESYS" ]; then
				echo -e "\n${print_green}Launching IAMC dataset creation for $DATASET - [$start_time]${no_color}"
				source ${INCLUDE}/runLINK_GENESYS.sh 
				if ! linkgenesys_status; then return 1; fi			
			fi
			if [ "$CREATE" = "CREATE" ]; then
				echo -e "\n${print_green}Launching plan4res dataset creation for $DATASET - [$start_time]${no_color}"
				if [[ "$mode1" != "simul" && "$mode1" = "invest" ]]; then
					oldmode1=$mode1
					mode1=$mode2
					source ${INCLUDE}/create.sh
					wait
					if ! create_status; then return 1; fi	
					mode1=$oldmode1
				else
				    source ${INCLUDE}/create.sh
				    wait
					if ! create_status; then return 1; fi
				fi
			fi
			echo -e "\n${print_green}Launching plan4res dataset formatting for $DATASET - [$start_time]${no_color}"		
			source ${INCLUDE}/format.sh
			wait
			if [ "$mode1" = "postinvest" ]; then mode1="optim" ; fi
			format_status
			;;
	    *)
			echo -e "\n${print_red}Error: First argument must be CLEAN, LINKGENESYS, CREATE, FORMAT, SSV, SIM, CEM, POSTTREAT, SSVandSIM or SSVandCEM.${no_color}"
			return 1
			;;
	esac 
}


# function to display help
function show_help() {
    echo "Usage: $0 runtype [dataset] -M [option1] -m [option2] -o [Dir] -C -F -G -H [save] "	
	echo "                            -L [NumberOfCemIterations] [MaxNumberOfLoops] -U [configfile]"
	echo "                            -S [NumberIterationsFirstStep] [CheckConvEachXIter] -E [epsilon] -D [distance] " 
	echo "                            -B [block] -s [indexscen] -g [sizegroup] -k [numgroup] -f "
	echo "					          -t [nbthreads] -P [nbcpus] "
    echo "Arguments:"
    echo "  runtype   Run type (CLEAN, CONFIG, LINKGENESYS, CREATE, FORMAT, SSV, SIM, SIMsddp, SIMBLOCK, CEM, SSVandSIM, SSVandCEM, POSTTREAT)"
    echo "  dataset   Name of dataset"
	echo "============="
	echo " 	runtypes: "
	echo "============="
	echo "  CLEAN: remove all results and revert to initial csv files if necessary (ie if cem -L was launched) "	
	echo "  CONFIG: read config file in settings/plan4res_settings.yml and print to screen "
	echo "  LINKGENESYS: creates a IAMC dataset from GENeSYS-MOD native inputs and outputs  "
	echo "  CREATE: creates a plan4res dataset (csv files) from a IAMC dataset  "
	echo "  FORMAT: creates netcdf files for SMS++ "
	echo "  SSV: runs the sddp_solver for computing bellman values"
	echo "  CEM: runs the capacity expansion followed by a simulation on the optimised mix, using investment_solver"
	echo "  SIM: run simulations using investment_solver in simulation mode"
	echo "  SIMsddp: run simulations using sddp_solver in simulation mode"
	echo "  SIMBLOCK: run simulation on one block (usually one week) using ucblock_solver"
	echo "  POSTTREAT: runs posttreatment of results "
	echo "  SSVandSIM:  runs SSV followed by SIM"
	echo "  SSVandCEM: runs SSV followed by CEM "
	echo "============="
	echo " 	options: "
	echo "============="
	echo " 	-M [option1] is used for the following runtypes: "
	echo "  	CREATE: option1 can be: simul or invest (default: simul)"
	echo "  	FORMAT: option1 can be: optim, simul, invest or postinvest (default: simul)"
	echo "  	SSV: option1 can be: simul or invest (default: simul)"
	echo "  	POSTTREAT: option1 can be: simul or invest (default: simul)"
	echo " 	-m [option2] is used only for FORMAT if option1=optim "
	echo "  	FORMAT: option1 can be: invest or simul (default: simul)"	
    echo "  -o [Dir] (or --out [Dir]) is optionnal ; Dir is the name of a subdir or dataset where results will be written"
	echo "       -o is usable for SSV, CEM, SIM, SSVandSIM, SSVandCEM, POSTTREAT"
    echo "  -T [Dir] (or --timeseries [Dir]) is optionnal ; Dir is the name of a subdir of data where Timeseries will be read"
	echo "       -T is usable for FORMAT" 
	echo "  -C or --create : in that case the dataset (csv files) will be created"
	echo "       -C is usable for FORMAT, SSV, SIM, CEM, SSVandCEM, SSVandSIM, CEMloopSSV"
  	echo "  -F or --format : in that case the netcdf dataset for sms++ (csv files) will be created"
	echo "       -F is usable for SSV, SIM, CEM (without option -L), (for SSVandCEM, SSVandSIM, CEM -L, creation of netcdf files is mandatory)"
  	echo "  -G or --linkgenesys : in that case the IAMC dataset (from genesys-mod native inputs/outputs) will be created"
	echo "       -G is usable for FORMAT, SSV, SIM, CEM, SSVandCEM, SSVandSIM, CEMloopSSV"
  	echo "  -H or --hotstart : in that case a first SSV run must have been performed; The current run will restart from the results of the previous run" 
	echo "       -H is usable for SSV, CEM"
	echo "       save is only used with CEM, meaning that not only the previous solution will be used but also the previous state"
   	echo "  -L or --loopssv : in that case CEM will be launched using a loop of ssv/cem until convergence" 
	echo "       -L is usable for CEM"
	echo "       NumberOfCemIterations is the max number of iterations in each run of CEM"
	echo "       MaxNumberOfLoops is the max number iterations ssv/cem"	
	echo "     Values of options to -L can be given in the launching command or is settings file plan4res_settings.yml"
  	echo "  -U or --scenarios : allows to launch cem in sequence on different lists of scenarios " 
	echo "       -U is usable for CEM"
	echo "       The lists of scenarios must be in config file nameconfigfile"  
	echo "     Values of options to -U can be given in the launching command or is settings file plan4res_settings.yml"
  	echo "  -S or --steps : in that case SSV will be ran in 2 steps (first step with convergence checks every 10 iterations, second with checks every iteration)" 
	echo "       -S is usable for SSV, CEM" 
	echo "       NumberIterationsFirstStep is the max number of iterations of the first step"
	echo "       CheckConvEachXIter: convergence is checked after CheckConvEachXIter SSV iterations"	
	echo "     Values of options to -S can be given in the launching command or is settings file plan4res_settings.yml"
  	echo "  -E or --epsilon : convergence criteria for CEM -L (default 0.01)" 
	echo "       -E is usable for CEM"
	echo "     Values of options to -E can be given in the launching command or is settings file plan4res_settings.yml"
  	echo "  -D or --distance : choose convergence test when using CEM with option -L" 
	echo "       -D is usable for CEM -L"
	echo "       distance is the kind of one of the convergence tests; it can be 2 or 3 (default: 2)"
	echo "			2: distance between initial capacity and invested capacity is used for checking convergence"
	echo "			3: distance between cost of investment solution at last 2 iterations is used for checking convergence"
	echo "     Values of options to -D can be given in the launching command or is settings file plan4res_settings.yml"
	echo "  -B [block] or --block [block] is mandatory with SIMBLOCK "
	echo "        block is the index of the block to be simulated"
	echo "  -s [indexscen] or --sim [indexscen] can only be used with SIM or SIMsddp"
	echo "		If -s is used, then only one scenario will be simulated: scenario indexscen"
	echo "  -g [sizegroup] or --group [sizegroup] can only be used with SIM or SIMsddp"
	echo "      If -g is used, simulations will be ran by groups of sizegroup scenarios, meaning that a dataset per group is created"
	echo "      If used on a parallel machine, the groups will be ran in parallel"
	echo "  -k [numgroup] or --numgroup [numgroup] can only be used with SIM or SIMsddp with option -g"
	echo "      If -g and -k are used then only the group number numgroup of sizegroup scenarios will be simulated"
	echo "  -t [nbthreads] or --nbthreads [nbthreads] can only be used for runs in parallel, only for SSV, CEM, SIM, SIMsddp"
	echo "	    It is used to define the number of OMP threads"
	echo "		Recommended values: for CEM, SIM, SIMsddp, nbthread can be the number of available cores on one node"
	echo "		Recommended values: for SSV, nbthread should usually be smaller depending on the available memory and number of timesteps (can be increased if more memory or less timesteps)"
	echo "  -P [procs] or --procs [procs] is used to parameterize the number of CPUs used per simulation"
	echo "      -P is currently not used "
	echo ""
    echo "  $0 -h or $0 --help : Display this help and exit"
}
