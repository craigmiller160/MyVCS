#!/bin/sh
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
	if [ $# -lt 1 ]
		then
			printf "${RED}$TAG CRITICAL ERROR!!! validate_command_func needs a single value to parse.${NC}\n"
			return 1
	fi

	case "$1" in
		copy)
			if [ $# -ne 3 ]
				then
					printf "${RED}$TAG CRITICAL ERROR! copy command needs two pathnames as arguments.${NC}\n"
					return 1
				else
					COMMAND="$1"
					PATH1="$2"
					PATH2="$3"
			fi
		;;
		switch | merge)
			if [ $# -ne 2 ]
				then
					printf "${RED}$TAG CRITICAL ERROR! $1 command needs one pathname as an argument.${NC}\n"
					return 1
				else
					COMMAND="$1"
					PATH1="$2"
			fi
		;;
		*)
			printf "${RED}$TAG CRITICAL ERROR!!! Invalid command $1.${NC}\n"
			return 1
		;;
	esac

	return 0
}


# Get shell script's directory and move shell there to execute config script
SCRIPT_DIR="$(dirname "${BASH_SOURCE}")"
cd $SCRIPT_DIR
source ./global.sh

# Test the number of arguments supplied to this script and return an error if it's invalid
if [ $# -lt 1 ]
	then
		printf "${RED}$TAG CRITICAL ERROR!!! Invalid number of arguments supplied to svn script.${NC}\n"
		exit 1
fi

# If the first argument is the working directory flag, set those values
if [ "$1" = "-wd" ] || [ "$1" = "--working-directory" ]
	then
		USE_WD="true"
		WORKING_DIR="$2"
fi

# Validate and set the function command, whose position is determined by the USE_WD flag
if [ "$USE_WD" != "true" ]
	then
		validate_command_func "$@"
	else
		validate_command_func "${@:3}"
fi

# Test the status code for the function. If an error, exit the script
if [ $? -ne 0 ]
	then
		exit 1
fi

#########
# TODO need to test merge properly
#########

# If USE_WD is true, change directory to the working directory provided
if [ "$USE_WD" = "true" ]
	then
		cd "$WORKING_DIR"
fi

# Execute the command with the provided arguments
case "$COMMAND" in
	copy)
		svn_copy_func "$PATH1" "$PATH2"
	;;
	merge)
		svn_merge_func "$PATH1" "$WORKING_DIR"
	;;
	switch)
		svn_switch_func "$PATH1"
	;;
esac

exit 0