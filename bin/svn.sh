#!/bin/bash
# SCRIPT
# NAME: svn.sh
# DESCRIPTION: A script to conveniently execute SVN commands. It avoids needing
#				to produce the whole URL for various operations, thus making it
#				much simpler to execute those commands.
#				IMPORTANT: This script only works when executed in a directory
#				managed by SVN.
# OPTIONS:
#			-wd --working-directory : (Optional) Specifies that the argument after this
#										is the working directory to execute SVN commands in.
#			[working directory] : (Optional) The working directory to execute SVN commands in.
#									To be used, this option requires the -wd flag before it.
#			[command] : (Required) The SVN command to execute in this script
#			[pathnames...] : (Required/Optional) Depending on the command, certain pathnames
#								may be needed for execution.

# UPDATED FOR MYVCS2

# Whether or not a working directory value is supplied
USE_WD="false"
# The working directory, if it's supplied
WORKING_DIR=""
# The SVN command to execute
COMMAND=""
# The first path, if there is one
PATH1=""
# The second path, if there is one
PATH2=""
# The regex, for the add command
REGEX=""

# FUNCTION
# NAME: validate_command_func
# DESCRIPTION: A function to validate the inputted parameter for an SVN command. It will 
#				either set the command variable to the user input, or return an error code
#				if the user input is invalid
# OPTIONS:
#			[command] : (Required) The user-inputted command to validate.
#			[pathsnames...] : (Optional/Required) The names of the URL paths to use with
#								the command. One or more are required, depending on the command.
function validate_command_func {
	if [ $# -lt 1 ]; then
		printf "${RED}${BOLD}$TAG CRITICAL ERROR!!! validate_command_func needs a single value to parse.${NORM}${NC}\n"
		return 1
	fi

	case "$1" in
		copy)
			if [ $# -ne 3 ]; then
				printf "${RED}${BOLD}$TAG CRITICAL ERROR! copy command needs two pathnames as arguments.${NORM}${NC}\n"
				return 1
			else
				COMMAND="$1"
				PATH1="$2"
				PATH2="$3"
			fi
		;;
		switch | merge)
			if [ $# -ne 2 ]; then
				printf "${RED}${BOLD}$TAG CRITICAL ERROR! $1 command needs one pathname as an argument.${NORM}${NC}\n"
				return 1
			else
				COMMAND="$1"
				PATH1="$2"
			fi
		;;
		add)
			COMMAND="$1"
			REGEX="$2"
		;;
		*)
			printf "${RED}${BOLD}$TAG CRITICAL ERROR!!! Invalid command $1.${NORM}${NC}\n"
			return 1
		;;
	esac

	return 0
}

### TODO document this
function svn_add_func {

	IFS=$'\n'

	files=($(svn status | egrep "^\? *$1" | awk -F' ' '{$1=""; print $0 }' OFS=''))


	echo "The following files and directories will be added to SVN:"
	for f in ${files[@]}; do
		echo "  $f"
	done

	valid=false

	while ! $valid; do
		read -p "Do you want to proceed? (y/n): "
		case $REPLY in
			y)
				valid=true
				echo "Adding files"
				svn add ${files[@]// /}
			;;
			n)
				valid=true
				echo "Cancelling operation"
			;;
			*)
				echo "Invalid response, please try again"
			;;
		esac
	done

}


# Test the number of arguments supplied to this script and return an error if it's invalid
if [ $# -lt 2 ]; then
	printf "${RED}${BOLD}$TAG CRITICAL ERROR!!! Invalid number of arguments supplied to svn script.${NORM}${NC}\n"
	exit 1
fi

# Set the MYVCS_PATH variable and source bin files
MYVCS_PATH="$1"
source "$MYVCS_PATH/myvcs-config.properties"
source "$MYVCS_PATH/bin/global.sh"

validate_command_func "${@:2}"

# Test the status code for the function. If an error, exit the script
if [ $? -ne 0 ]; then
	exit 1
fi

cd "$DEV_MAIN_PATH"

# Execute the command with the provided arguments
case "$COMMAND" in
	copy)
		svn_copy_func "$PATH1" "$PATH2"
	;;
	merge)
		svn_merge_func "$PATH1"
	;;
	switch)
		svn_switch_func "$PATH1"
	;;
	add)
		svn_add_func "$REGEX"
	;;
esac

exit 0