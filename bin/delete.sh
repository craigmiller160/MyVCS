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

if [ $# -ne 2 ]; then
	printf "${RED}${BOLD}$TAG Error! Delete command requires a branch name parameter.${NORM}${NC}\n"
	exit 1
fi

# Set the MYVCS_PATH variable and source bin files
MYVCS_PATH="$1"
source "$MYVCS_PATH/myvcs-config.properties"
source "$MYVCS_PATH/bin/global.sh"

case "$2" in
	"$DEV_MAIN_DIR" | "master")
		printf "${RED}${BOLD}$TAG Error! Cann't delete main development branch.${NORM}${NC}\n"
		exit 1
	;;
esac

echo "$TAG $2: Preparing to delete branch from filesystem, local Git, and remote Git."

cd "$DEV_ROOT_PATH"

# If a directory with that name exists, delete it from the fielsystem.
DIR_EXISTS=$(ls | grep $2)
if [ "$DIR_EXISTS" != "" ]; then
	printf "$TAG $2: Deleting branch directory from filesystem."
	ERROR=$(rm -rf "$2" 2>&1 >/dev/null) &
	while pkill -0 -u craigmiller -x rm; do
		printf "."
		sleep 1
	done
	printf "\n"

	if [ $? -ne 0 ]; then
		printf "${RED}${BOLD}$TAG $2: Unable to delete branch directory from filesystem.${NORM}${NC}\n"
		printf "${RED}$ERROR${NC}"
	else
		echo "$TAG $2: Successfully deleted branch directory from filesystem."
	fi
else
	printf "${RED}${BOLD}$TAG $2: Branch is not a directory on local filesystem. Nothing deleted.${NORM}${NC}\n"
fi

"$MYVCS_PATH/bin/git.sh" "$MYVCS_PATH" delete "$2"

exit 0