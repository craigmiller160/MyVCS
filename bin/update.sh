#!/bin/bash
# SCRIPT
# NAME: update.sh
# DESCRIPTION: This is the script that handles updating the working directory.
#				It receives the name of the branch to pull updated data from SVN
#				for, and then merge that update into the local Git branch.
# OPTIONS:
#			[branch name] : (Required) The name of the branch to pull an update
#								from SVN for and merge into the Git branch.

# UPDATED FOR MYVCS2

# FUNCTION
# NAME: update_master_from_trunk_func
# DESCRIPTION: This function updates the master Git branch on the local machine
#				from the SVN trunk. Any changes from SVN will be committed to Git.
function update_master_from_trunk_func {
	cd "$DEV_MAIN_PATH"

	git_switch_func "master"
	svn_switch_func "trunk"

	echo "$TAG Updating from SVN trunk"
	svn update . 1>/dev/null 2>/dev/null

	# Revert to solve any conflicts
	if [ ! -z "$(svn status)" ]; then
		echo "$TAG Resolving conflicts with SVN files on trunk."
		svn revert -R . 1>/dev/null 2>/dev/null
	fi

	# Commit any changes that are detected.
	if [ ! -z "$(git status --porcelain)" ]; then
		echo "$TAG Changes from SVN trunk detected. Committing them to Git master."
		git add . 1>/dev/null 2>/dev/null
		git commit -m "Committing changes from SVN trunk." 1>/dev/null 2>/dev/null
	else
		echo "$TAG No changes from SVN trunk detected. Nothing to be committed to Git master."
	fi
}

# Check the number of arguments first
if [ $# -ne 2 ]; then
	printf "${RED}${BOLD}$TAG Error! Need to specify name of branch to update.${NORM}${NC}."
fi

# Set the MYVCS_PATH variable and source bin files
MYVCS_PATH="$1"
source "$MYVCS_PATH/myvcs-config.properties"
source "$MYVCS_PATH/bin/global.sh"

echo "$TAG Downloading any changes from SVN trunk"

case $2 in
	trunk)
		update_master_from_trunk_func
	;;
esac