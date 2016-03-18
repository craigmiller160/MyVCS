#!/bin/sh
# SCRIPT
# NAME: git.sh
# DESCRIPTION: A script to conveniently execute certain complex operations
#				involving Git.
# OPTIONS:
#			[command] : (Required) The command for this script to execute
#			[branch name] : (Optional) The branch name, only required for
#							certain commands.

# Get shell script's directory and move shell there to execute config script
SCRIPT_DIR="$(dirname "${BASH_SOURCE}")"
cd $SCRIPT_DIR
source ./global.sh

#### TODO document this function
function git_backup_func {

	# Move to the root of the dev directory and get a list of sub directories
	cd "$DEV_ROOT_PATH"
	DIRS=$(ls)

	# Iterate through sub directories and push them all to origin
	for DIR in ${DIRS[@]}; do
		# Skip the dev main directory
		if [ "$DIR" != "$DEV_MAIN_DIR" ]; then
			cd "$DIR"
			git push origin HEAD:"$DIR" 1>/dev/null 2>/dev/null

			if [ $? -ne 0 ]; then
				git pull origin "$DIR" 1>/dev/null 2>/dev/null

				if [ $? -ne 0 ]; then
						printf "${RED}$TAG $DIR: Failed to push to origin.${NC}\n"
						#### TODO need to add an error message here
				fi
			fi

			if [ $? -eq 0 ]; then
				echo "$TAG $DIR: Successfully pushed to origin"
			fi
		fi
		cd "$DEV_ROOT_PATH"
	done

	# Move to Main directory
	cd "$DEV_MAIN_PATH"

	#### TODO need to handle output and errors for git checkout commands

	# Get an array of all branch names from Git
	BRANCHES=()
	eval "$(git for-each-ref --shell --format='BRANCHES+=(%(refname))' refs/heads/)"
	echo "$TAG Backing up all branches in bitbucket. This could take a few minutes, please wait."
	# Iterate through all branches and push each one to bitbucket
	for BRANCH in "${BRANCHES[@]}"; do
		BRANCH="$(awk -F/ '{print $3}' <<< $BRANCH)"
		git checkout "$BRANCH"
		ERROR=$(git push bitbucket "$BRANCH" 2>&1 >/dev/null) 

		if [ $? -ne 0 ]; then
			printf "${RED}$TAG $BRANCH: Failed to backup to bitbucket.${NC}\n"
			printf "${RED}$ERROR.${NC}\n"
		else
			printf "$TAG $BRANCH: Successfully backed up to bitbucket.\n"
			
		fi
	done

	git checkout master 1>/dev/null 2>/dev/null

}

##### TODO document this function
function git_delete_func {

	# Test the number of arguments
	if [ $# -ne 1 ]; then
		printf "${RED}$TAG Error! Invalid number of arguments to git_delete_func.${NC}\n"
		return 1
	fi

	echo "$TAG $1: Deleting Git branch"

	cd "$DEV_MAIN_PATH"

	# Test if the branch exists before proceeding
	git_branch_exists_func $1
	if [ $? -ne 0 ]; then
		return 1
	fi

	# Delete the local branch. Won't have an error because we've already tested that the branch exists
	git branch -D $1 1>/dev/null 2>/dev/null
	echo "$TAG $1: Successfully deleted local Git branch."

	# Test if remote exists before proceeding
	REMOTE_EXISTS=$(git branch -a | grep remotes/bitbucket/$1)
	if [ "$REMOTE_EXISTS" != "" ]; then
		# Delete the remote branch
		ERROR=$(git push bitbucket --delete $1 2>&1 >/dev/null)
		if [ $? -ne 0 ]; then
			printf "${RED}$TAG $1: Unable to delete remote branch.${NC}\n"
			printf "${RED}$ERROR${NC}\n"
		else
			echo "$TAG $1: Successfully deleted remote Git branch."
		fi
	else
		echo "$TAG $1: No remote Git branch to delete."
	fi

	return 0

}

# Test that there is a valid number of arguments
if [ $# -lt 2 ]; then
	printf "${RED}$TAG Error! Invalid number of arguments.${NC}\n"
	return 1
fi

# Test the parameter to see which command to run
case $1 in
	backup)
		git_backup_func
	;;
	delete)
		git_delete_func "$2"
	;;
esac

if [ $? -ne 0 ]; then
	exit 1
else
	exit 0
fi

