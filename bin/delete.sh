#!/bin/bash
# SCRIPT
# NAME: delete.sh
# DESCRIPTION: A script for conveniently deleting all content
#				associated with a given branch. This script will
#				delete the local directory, the local Git branch,
#				and the remote Git branch. It will NOT touch the SVN
#				branch.
# OPTIONS:
#			[branch name] : (Required) The name of the branch to delete

# UPDATED FOR MYVCS2

### TODO add flag documentation to the OPTIONS section

# Set the MYVCS_PATH variable and source bin files
MYVCS_PATH="$1"
source "$MYVCS_PATH/myvcs-config.properties"
source "$MYVCS_PATH/bin/global.sh"

if [ $# -lt 2 ]; then
	printf "${RED}${BOLD}$TAG Error! Invalid number of parameters.${NORM}${NC}\n"
	exit 1
fi

NAME=""
NO_FLAG=true
LOCAL=false
DIR=false
REMOTE=false

#### TODO document this
function parse_arg {

	case $1 in
		-*)
			parse_flag $1
		;;
		*)
			if [ "$NAME" = "" ]; then
				NAME="$1"
			else
				printf "${RED}${BOLD}$TAG Error! Argument $1 is not a flag, and branch name is already set.${NORM}${NC}\n"
				exit 1
			fi
		;;
	esac

	return 0

}

#### TODO document this
function parse_flag {

	flag=$1
	NO_FLAG=false

	for (( i = 0; i < ${#flag}; i++ )); do
		case ${flag:$i:1} in
			l)
				if $LOCAL ; then
					printf "${RED}${BOLD}$TAG Error! Local flag (l) can only be provided once.${NORM}${NC}\n"
					exit 1
				fi

				LOCAL=true
			;;
			d)
				if $DIR ; then
					printf "${RED}${BOLD}$TAG Error! Directory flag (d) can only be provided once.${NORM}${NC}\n"
					exit 1
				fi

				DIR=true
			;;
			r)
				if $REMOTE ; then
					printf "${RED}${BOLD}$TAG Error! Remote flag (r) can only be provided once.${NORM}${NC}\n"
					exit 1
				fi

				REMOTE=true
			;;
			-)
				# Do nothing
			;;
			*)
				printf "${RED}${BOLD}$TAG Error! Invalid flag: ${flag:$i:1}${NORM}${NC}\n"
				exit 1
			;;
		esac
	done

	return 0

}

# Parse all arguments
for arg in "${@:2}"; do
	parse_arg $arg
done

# If no flag is provided, everything is true
if $NO_FLAG ; then
	LOCAL=true
	DIR=true
	REMOTE=true
fi

# If no branch name is provided, exit with an error
if [ "$NAME" = "" ]; then
	printf "${RED}${BOLD}$TAG Error! No branch name to delete provided.${NORM}${NC}\n"
	exit 1
fi

case "$NAME" in
	"$DEV_MAIN_DIR" | "master")
		printf "${RED}${BOLD}$TAG Error! Cann't delete main development branch.${NORM}${NC}\n"
		exit 1
	;;
esac

intro="$TAG $NAME: Preparing to delete"
if $DIR ; then
	intro="$intro [directory]"
fi

if $LOCAL ; then
	intro="$intro [local branch]"
fi

if $REMOTE ; then
	intro="$intro [remote branch]"
fi


echo "$intro."

cd "$DEV_ROOT_PATH"

# Delete the directory if that option is chosen
if $DIR; then
	DIR_EXISTS=$(ls | grep $NAME)
	if [ "$DIR_EXISTS" != "" ]; then
		printf "$TAG $NAME: Deleting branch directory from filesystem."
		ERROR=$(rm -rf "$NAME" 2>&1 >/dev/null) &
		while pkill -0 -u craigmiller -x rm; do
			printf "."
			sleep 1
		done
		printf "\n"

		if [ $? -ne 0 ]; then
			printf "${RED}${BOLD}$TAG $NAME: Unable to delete branch directory from filesystem.${NORM}${NC}\n"
			printf "${RED}$ERROR${NC}"
		else
			echo "$TAG $NAME: Successfully deleted branch directory from filesystem."
		fi
	else
		printf "${RED}${BOLD}$TAG $NAME: Branch is not a directory on local filesystem. Nothing deleted.${NORM}${NC}\n"
	fi
fi

"$MYVCS_PATH/bin/git.sh" "$MYVCS_PATH" delete "$NAME" $LOCAL $REMOTE

exit 0