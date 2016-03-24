#!/bin/sh
# SCRIPT
# NAME: delete.sh
# DESCRIPTION: A script for conveniently deleting all content
#				associated with a given branch. This script will
#				delete the local directory, the local Git branch,
#				and the remote Git branch. It will NOT touch the SVN
#				branch.
# OPTIONS:
#			[branch name] : (Required) The name of the branch to delete

# Get shell script's directory and move shell there to execute config script
# SCRIPT_DIR="$(dirname "${BASH_SOURCE}")"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $SCRIPT_DIR
source ./global.sh

if [ $# -ne 1 ]; then
	printf "${RED}${BOLD}$TAG Error! Delete command requires a branch name parameter.${NORM}${NC}\n"
	exit 1
fi

case "$1" in
	"$DEV_MAIN_DIR" | "master")
		printf "${RED}${BOLD}$TAG Error! Cann't delete main development branch.${NORM}${NC}\n"
		exit 1
	;;
esac

echo "$TAG $1: Preparing to delete branch from filesystem, local Git, and remote Git."

cd "$DEV_ROOT_PATH"

# If a directory with that name exists, delete it from the fielsystem.
DIR_EXISTS=$(ls | grep $1)
if [ "$DIR_EXISTS" != "" ]; then
	echo "$TAG $1: Deleting branch directory from filesystem."
	ERROR=$(rm -rf "$1" 2>&1 >/dev/null)
	if [ $? -ne 0 ]; then
		printf "${RED}${BOLD}$TAG $1: Unable to delete branch directory from filesystem.${NORM}${NC}\n"
		printf "${RED}$ERROR${NC}"
	else
		echo "$TAG $1: Successfully deleted branch directory from filesystem."
	fi
else
	printf "${RED}${BOLD}$TAG $1: Branch is not a directory on local filesystem. Nothing deleted.${NORM}${NC}\n"
fi

### TODO make this call more platform-independent
$SCRIPT_DIR/git.sh delete $1

exit 0