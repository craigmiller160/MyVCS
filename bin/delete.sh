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
SCRIPT_DIR="$(dirname "${BASH_SOURCE}")"
cd $SCRIPT_DIR
source ./global.sh

if [ ?# -ne 1 ]; then
	printf "${RED}$TAG Error! Delete command requires a branch name parameter.${NC}\n"
	exit 1
fi



exit 0