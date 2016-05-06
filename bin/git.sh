#!/bin/bash
# SCRIPT
# NAME: git.sh
# DESCRIPTION: A script to conveniently execute certain complex operations
#				involving Git.
# OPTIONS:
#			[command] : (Required) The command for this script to execute
#			[branch name] : (Optional) The branch name, only required for
#							certain commands.

# UPDATED FOR MYVCS2

# FUNCTION
# NAME: git_backup_func
# DESCRIPTION: A function to backup all Git branches. It first pushes updated 
#				content from all Git branch directories to the corresponding
#				branches in the main directory. It then backs up all the branches
#				in the main directory with the bitbucket repository.
function git_backup_func {

	cd "$DEV_MAIN_PATH"
	BRANCH=$(svn info | grep ^URL | awk '{print $2}')
	if [ "$BRANCH" != "$SVN_TRUNK_URL" ]; then
		printf "${RED}${BOLD}$TAG Error! Main directory not on SVN trunk. Resolve this and try again.${NORM}${NC}\n"
		return 1
	fi

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
						printf "${RED}${BOLD}$TAG $DIR: Failed to push to origin.${NORM}${NC}\n"
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
		git checkout "$BRANCH" 1>/dev/null 2>/dev/null
		printf "$TAG $BRANCH: Backing up to bitbucket."
		ERROR=$(git push bitbucket "$BRANCH" 2>&1 >/dev/null) &
		PID=$!
		while pkill -0 git; do
			printf "."
			sleep 1
		done
		printf "\n"

		if [ $? -ne 0 ]; then
			printf "${RED}${BOLD}$TAG $BRANCH: Failed to backup to bitbucket.${NORM}${NC}\n"
			printf "${RED}$ERROR.${NC}\n"
		else
			printf "$TAG $BRANCH: Successfully backed up to bitbucket.\n"
			
		fi
	done

	git checkout master 1>/dev/null 2>/dev/null

}

# FUNCTION
# NAME: git_delete_func
# DESCRIPTION: A function to delete a Git branch. This function deletes its 
#				directory from the local filesystem, then deletes its local
#				Git branch, then deletes its branch in the remote bitbucket
#				repository.
# OPTIONS:
#			[branch name] : (Required) The name of the branch to delete
function git_delete_func {

	# Test the number of arguments
	if [ $# -lt 1 ]; then
		printf "${RED}${BOLD}$TAG Error! Invalid number of arguments to git_delete_func.${NORM}${NC}\n"
		return 1
	fi

	NAME="$1"
	LOCAL=$2
	REMOTE=$3

	cd "$DEV_MAIN_PATH"

	# If local option, delete local Git branch
	if $LOCAL ; then
		echo "$TAG $NAME: Deleting local Git branch"
		# Test if the branch exists before proceeding
		git_branch_exists_func $NAME
		if [ $? -ne 0 ]; then
			printf "${RED}${BOLD}$TAG $NAME: no local Git branch exists.${NORM}${NC}\n"
		else
			# Delete the local branch. Won't have an error because we've already tested that the branch exists
			git branch -D $1 1>/dev/null 2>/dev/null
			echo "$TAG $NAME: Successfully deleted local Git branch."
		fi
	fi

	# If remote option, delete remote Git branch
	if $REMOTE ; then
		REMOTE_EXISTS=$(git branch -a | grep remotes/bitbucket/$NAME)
		if [ "$REMOTE_EXISTS" != "" ]; then
			# Delete the remote branch
			printf "$TAG $NAME: Deleting remote branch."
			ERROR=$(git push bitbucket --delete $NAME 2>&1 >/dev/null) &
			while pkill -0 -u craigmiller -x git; do
				printf "."
				sleep 1
			done
			printf "\n"

			if [ $? -ne 0 ]; then
				printf "${RED}${BOLD}$TAG $NAME: Unable to delete remote branch.${NORM}${NC}\n"
				printf "${RED}$ERROR${NC}\n"
			else
				echo "$TAG $NAME: Successfully deleted remote Git branch."
			fi
		else
			printf "${RED}${BOLD}$TAG $NAME: no remote Git branch exists.${NORM}${NC}\n"
		fi
	fi

	return 0

}

# FUNCTION
# DESCRIPTION: A function to show custom formatted Git logs.
# OPTIONS :
#			[directory] : (Required) The directory managed by Git
#							that a log should be obtained for.
#			-l | --limit : (Optional) Limit the number of log entries returned.
function git_log_func {

	if [ $# -lt 1 ]; then
		printf "${RED}${BOLD}$TAG Error! Invalid number of arguments.${NORM}${NC}\n"
		return 1
	fi

	# Parse the arguments
	case $# in
		1)
			DIR="$1"
			LIMIT=""
		;;
		3)
			DIR="$3"
			LIMIT="--max-count=$2"
		;;
	esac

	# Move shell to proper directory
	cd "$DIR"

	git log --pretty=format:'%ad | %H%n%s%n%b' --date=format:'%Y-%m-%d %H:%M:%S' $LIMIT
	return 0

}

# Test that there is a valid number of arguments
if [ $# -lt 2 ]; then
	printf "${RED}${BOLD}$TAG Error! Invalid number of arguments.${NORM}${NC}\n"
	exit 1
fi

# Set the MYVCS_PATH variable and source bin files
MYVCS_PATH="$1"
source "$MYVCS_PATH/myvcs-config.properties"
source "$MYVCS_PATH/bin/global.sh"

# Test the parameter to see which command to run
case $2 in
	backup)
		git_backup_func
	;;
	delete)
		#### TODO this only works because it's called as part of the delete.sh script. If called directly from myvcs, issues may arrise
		git_delete_func "${@:3}" 
	;;
	log)
		git_log_func "${@:3}"
	;;
	*)
		printf "${RED}${BOLD}$TAG Error! Invalid myvcs git command.${NORM}${NC}\n"
		exit 1
	;;
esac

if [ $? -ne 0 ]; then
	exit 1
else
	exit 0
fi

