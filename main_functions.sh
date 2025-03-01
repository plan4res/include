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
        	-C|--create) CREATE="CREATE"; echo "csv dataset will be created before running ${runtype}"; shift ;;
        	-F|--format) FORMAT="FORMAT"; echo "nc4 dataset will be created before running ${runtype}" ; shift ;;
        	-S|--steps) 
				test_fill_option "NumberSSVIterationsFirstStep" "$1" "$2"
				test=$?
				if [ $test -eq 0 ]; then 
					STEPS=$NumberSSVIterationsFirstStep
				else 
					echo -e "${print_red} option -S requested but parameter NumberIterationsFirstStep not present in command nor ${CONFIG}/plan4res_settings.yml${no_color}"
					return 1
				fi	
				test_fill_option "CheckConvEachXIterInFirstStep" "$1" "$3"
				test=$?
				if [ $test -eq 0 ]; then 
					ITERCONV=$CheckConvEachXIterInFirstStep
				else 
					echo -e "${print_red} option -S requested but parameter CheckConvEachXIterInFirstStep not present in command nor ${CONFIG}/plan4res_settings.yml${no_color}"
					return 1
				fi
				if [[ "${runtype}" = "SSV" || "${runtype}" = "CEM" ]]; then
					echo "SSV will be ran in 2 steps"
				fi
				shift
				;;
        	-t|--nbthreads) 				
				test_option "number_threads" $2
				test=$?
				if [ $test -eq 0 ]; then 
					if [[ "${runtype}" = "FORMAT" || "$FORMAT" = "FORMAT" ]]; then
						echo "nc4 will be created with ${number_threads} subblocks ="
						number_threads=$2
					fi
					shift			
				fi
				shift
				;;
        	-L|--loopssv) 
				LOOPCEM="LOOPCEM"
				test_fill_option "NumberOfCemIterationsInLoopCEM" "$1" "$2"
				test=$?
				if [ $test -eq 0 ]; then 
					number_cem_iters=$NumberOfCemIterationsInLoopCEM
				else 
					echo -e "${print_red} option -L requested but parameter NumberOfCemIterationsInLoopCEM not present in command nor in ${CONFIG}/plan4res_settings.yml; STOP${no_color}"					
					return 1; 
				fi
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
			echo -e "\n${print_red}Error: First argument must be CLEAN, CREATE, FORMAT, SSV, SIM, CEM, POSTTREAT, SSVandSIM or SSVandCEM.${no_color}"
			return 1
			;;
	esac 
}


# function to display help
function show_help() {
    echo "Usage: $0 runtype [dataset] -M [option1] -m [option2] -o [Dir] -H [save] -S [NumberIterationsFirstStep] [CheckConvEachXIter] -E [epsilon] -L [NumberOfCemIterations] [MaxNumberOfLoops] -D [distance] -U [configfile]"
    echo "Arguments:"
    echo "  runtype   Run type (CLEAN, CREATE, FORMAT, SSV, SIM, CEM, SSVandSIM, SSVandCEM, POSTTREAT)"
    echo "  dataset   Name of dataset"
    echo "  -o [Dir] (or --out [Dir]) is optionnal ; Dir is the name of a subdir or dataset where results will be written"
	echo "       -o is usable for SSV, CEM, SIM, SSVandSIM, SSVandCEM, POSTTREAT"
  	echo "  -C or --create is optionnal : in that case the dataset (csv files) will be created"
	echo "       -C is usable for FORMAT, SSV, SIM, CEM, SSVandCEM, SSVandSIM, CEMloopSSV"
  	echo "  -F or --format is optionnal : in that case the netcdf dataset for sms++ (csv files) will be created"
	echo "       -F is usable for SSV, SIM, CEM (without option -L), (for SSVandCEM, SSVandSIM, CEM -L, creation of netcdf files is mandatory)"
  	echo "  -H or --hotstart is optionnal : in that case a first SSV run must have been performed; The current run will restart from the results of the previous run" 
	echo "       -H is usable for SSV, CEM"
	echo "       save is only used with CEM, meaning that not only the previous solution will be used but also the previous state"
  	echo "  -S or --steps is optionnal : in that case SSV will be ran in 2 steps (first step with convergence checks every 10 iterations, second with checks every iteration)" 
	echo "       -S is usable for SSV, CEM" 
	echo "       NumberIterationsFirstStep is the max number of iterations of the first step"
	echo "       CheckConvEachXIter: convergence is checked after CheckConvEachXIter SSV iterations"	
	echo "     Values of options to -S can be given in the launching command or is settings file plan4res_settings.yml"
  	echo "  -L or --loopssv : in that case CEM will be launched using a loop of ssv/cem until convergence" 
	echo "       -L is usable for CEM"
	echo "       NumberOfCemIterations is the max number of iterations in each run of CEM"
	echo "       MaxNumberOfLoops is the max number iterations ssv/cem"	
	echo "     Values of options to -L can be given in the launching command or is settings file plan4res_settings.yml"
  	echo "  -E or --epsilon : optionnal convergence criteria for CEM -L (default 0.01)" 
	echo "       -E is usable for CEM"
	echo "     Values of options to -E can be given in the launching command or is settings file plan4res_settings.yml"
  	echo "  -D or --distance : choose convergence test when using CEM with option -L" 
	echo "       -D is usable for CEM -L"
	echo "       distance is the kind of one of the convergence tests"  
	echo "     Values of options to -D can be given in the launching command or is settings file plan4res_settings.yml"
  	echo "  -U or --scenarios: allows to launch cem in sequence on different lists of scenarios " 
	echo "       -U is usable for CEM"
	echo "       The lists of scenarios must be in config file nameconfigfile"  
	echo "     Values of options to -U can be given in the launching command or is settings file plan4res_settings.yml"
	echo " 	option1 is used for the following runtypes: "
	echo "  	CREATE: simul or invest "
	echo "  	FORMAT: optim, simul, invest or postinvest "
	echo "  	SSV: simul or invest "
	echo "  	POSTTREAT: simul or invest "
	echo " 	option2 is used only for FORMAT if option1=optim "
	echo "  	FORMAT: invest or simul "	
	echo "  distance is used onfly for CEMloopSSV "
	echo "      distance can be 2,3 (default: 2)"
	echo "			2: distance between initial capacity and invested capacity is used for checking convergence"
	echo "			3: distance between cost of investment solution at last 2 iterations is used for checking convergence"
	echo "============="
	echo " 	runtypes: "
	echo "============="
	echo "  CLEAN: remove all results and revert to initial csv files if necessary (ie if cem -L was launched) "	
	echo "  CONFIG: read config file in settings/plan4res_settings.yml and print to screen "
	echo "  CREATE: creates a plan4res dataset (csv files) from a IAMC dataset  "
	echo "  	-M [simul]: the csv files will be created in csv_simul/ using settingsCreate_simul.yml"
	echo "  		i.e. the csv files will not include columns describing potential investment "
	echo "  		nor technologies for which the capacity is 0 but it is possible to invest "
	echo "  	-M [invest]: the csv files will be created in csv_invest/ using settingsCreate_invest.yml"
	echo "  		i.e. the csv files will  include additionnal columns and rows describing potential investment "
	echo "  	if -M is not provided, default option is simul "
	echo "  FORMAT: creates netcdf files for SMS++ "
	echo " 		-M [optim] -m [option2]: netcdf files will be created for computation of bellman values (for running SSV) "
	echo "  		the nc4 files will be created in nc4_optim, using settings_format_optim.yml"
	echo "			  if option2=simul: using data in csv_simul, and settingsCreate_simul.yml"
	echo "			  without option2: using data in csv_simul, and settingsCreate_simul.yml"
	echo "			  if option2=invest: using data in csv_invest, and settingsCreate_invest.yml"
	echo "  		this dataset is meant for running SSV "
	echo " 		-M [simul]: netcdf files will be created for a simulation case study (without investment optimisation) "
	echo "  		the nc4 files will be created in nc4_simul, using data in csv_simul, settingsCreate_simul.yml and settings_format_simul.yml "
	echo "  		this dataset is meant for running SIM, and using results of an SSV ran with the simul option"
	echo "  	-M [invest] : the dataset (nc4 files) will be created for a case study with investment optimisation "
	echo "  		the nc4 files will be created in nc4_invest, using data in csv_invest, settingsCreate_invest.yml and settings_format_invest.yml "
	echo "  		this dataset is meant for running CEM, and using results of an SSV ran with the option invest "
	echo "  	-M [postinvest] : the dataset (nc4 files) will be created for a case study with investment optimisation "
	echo "  		the nc4 files will be created in nc4_optim, using data in csv_invest, settingsCreate_invest.yml and settings_format_postinvest.yml "
	echo "			  if option2=simul: using data in csv_simul, and settingsCreate_simul.yml"
	echo "  		       the csv files in csv_simul AND csv_invest will be updated based on the results of CEM in results_invest "
	echo "  		       and saved in csv_simul AND csv_invest at each iteration of CEM -L "
	echo "			  if option2=invest: using data in csv_invest, and settingsCreate_invest.yml"
	echo "  		       and the csv files in csv_invest will be updated based on the results of CEM in results_invest "
	echo "  		  in both cases The invested capacity will be computed (updated if CEM -L) in files *invested.csv in results_invest "
	echo "  		this dataset is meant for running SSV, after a run of CEM ; it is also used in CEM -L"
	echo "  	if -M is not provided, default option is simul "
	echo "  SSV: runs the sddp_solver for computing bellman values"
	echo " 		-M [option]: SSV will be ran from nc4 files in nc4_optim"
	echo "  		the results of SSV will be in results_$option "
	echo "  		option can be: invest, simul, optim "
	echo "      if -M is not provided, default option is optim"
	echo "  SIM: run simulations "
	echo "  		the results of SIM will be in results_simul "
	echo "  		SIM will use BellmanValues in results_simul "
	echo "  CEM: runs investment optimisation and simulation"
	echo "  		the results of CEM will be in results_invest "
	echo "  		without option -L, CEM will use BellmanValues in results_invest "
	echo "  		with option -L, BellmanValues will be computed at each iteration "
	echo "  POSTTREAT: runs posttreatment of results "
	echo " 		-M [simul]: use results in results_simul"
	echo "   	-M [invest] : use results in results_invest"
	echo "      if -M is not provided, default option is optim"
	echo "  SSVandSIM:  "
	echo "  		- CREATE -M simul"
	echo "  		- FORMAT -M optim -m simul"
	echo "  		- SSV -M simul"
	echo "  		- FORMAT -M simul"
	echo "  		- SIM "
	echo "  		- POSTTREAT -M simul "
	echo " 		the results will be in results_simul "
	echo "  SSVandCEM: runs the following workflow: "
	echo "  		- CREATE -M invest"
	echo "  		- FORMAT -M optim -m invest"
	echo "  		- SSV -M invest"
	echo "  		- FORMAT -M invest"
	echo "  		- CEM "
	echo "  		- POSTTREAT -M invest "
	echo " 	    the results will be in results_invest "	
    echo ""
    echo "Options:"
    echo "  -h, --help  Display this help and exit"
}
