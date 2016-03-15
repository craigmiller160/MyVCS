#!/bin/sh
# SCRIPT
# NAME: update.sh
# DESCRIPTION: This is the script that handles updating the working directory.
#				Initially it is being created to handle updating the Git master
#				branch from Trunk, but it will ultimately do more than that.
# OPTIONS:
#			[-to | --trunk-only] : (Optional) A flag to indicate that this update
#									is simply to update the Git master branch from SVN trunk.

# Get shell script's directory and move shell there to execute config script
SCRIPT_DIR="$(dirname "${BASH_SOURCE}")"
cd "$SCRIPT_DIR"
source ./global.sh

### TODO need to be able to handle conflicts silently and warn the user about them

function update_master_from_trunk_func {
	cd "$DEV_MAIN_PATH"

	git_switch_func "master"
	svn_switch_func "trunk"

	echo "$TAG Updating from SVN trunk"
	svn update . 1>/dev/null 2>/dev/null

	if [ ! -z "$(svn status)" ]
		then
			echo "$TAG Resolving conflicts with SVN files on trunk."
			svn revert -R . 1>/dev/null 2>/dev/null
	fi

	if [ ! -z "$(git status --porcelain)" ]
		then
			echo "$TAG Changes from SVN trunk detected. Committing them to Git master."
			git add . 1>/dev/null 2>/dev/null
			git commit -m "Committing changes from SVN trunk. `date +%Y-%m-%d::%H:%M:%S`" 1>/dev/null 2>/dev/null
		else
			echo "$TAG No changes from SVN trunk detected. Nothing to be committed to Git master."
	fi
}

echo "$TAG Downloading any changes from SVN trunk"

case $1 in
	-to | --trunk-only)
		update_master_from_trunk_func
	;;
esac