#!/bin/sh
# SCRIPT
# NAME: git.sh
# DESCRIPTION: A script to conveniently execute certain complex operations
#				involving Git.

# Get shell script's directory and move shell there to execute config script
SCRIPT_DIR="$(dirname "${BASH_SOURCE}")"
cd $SCRIPT_DIR
source ./global.sh

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

# Get an array of all branch names from Git
BRANCHES=()
eval "$(git for-each-ref --shell --format='BRANCHES+=(%(refname))' refs/heads/)"
echo "$TAG Backing up all branches in bitbucket. This could take a few minutes, please wait."
# Iterate through all branches and push each one to bitbucket
for BRANCH in "${BRANCHES[@]}"; do
	BRANCH="$(awk -F/ '{print $3}' <<< $BRANCH)"
	ERROR=$(git push bitbucket "$BRANCH" 2>&1 >/dev/null) 

	if [ $? -ne 0 ]; then
		printf "${RED}$TAG $BRANCH: Failed to backup to bitbucket.${NC}\n"
		printf "${RED}$ERROR.${NC}\n"
	else
		printf "$TAG $BRANCH: Successfully backed up to bitbucket.\n"
		
	fi
done

exit 0