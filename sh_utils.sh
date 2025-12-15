#/bin/bash

main_config_file="$P4R_DIR_LOCAL/data/${DATASET}/settings/plan4res_settings.yml"
function check_results_dir() {
	local repo=$1
	echo -e "${print_blue}        - check if repo ${INSTANCE}/results_${repo}${OUT} exists${no_color}\n"
	if [[ ! -d "${INSTANCE}/results_${repo}${OUT}" ]]; then
		echo -e "${print_red}            - results_${repo}${OUT} dir does not exist ${no_color}\n"
		return 1
	else
		return 0
	fi
}

function create_format_settings_group() {

	local settings="$1"
    local settings_group="$2"
    local G="$3"
    local I="$4"
    local N="$5"

	echo -e "${print_blue}        - replace Scenarios list in $settings, creating $settings_group, with $N scenarios from scen $I ${no_color}\n"
    awk -v I="$I" -v N="$N" '
    /^[[:space:]]*Scenarios:[[:space:]]*\[/ {

        # Supprimer tout avant le [
        line = $0
        sub(/^.*\[/, "", line)
        sub(/\].*$/, "", line)

        # Découper la liste par virgules
        n = split(line, vals, ",")

        start = I + 1          # awk commence à 1
        end = start + N - 1

        printf "    Scenarios: ["
        first = 1

        for (i = start; i <= end && i <= n; i++) {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", vals[i])

            if (!first) printf ","
            printf "%s", vals[i]
            first = 0
        }

        printf "]\n"
        next
    }

    { print }

    ' "$settings" > "$settings_group"
	
	sed -i "s|outputDir: 'nc4_simul/'|outputDir: 'nc4_simul_${G}/'|g" "$settings_group"
}

move_simul_results_group() {
	grp="$1"
	current_first_scen="$2"
	size_group="$3"
	SRC_DIR="${INSTANCE_IN_P4R}/results_simul${OUT}_${grp}"
	DEST_DIR="${INSTANCE_IN_P4R}/results_simul${OUT}"

	for ((i=0; i<$size_group; i++)); do
		j=$((current_first_scen + i))
		for file in "$SRC_DIR"/*_Scen${i}_OUT.csv; do
			# Vérifier que le fichier existe
			[ -e "$file" ] || continue

			base=$(basename "$file")
			
			# Remplacer _Scen<i>_ par _Scen<j>_
			newname=$(echo "$base" | sed "s/_Scen${i}_/_Scen${j}_/")
			mv "$file" "$DEST_DIR/$newname"
		done
	done
}
function move_simul_results() {
	echo -e "${print_blue}        - move results of simulation to ${INSTANCE}/results_$1${OUT}  ${no_color}\n"
	for file in $outputs ; do
		mv ${INSTANCE}/results_$1${OUT}/$file*.csv ${INSTANCE}/results_$1${OUT}/$file/
	done
	mv ${INSTANCE}/results_$1${OUT}/MarginalCost*.csv ${INSTANCE}/results_$1${OUT}/MarginalCosts/
}

function remove_previous_ssv_results() {
	echo -e "${print_blue}        - if existing, remove previous ssv results in ${INSTANCE}/results_$1${OUT} ${no_color}\n"

	if [ -f "${INSTANCE}/results_$1${OUT}/BellmanValuesOUT.csv" ]; then
		rm ${INSTANCE}/results_$1${OUT}/BellmanValuesOUT.csv
	fi
	if [ -f "${INSTANCE}/results_$1${OUT}/BellmanValuesAllOUT.csv" ]; then
		rm ${INSTANCE}/results_$1${OUT}/BellmanValuesAllOUT.csv
	fi
	if [ -f "${INSTANCE}/results_$1${OUT}/cuts.txt" ]; then
		rm ${INSTANCE}/results_$1${OUT}/cuts*.txt
	fi
	if [ -f "${INSTANCE}/results_$1${OUT}/visited_states.sddp.gsbmf" ]; then
		rm ${INSTANCE}/results_$1${OUT}/visited*
	fi
	if [ -f "${INSTANCE}/results_$1${OUT}/regressors.sddp.gsbmf" ]; then
		rm ${INSTANCE}/results_$1${OUT}/regressors*
	fi
}

function remove_previous_simulation_results() {
	# remove previous simulation results
	echo -e "${print_blue}        - if existing, remove previous simulation results in ${INSTANCE}/results_$1${OUT} ${no_color}\n"
	for file in $outputs ; do
	    if [ -d "${INSTANCE}/results_$1${OUT}/$file" ]; then
		    rm -rf ${INSTANCE}/results_$1${OUT}/${file}
		fi
	done
	if [ -d "${INSTANCE}/results_$1${OUT}/MarginalCosts" ]; then
	    rm -rf ${INSTANCE}/results_$1${OUT}/MarginalCosts
	fi
}

function remove_previous_investment_results() {
	echo -e "${print_blue}        - if existing, remove previous investment results in ${INSTANCE}/results_invest${OUT} ${no_color}\n"
	if [ -f "${INSTANCE}/results_invest${OUT}/Solution_OUT.csv" ]; then
		echo -e "${print_blue}            - delete file ${INSTANCE}/results_invest${OUT}/Solution_OUT.csv ${no_color}\n"
		rm ${INSTANCE}/results_invest${OUT}/Solution_OUT*.csv
	fi
	if [ -f "${INSTANCE}/results_invest${OUT}/investment_candidates.txt" ]; then
		rm ${INSTANCE}/results_invest${OUT}/investment_candidates.txt
	fi
	if [ "$CEMLOOP" = "CEMLOOP" ]; then
		for file in ${INSTANCE}/results_invest${OUT}/*_save_*.csv ; do	
			if [ -f "$file" ]; then
				rm file
			fi
		done
		for file in ${INSTANCE}/results_simul${OUT}/*_save_*.csv ; do	
			if [ -f "$file" ]; then
				rm file
			fi
		done
	fi
}

function remove_all_investment_results() {
	echo -e "${print_blue}        - if existing, remove previous investment results in ${INSTANCE}/results_invest${OUT} ${no_color}\n"
	if [ -f "${INSTANCE}/results_invest${OUT}/Solution_OUT.csv" ]; then
		echo -e "${print_blue}            - delete file ${INSTANCE}/results_invest${OUT}/Solution_OUT.csv ${no_color}\n"
		rm ${INSTANCE}/results_invest${OUT}/Solution_OUT*.csv
	fi
	if [ -f "${INSTANCE}/results_invest${OUT}/investment_candidates.txt" ]; then
		rm ${INSTANCE}/results_invest${OUT}/investment_candidates.txt
	fi
	for file in ${INSTANCE}/results_invest${OUT}/*_save_*.csv ; do	
		if [ -f "$file" ]; then
			rm file
		fi
	done
	
	for file in ${INSTANCE}/csv_invest/*invested.csv ; do	
		if [ -f "$file" ]; then
			rm $file
		fi
	done
	for file in ${INSTANCE}/csv_invest/*_save*.csv ; do	
		if [ -f "$file" ]; then
			rm $file
		fi
	done
	for file in ${INSTANCE}/csv_simul/*_save*.csv ; do	
		if [ -f "$file" ]; then
			rm $file
		fi
	done
}

function clean_csv() {
	dir="${INSTANCE}/csv_$1"
	echo -e "${print_blue}        - clean repo $dir ${no_color}\n"
	for file in $inputs ; do
		if [ -f "${dir}/${file}_save_0.csv" ]; then
			echo -e "${print_blue}            - ${dir}/${file}_save_0.csv is present, used to backup ${no_color}\n"
			mv ${dir}/${file}_save_0.csv ${dir}/${file}.csv
			if [ -f "${dir}/${file}_save_1.csv" ]; then
				rm ${dir}/${file}_save_*.csv
			fi
		fi
	done
}

function check_ssv_output() {
	local mode=$1
	echo -e "${print_blue}        - check if SSV results exist in ${INSTANCE}/results_$mode${OUT} ${no_color}\n"
	if [ -f "${INSTANCE}/results_$mode${OUT}/BellmanValuesOUT.csv" ]; then
		echo -e "${print_green}            - BellmanValuesOUT.csv found in results_$mode${OUT}/ ${no_color}\n"
		if [ -f "${INSTANCE}/results_$mode${OUT}/bellmanvalues.csv" ]; then
			rm ${INSTANCE}/results_$mode${OUT}/bellmanvalues.csv
		fi
		cp ${INSTANCE}/results_$mode${OUT}/BellmanValuesOUT.csv ${INSTANCE}/results_$mode${OUT}/bellmanvalues.csv
		return 0
	elif [ -f "${INSTANCE}/results_$mode${OUT}/cuts.txt" ]; then
		echo -e "${print_green}            - cuts.txt found in results_$mode${OUT}/ ${no_color}\n"
		cp ${INSTANCE}/results_$mode${OUT}/cuts.txt ${INSTANCE}/results_$mode${OUT}/bellmanvalues.csv
		return 0
	else
		echo -e "${print_red}            - None of BellmanValuesOUT.csv and cuts.txt is present in results_$mode${OUT}/ ${no_color}\n"
		return 1
	fi
}

function filter_cuts() {
	local mode=$1
	local group=$2
	local suffix=""
	if [ "$group" != "" ]; then 
		suffix="_$group" 
	fi
	# bellman values may have been computed for more ssv timestpeps than required => remove them
	LASTSTEP=$(ls -l ${INSTANCE}/nc4_${mode}${suffix}/Block*.nc4 | wc -l)
	echo -e "${print_blue}        - remove Bellman values after $LASTSTEP steps since they will not be used by the CEM ${no_color}\n"
	awk -F, -v laststep="$LASTSTEP" 'NR==1 || $1 < laststep' "${INSTANCE}/results_$mode${OUT}${suffix}/bellmanvalues.csv" > "${INSTANCE}/results_$mode${OUT}${suffix}/temp.csv"
	mv ${INSTANCE}/results_$mode${OUT}${suffix}/temp.csv ${INSTANCE}/results_$mode${OUT}${suffix}/bellmanvalues.csv
 }

function create_results_dir() {
	echo -e "${print_blue}        - create results repo in ${INSTANCE}/results_$1${OUT} ${no_color}\n"
	if [[ ! -d "${INSTANCE}/results_$1" ]] ; then
		mkdir ${INSTANCE}/results_$1
	fi
	if [[ ! -z "${OUT}" ]]; then
		if [[ ! -d "${INSTANCE}/results_$1${OUT}" ]] ; then
			mkdir ${INSTANCE}/results_$1${OUT}
		fi
	fi
	if [ "$1"!="optim" ]; then
	    for file in $outputs ; do
			if [[ ! -d "${INSTANCE}/results_$1${OUT}/$file" ]]; then
					mkdir ${INSTANCE}/results_$1${OUT}/$file
			fi
		done
		if [[ ! -d "${INSTANCE}/results_$1${OUT}/MarginalCosts" ]]; then
			mkdir ${INSTANCE}/results_$1${OUT}/MarginalCosts
		fi
	fi
}

function move_simul_results() {
	echo -e "${print_blue}        - move results of simulation to ${INSTANCE}/results_$1${OUT}  ${no_color}\n"
	for file in $outputs ; do
		mv ${INSTANCE}/results_$1${OUT}/$file*.csv ${INSTANCE}/results_$1${OUT}/$file/
	done
	mv ${INSTANCE}/results_$1${OUT}/MarginalCost*.csv ${INSTANCE}/results_$1${OUT}/MarginalCosts/
}

function read_python_status {
	if [[ -f "$1" ]]; then	
		echo $(head -n 1 $1) 
	fi
}

function simulation_status {
	missing_files=()
	if [ "$mode1" = "invest" ]; then
		NB_SCEN="${NBSCEN_CEM}"
	else
		NB_SCEN="${NBSCEN_SIM}"
	fi
	
	if [[ $groupsim -eq 1 && $onegroupsim -eq 1 ]]; then
		BASE=$(( NBSCEN_SIM / sizegroupsim ))
		RESTE=$(( NBSCEN_SIM % sizegroupsim ))
		if [ $RESTE -ge 1 ]; then
			nb_group_sim=$(( BASE + 1 ))
		else	
			nb_group_sim=$BASE
		fi
		current_first_scen=0
		sizecurrentgroup=$sizegroupsim
		number_remaining_scen=$NBSCEN_SIM
		for ((grp=0; grp<$nb_group_sim; grp++)); do
			if [ $number_remaining_scen -lt $sizegroupsim ] ; then
				sizecurrentgroup=$number_remaining_scen
			else
				sizecurrentgroup=$sizegroupsim
			fi
			if [ $sizecurrentgroup -gt 0 ]; then
				old_current_first_scen=$current_first_scen
				current_first_scen=$(( old_current_first_scen + sizecurrentgroup ))
				number_remaining_scen=$(( number_remaining_scen - sizecurrentgroup ))
			fi
		done
		last_scen=$(( current_first_scen + sizecurrentgroup ))
		# Check outputs of simulation
		for ((i=current_first_scen; i<last_scen; i++)); do
			for rep in $outputs ; do
				file="${INSTANCE}/results_${mode1}${OUT}/${rep}/${rep}_Scen${i}_OUT.csv"
				if [[ ! -f "$file" ]]; then
					missing_files+=(${rep}_Scen${i})
				fi
			done
			for rep in $MarginalCosts ; do
				file="${INSTANCE}/results_${mode1}${OUT}/MarginalCosts/${rep}_Scen${i}_OUT.csv"
				if [[ ! -f "$file" ]]; then
					missing_files+=(${rep}_Scen${i}) 
				fi
			done
		done
	
	else	
		# Check outputs of simulation
		for ((i=0; i<NB_SCEN; i++)); do
			for rep in $outputs ; do
				file="${INSTANCE}/results_${mode1}${OUT}/${rep}/${rep}_Scen${i}_OUT.csv"
				if [[ ! -f "$file" ]]; then
					missing_files+=(${rep}_Scen${i})
				fi
			done
			for rep in $MarginalCosts ; do
				file="${INSTANCE}/results_${mode1}${OUT}/MarginalCosts/${rep}_Scen${i}_OUT.csv"
				if [[ ! -f "$file" ]]; then
					missing_files+=(${rep}_Scen${i}) 
				fi
			done
		done
	fi

	if [ ${#missing_files[@]} -eq 0 ]; then
		echo -e "${print_green}$(date +'%m/%d/%Y %H:%M:%S') - successfully ran SIM. ${no_color}"
    	echo -e "${print_green} results available in ${INSTANCE}/results_$mode1${OUT} ${no_color}"
		return 0
	else
		echo -e "${print_red}$(date +'%m/%d/%Y %H:%M:%S') - error while running SIM for scenarios ${missing_files[@]}.${no_color}"
		return 1
	fi
}

function create_status {
	missing_files=()
	
	# Check outputs of create
	for csv in $inputs ; do
		file="${INSTANCE}/csv_${mode1}/${csv}.csv"
		if [[ ! -f "$file" ]]; then
			missing_files+=(${csv})
		fi
	done

	if [ ${#missing_files[@]} -eq 0 ]; then
		echo -e "${print_green}$(date +'%m/%d/%Y %H:%M:%S') - successfully ran CREATE. ${no_color}"
    	echo -e "${print_green} results available in ${INSTANCE}/csv_$mode1${no_color}"
		return 0
	else
		echo -e "${print_red}$(date +'%m/%d/%Y %H:%M:%S') - error while running CREATE ${missing_files[@]}.${no_color}"
		return 1
	fi
}

function linkgenesys_status {
	missing_files=()
	
	# Check outputs of linkgenesys
	file="${INSTANCE}/IAMC/${DATASET}.xlsx"
	if [[ ! -f "$file" ]]; then
		missing_files+=(${file})
	fi

	if [ ${#missing_files[@]} -eq 0 ]; then
		echo -e "${print_green}$(date +'%m/%d/%Y %H:%M:%S') - successfully ran LINKGENESYS. ${no_color}"
    	echo -e "${print_green} results available in ${INSTANCE}/IAMC${no_color}"
		return 0
	else
		echo -e "${print_red}$(date +'%m/%d/%Y %H:%M:%S') - error while running LINKGENESYS ${missing_files[@]}.${no_color}"
		return 1
	fi
}


function format_status {
	missing_files=()
		
	begin=$(get_yaml_value_level1 "${CONFIG}/settings_format_${mode1}.yml" "BeginDataset")
	end=$(get_yaml_value_level1 "${CONFIG}/settings_format_${mode1}.yml" "EndDataset")
	dayFirst=$(get_yaml_value_level1 "${CONFIG}/settings_format_${mode1}.yml" "dayfirst")
	UnitDuration=$(get_yaml_value_level2 "${CONFIG}/settings_format_${mode1}.yml" "SSVTimeStep" "Unit")
	DurationBlock=$(get_yaml_value_level2 "${CONFIG}/settings_format_${mode1}.yml" "SSVTimeStep" "Duration")
	
	cleaned_begin=$(echo "$begin" | tr -d '\r' | sed "s/'//g" | sed 's/  */ /g')
	cleaned_end=$(echo "$end" | tr -d '\r' | sed "s/'//g" | sed 's/  */ /g')
	cleaned_DurationBlock=$(echo "$DurationBlock" | tr -d '\r' | sed "s/'//g" | sed 's/  */ /g')
	
	if [[ "$dayFirst" != *"True"* ]] ; then
		# Format mm/jj/aaaa HH:MM:SS
		start_seconds=$(date -d "$(echo $cleaned_begin | awk -F'[/ :]' '{print $1"/"$2"/"$3" "$4":"$5":"$6}')" +%s 2>/dev/null)
		end_seconds=$(date -d "$(echo $cleaned_end | awk -F'[/ :]' '{print $1"/"$2"/"$3" "$4":"$5":"$6}')" +%s 2>/dev/null)
	else
		# Format jj/mm/aaaa HH:MM:SS
		start_seconds=$(date -d "$(echo $cleaned_begin | awk -F'[/ :]' '{print $2"/"$1"/"$3" "$4":"$5":"$6}')" +%s 2>/dev/null)
		end_seconds=$(date -d "$(echo $cleaned_end | awk -F'[/ :]' '{print $2"/"$1"/"$3" "$4":"$5":"$6}')" +%s 2>/dev/null)
	fi
		
	difference_seconds=$((end_seconds - start_seconds))
	difference_hours=$((difference_seconds / 3600  + 1))
	
	if [[ "$UnitDuration" = *"hours"* ]]; then
		unit=1
	elif [[ "$UnitDuration" = *"days"* ]]; then
		unit=24
	elif [[ "$UnitDuration" = *"weeks"* ]]; then
		unit=168
	else
		echo -e "${print_red}  Bad unit ($UnitDuration) for SSVTimeStep duration in ${CONFIG}/settingsCreateInputPlan4res_${mode1}.yml.${no_color}"
		return 1
	fi
	DurationBlock=$((cleaned_DurationBlock * unit))
	number_blocks=$((difference_hours / DurationBlock ))
	echo "There are $number_blocks Blocks"	
	
	if [ $? -ne 0 ]; then
		echo -e "${print_red}$(date +'%m/%d/%Y %H:%M:%S') - error while computing the number of UCBlocks .${no_color}"
		return 1
	fi
	
	# check InvestmentBlock.nc4
																				 
	if [[ "$mode1" = "simul" || "mode1" = "invest" || "mode1" = "postinvest" ]]; then
		if [ ! -f "${INSTANCE}/nc4_${mode1}/InvestmentBlock.nc4" ]; then
			missing_files+=("InvestmentBlock")
		fi
	fi
   
	
	if [[ ! -f "${INSTANCE}/nc4_${mode1}/SDDPBlock.nc4" ]]; then
		missing_files+=("SDDPBlock")
	fi
	
	for ((i=0; i<number_blocks; i++)); do
		file="${INSTANCE}/nc4_${mode1}/Block_${i}.nc4"
		if [[ ! -f "$file" ]]; then
			missing_files+=("Block_${i}")
		fi
	done

	if [ ${#missing_files[@]} -eq 0 ]; then
		echo -e "${print_green}$(date +'%m/%d/%Y %H:%M:%S') - successfully ran FORMAT. ${no_color}"
    	echo -e "${print_green} results available in ${INSTANCE}/nc4_$mode1 ${no_color}"
		return 0
	else
	    echo -e "${print_red}$(date +'%m/%d/%Y %H:%M:%S') - error while running FORMAT ${missing_files[@]} in ${INSTANCE}/nc4_$mode1.${no_color}"
		return 1
	fi
}

function get_yaml_value_level1() {
	local file=$1
	local key=$2
	while IFS= read -r line; do
		trimmed_line=$(echo "$line" | sed 's/^[ \t]*//') # remove spaces and tabs at begin of line
		
		# check if line does not start by # and contains the key
		if [[ ! $trimmed_line =~ ^# ]] && [[ $trimmed_line == *"$key"* ]]; then
			echo "$trimmed_line" | sed "s/.*$key: *//"
			return
		fi
	done < "$file"
}

function get_yaml_value_level2() {
	local file=$1
	local key1=$2
	local key2=$3
	local found_key1=false

	while IFS= read -r line; do
		trimmed_line=$(echo "$line" | sed 's/^[ \t]*//')  # remove spaces and tabs at begin of line
		
		# check if line does not start by # and contains the key
		if [[ ! $trimmed_line =~ ^# ]] && [[ $trimmed_line == *"$key1"* ]]; then
			found_key1=true
		elif $found_key1 && [[ ! $trimmed_line =~ ^# ]] && [[ $trimmed_line == *"$key2"* ]]; then
			echo "$line" | sed "s/.*$key2: *//"
			return
		fi
	done < "$file"
}

function update_yaml_param() {
	local file="$1"
	local level="$2"
	local key_path="$3"
	local new_value="$4"
	local indent="${5:-4}"

	# Convert keys in a table (the key must be given as a string with eg 3 words if it is a level 3 param"
	IFS=' ' read -r -a keys <<< "$key_path"

	# compute number of spaces in indesnt
	local total_indent=$(( (level - 1) * indent ))
	local indentation
	indentation=$(printf '%*s' "$total_indent")

	# find target key
	local target_key="${keys[-1]}"

	case "$new_value" in
		true|false|yes|no)
			local formatted_value="$new_value"
			;;
		*)
			local formatted_value="\"$new_value\""
			;;
	esac

	# find row to replace and create new row
	local search_line="${indentation}${target_key}:"
	local replacement="${search_line} ${formatted_value}"

	# replace row
	sed -i -E "s|^${search_line}[^\n]*|${replacement}|" "$file"
}


function sddp_status {
    if [[ -f "${INSTANCE}/results_${mode1}${OUT}/BellmanValuesOUT.csv" ]]; then
        echo -e "${print_green}$(date +'%m/%d/%Y %H:%M:%S') - successfully ran SSV with SDDP solver (convergence OK).${no_color}"
    	echo -e "${print_green} results available in ${INSTANCE}/results_${mode1}${OUT} ${no_color}"
		return 0
	else
        if [[ -f "${INSTANCE}/results_${mode1}${OUT}/cuts.txt" ]]; then
            echo -e "${print_orange}$(date +'%m/%d/%Y %H:%M:%S') - partially ran SSV with SDDP solver${no_color}${print_red} (no convergence).${no_color}"
			echo -e "${print_orange} results available in ${INSTANCE}/results_${mode1}${OUT} ${no_color}"
			return 0
        else
            echo -e "${print_red}$(date +'%m/%d/%Y %H:%M:%S') - error while running sddp_solver.${no_color}"
            return 1
        fi
    fi
}

function investment_status {
    if [[ -f "${INSTANCE}/results_invest${OUT}/Solution_OUT.csv" ]]; then
        echo -e "${print_green}$(date +'%m/%d/%Y %H:%M:%S') - successfully ran CEM with investment_solver.${no_color}"
		echo -e "${print_green} results available in ${INSTANCE}/results_${mode1}${OUT} ${no_color}"
		return 0
	else
        echo -e "${print_red}$(date +'%m/%d/%Y %H:%M:%S') - error while running CEM with investment_solver.${no_color}"
        return 1
    fi
}

# increment number of int parameters in sms++ config file $1
function increment_int_param_count() {
	file=$1
	current_value=$(grep -oP '^\d+(?=\s+# number of integer parameters)' "$file")
	new_value=$((current_value + 1))
	sed -i "s/^$current_value\s\+# number of integer parameters/$new_value # number of integer parameters/" "$file"
}

# increment number of str parameters in sms++ config file $1
function increment_str_param_count() {
	file=$1
	current_value=$(grep -oP '^\d+(?=\s+# number of string parameters)' "$file")
	new_value=$((current_value + 1))
	sed -i "s/^$current_value\s\+# number of string parameters/$new_value # number of string parameters/" "$file"
}

# increment number of str parameters in sms++ config file $1
function increment_dbl_param_count() {
	file=$1
	current_value=$(grep -oP '^\d+(?=\s+# number of double parameters)' "$file")
	new_value=$((current_value + 1))
	sed -i "s/^$current_value\s\+# number of double parameters/$new_value # number of double parameters/" "$file"
}

# check if parameter $2 exists in sms++ config file $1
function check_param() {
    file=$1
	name=$2
	if grep -q "$name" "$file"; then
		return 0
    else
        return 1
    fi
}

# replace parameter $2 by $3 in sms++ config file $1
function replace_param() {
	local name="$2"
	local value="$3"
    local file="$1"
	escaped_value=$(echo "$value" | sed 's/[\/&]/\\&/g')
	sed -i "s/^${name//\//\\/}.*/$name $escaped_value/" "$file"
}

function get_solver() {
	local file="$1"
    local found_block_solver_config=false
    local line_number=0

    while IFS= read -r line || [ -n "$line" ]; do
        # Ignore lines starting by # and empty lines
        if [[ "$line" =~ ^# ]] || [[ -z "$line" ]]; then
            continue
        fi

        # Check if line starts with BlockSolverConfig
        if [[ "$line" =~ ^BlockSolverConfig ]]; then
            found_block_solver_config=true
            line_number=0
            continue
        fi

        # If BlockSolverConfig awas found, count following active lines, gets solver name on 3rd line
        if $found_block_solver_config; then
            ((line_number++))
            if [[ $line_number -eq 3 ]]; then
                solver_name=$(echo "$line" | awk -F'#' '{print $1}' | xargs)
                echo "$solver_name"
                return
            fi
        fi
    done < "$file"
	
}

# gets the value of parameter $2 in sms++ config file $1
function get_param_value() {
    local param="$1"
    local file="$2"
    
    # Utilisation de grep et awk pour extraire la valeur du paramètre
    local value=$(grep "^$param" "$file" | awk '{print $2}')
    
    echo "$value"
	# to retrieve the value, use value=$(get_param_value "$param" "$file")
}

# add string parameter $2 with value $3 in sms++ config file $1
function add_str_param(){
	file=$1
	name=$2
	value=$3
	sed -i "/# now all the string parameters/a $name $value" "$file"
}

# add int parameter $2 with value $3 in sms++ config file $1
function add_int_param(){
    file=$1
	name=$2
	value=$3
	sed -i "/# now all the integer parameters/a $name $value" "$file"
}

# add double parameter $2 with value $3 in sms++ config file $1
function add_dbl_param(){
    file=$1
	name=$2
	value=$3
	sed -i "/# now all the double parameters/a $name $value" "$file"
}

# Function to retrieve the solution value from the log file of the solver
function solution_value() {
    local log_input=$1  # Input string containing log information

    # Check if the input string is provided
    if [[ -z "$log_input" ]]; then
        echo -e "${print_red} Usage: solution_value <log_input>${no_color}"
        return 1
    fi

    # Extract solution values from the input string using grep and awk
    matches=$(echo "$log_input" | grep -oP 'Solution value:\s*([-+]?\d*\.\d+(e[+-]?\d+)?|\d+e[+-]?\d+)' | awk '{print $3}')

    # Check if we have at least one solution value
    if [[ -z "$matches" ]]; then
        echo -e "${print_red} No solution values found in the input string.${no_color}"
        return 1
    fi

    # Get the last solution value and output it
    last_value=$(echo "$matches" | tail -n 1)
    echo "$last_value"
}

# Function to compare costs between two iterations
function compare_costs() {
	cost_before=$1
    cost_after=$2
    epsilon=$3

	# Convert scientific notation to floating-point numbers using printf
	cost_before_float=$(printf "%.10f\n" "$cost_before")
    cost_after_float=$(printf "%.10f\n" "$cost_after")
	
	# Handle the case where cost_before is zero to avoid division by zero
    if (( $(echo "$cost_before_float == 0" | bc -l 2>/dev/null) )); then
        return 1
    else
		relative_difference=$(echo "scale=4; (($cost_after_float - $cost_before_float) / $cost_before_float) " | bc -l 2>/dev/null)
		absolute_difference=$(echo "scale=4; if ($relative_difference < 0) -1 * $relative_difference else $relative_difference" | bc -l 2>/dev/null)
		echo "Cost before: $cost_before_float, Cost after: $cost_after_float, Relative difference : $absolute_difference, epsilon: $epsilon"

		# Comparaison avec epsilon
		comparison=$(echo "$absolute_difference < $epsilon" | bc -l 2>/dev/null)
		if (( comparison )); then
			return 0
		else
			return 1
		fi
	fi

}


function compare_costs_old() {
    local cost_before=$1  # Cost from the previous iteration
    local cost_after=$2   # Cost from the current iteration
    local epsilon=$3      # Epsilon value for comparison

    # Convert scientific notation to floating-point numbers using printf
    cost_before_float=$(printf "%.10f\n" "$cost_before")
    cost_after_float=$(printf "%.10f\n" "$cost_after")

    # Handle the case where cost_before is zero to avoid division by zero
    if (( $(echo "$cost_before_float == 0" | bc -l 2>/dev/null) )); then
        relative_diff="Infinity"  # Assign infinity if cost_before is zero
    else
        # Calculate the relative difference and use the absolute value (|x|) for the comparison
        relative_diff=$(echo "scale=7; ($cost_after_float - $cost_before_float) / $cost_before_float" | bc -l 2>/dev/null)
        relative_diff=$(echo "scale=7; if ($relative_diff < 0) -1*$relative_diff else $relative_diff" | bc -l 2>/dev/null)
    fi

    # Output the costs and the calculated relative difference
    echo "Cost before: $cost_before_float, Cost after: $cost_after_float, Relative difference (absolute): $relative_diff"

    # If cost_before was zero, we don't calculate relative difference properly
    if [[ "$relative_diff" = "Infinity" ]]; then
        return 1  # Treat this case as non-converged
    fi

    # Compare the relative difference with epsilon (convergence condition)
    if (( $(echo "$relative_diff < $epsilon" | bc -l 2>/dev/null) )); then
        return 0  # Return 1 if the difference is less than epsilon (converged)
    else
        return 1  # Return 0 otherwise (not converged)
    fi
}

function update_scenarios() {
	local settings=$1
	local list_scenarios=$2
	echo -e "${print_blue} - updating $settings with $list_scenarios ${no_color}"
	sed -i -E "s/^(\s*)Scenarios:\s*\[.*\]/\1Scenarios: $list_scenarios/" "$settings"
}

function copy_ssv_output_from_to() {
	from=$1
	to=$2
	if [[ ! -d ${INSTANCE}/results_$to${OUT} ]]; then mkdir ${INSTANCE}/results_$to${OUT} ; fi
	if [ -f "${INSTANCE}/results_$from${OUT}/BellmanValuesOUT.csv" ]; then
		echo -e "${print_blue}        - BellmanValuesOUT.csv found in results_$from${OUT}/ ${no_color}"
		echo -e "${print_blue}        - copying to ${INSTANCE}/results_$to${OUT} ${no_color}"
		cp ${INSTANCE}/results_$from${OUT}/BellmanValuesOUT.csv ${INSTANCE}/results_$to${OUT}/BellmanValuesOUT.csv
		cp ${INSTANCE}/results_$from${OUT}/BellmanValuesOUT.csv ${INSTANCE}/results_$to${OUT}/bellmanvalues.csv
		return 0
	elif [ -f "${INSTANCE}/results_$from${OUT}/cuts.txt" ]; then
		echo -e "${print_blue}        - cuts.txt found in results_$from${OUT}/ ${no_color}"
		echo -e "${print_blue}        - copying to ${INSTANCE}/results_$to${OUT} ${no_color}"
		cp ${INSTANCE}/results_$from${OUT}/cuts.txt ${INSTANCE}/results_$to${OUT}/cuts.txt
		cp ${INSTANCE}/results_$from${OUT}/cuts.txt ${INSTANCE}/bellmanvalues.csv
		return 0
	else		
		echo -e "${print_red} - None of BellmanValuesOUT.csv and cuts.txt is present in results_$from${OUT}/ ${no_color}"
		return 1
	fi	
}

function test_fill_option() {
	local var_name="$1"
	local value_first=$4
	local value=$3
	local option=$2
	local var_value="${!var_name}"
	echo "test_fill_option with varbame1=$var_name value3=$value option2=$option var_value=$var_value"

	if [[ $value_first == --* ]] || [[ $value_first == -* ]] || [[ $value_first == "" ]]; then
    	echo -e "${print_red} input not provided afer $option"
		if [[ -z "$var_value" ]]; then
        	echo -e "${print_red} variable $var_name not in $main_config_file${no_color}"
			return 1
		else
			echo -e "${print_orange}        input not provided afer $option but variable $var_name available in $main_config_file with value $var_value ${no_color}"			
			return 0    		
		fi
	else
		if [[ $value == --* ]] || [[ $value == -* ]] || [[ $value == "" ]]; then
			echo -e "${print_red} input not provided afer $option"
			if [[ -z "$var_value" ]]; then
				echo -e "${print_red} variable $var_name not in $main_config_file${no_color}"
				return 1
			else
				echo -e "${print_orange}        input not provided afer $option but variable $var_name available in $main_config_file with value $var_value ${no_color}"			
				return 0    		
			fi
		else
			echo -e "${print_green} value : $value for var $var_name will be used"
			"$var_name"="$value"
			shift
			return 0
		fi
	fi 
	return 0	
}


function test_option() {	
	local code=$1
	local option1=$2
	if [[ $option1 == --* ]] || [[ $option1 == -* ]] || [[ $option1 == "" ]]; then
		echo -e "${print_red} input not provided afer $code ${no_color}"
		return 1
	else
		return 0
	fi
}


function test_option2() {
	local code=$1
	local option1=$2
	local option2=$2
	if [[ $option1 == --* ]] || [[ $option1 == -* ]] || [[ $option2 == --* ]] || [[ $option2 == -* ]]; then
		echo -e "${print_red} inputs not provided afer $code ${no_color}"
		return 1
	fi
}

function ceil_division() {
    local a=$1
    local b=$2
    local ceil

    ceil=$(awk -v a="$a" -v b="$b" 'BEGIN { division = a / b; print (division == int(division)) ? division : int(division) + 1 }')
    echo "$ceil"
}

clean() {
	remove_previous_ssv_results optim
	remove_previous_simulation_results invest
	remove_previous_simulation_results simul
	remove_all_investment_results
	clean_csv simul
	clean_csv invest
}

