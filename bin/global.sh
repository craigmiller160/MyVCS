#!/bin/sh
# SCRIPT
# NAME: global.sh
# DESCRIPTION: A script with global values that should be run when each command
#				is initialized. The values here include constant variables and
#				functions.

# Variables for the development directory locations
DEV_ROOT_PATH="/Users/craigmiller/PilotFishDev"
DEV_MAIN_DIR="PilotFishMain"
DEV_MAIN_PATH="$DEV_ROOT_PATH/$DEV_MAIN_DIR"

# Subversion Repository URLs
SVN_REPO_URL="https://atlantis.pilotfish-net.com/repos/XCS"
SVN_TRUNK="development"
SVN_BRANCHES="branches"
SVN_TRUNK_URL="$SVN_REPO_URL/$SVN_TRUNK"
SVN_BRANCHES_URL="$SVN_REPO_URL/$SVN_BRANCHES"

# Git branch name variables
GIT_TRUNK="master"

# Output line start
TAG="[myvcs]:"

# Constant values for the commands
CREATE="create"
UPDATE="update"
COMMIT="commit"
INIT="init"
SVN="svn"

# Color values
RED='\033[0;31m'
NC='\033[0m'

# Style values
BOLD=$(tput bold)
NORM=$(tput sgr0)


# The URL value produced by SVN URL parsing function
SVN_URL=""

# FUNCTION
# NAME: svn_parse_url_func
# DESCRIPTION: A function to parse the provided value for an SVN URL. 
#				It converts conveinent names like "trunk" for the trunk,
#				or a simple branch name for the URL of that branch in the Branches
#				directory. This function does NOT validate whether or not the URL
#				exists, it simply builds what would be a valid URL if it did exist.
# OPTIONS:
#			[branch name] : (Required) The name of the branch, or "trunk" for trunk.
function svn_parse_url_func {
	# Test that the function has the correct number of arguments
	if [ $# -ne 1 ]; then
		printf "${RED}${BOLD}$TAG Error! Invalid number of parameters for svn_parse_url_func.${NORM}${NC}\n"
		return 1
	fi

	# Test the value of the parameter and assign the URL field its value
	case "$1" in
		http*)
			printf "${RED}${BOLD}$TAG Error! Pure URLs cannot be provided to svn_switch_func, only relative names of the trunk/branch to use.${NORM}${NC}\n"
			return 1
		;;
		trunk)
			SVN_URL="$SVN_TRUNK_URL"
		;;
		*)
			SVN_URL="$SVN_BRANCHES_URL/$1"
		;;
	esac

	return 0
}

# FUNCTION
# NAME: git_branch_exists_func
# DESCRIPTION: A function to test whether or not a git branch exists.
# OPTIONS:
#			[name] : (Required) The name of the branch to test the existence of.
function git_branch_exists_func {
	if [ $# -ne 1 ]; then
		printf "${RED}${BOLD}$TAG Error! Invalid number of arguments to git_branch_exists_func.${NORM}${NC}\n"
	fi


	git rev-parse --verify "$1" 1>/dev/null 2>/dev/null

	if [ $? -ne 0 ]; then
		printf "${RED}${BOLD}$TAG $1: Git branch doesn't exist.${NORM}${NC}\n"
		return 1
	fi

	return 0
}

# FUNCTION
# NAME: git_switch_fun
# DESCRIPTION: A function to handle switching Git branches. It performs the
#				operation in the background, and returns a successful or failed
#				status code and echos messages based on its results.
# OPTIONS:
#			[name] : (Required) The name of the branch to switch to.
function git_switch_func {
	# Test that the propper number of arguments was supplied to the function
	if [ $# -ne 1 ]; then
		printf "${RED}${BOLD}$TAG Error! Invalid number of arguments to git_switch_func.${NORM}${NC}\n"
		return 1
	fi

	# Test if the branch exists first, and end the function if it doesn't
	git_branch_exists_func $1
	if [ $? -ne 0 ]; then
		return 1
	fi

	GIT_CUR_BRANCH=$(git symbolic-ref HEAD | awk -F/ '{print $3}')
	if [ "$GIT_CUR_BRANCH" != "$1" ]; then
		echo "$TAG Switching Git Branch to [$1]."
		ERROR=$(git checkout "$1" 2>&1 >/dev/null)
		if [ $? -ne 0 ]; then
			printf "${RED}${BOLD}$TAG Error! Unable to switch Git branch to [$1].${NORM}${NC}\n"
			printf "${RED}$ERROR${NC}\n"
			return 1
		fi
	else
		echo "$TAG Directory already on Git Branch [$1]."
	fi

	return 0
}

# FUNCTION
# NAME: svn_branch_exists_func
# DESCRIPTION: This function tests whether or not an SVN branch already exists.
# OPTIONS:
#			[name] : (Required) the name of the branch to test the existence of.
#						Please note that "trunk" is not valid here, as "trunk" will
#						always exist.
function svn_branch_exists_func {
	# Test if the propper number of parameters have been supplied
	if [ $# -ne 1 ]; then
		printf "${RED}${BOLD}$TAG Error! Invalid number of parameters for svn_branch_exists_func.${NORM}${NC}\n"
	fi

	# Run the SVN parse url function, and if it returns an error code end this function with an error code
	svn_parse_url_func "$1"
	if [ $? -ne 0 ]; then
		return 1
	fi

	# Test for the existence of the branch
	svn info "$SVN_URL" 1>/dev/null 2>/dev/null
	if [ $? -ne 0 ]; then
		printf "${RED}${BOLD}$TAG Error! SVN Branch [$1] doesn't exist.${NORM}${NC}\n"
		return 1
	fi

	return 0
}

# FUNCTION
# NAME: svn_switch_fun
# DESCRIPTION: A function to handle switching SVN branches more conveniently, without
#				needing to input the full URL each time.
# OPTIONS:
#			[name] : (Required) The name of the branch to switch to. Providing "trunk" as a value
#						switches to the "trunk" of the repository.
function svn_switch_func {
	# If the number of arguments is invalid, throw an error
	if [ $# -lt 1 ] || [ $# -gt 2 ]; then
		printf "${RED}${BOLD}$TAG Error! Invalid number of parameters for svn_switch_func.${NORM}${NC}\n"
		return 1
	fi

	# The new URL to switch to
	NEW_URL=""
	# The name of the branch to switch to
	BRANCH_NAME=""

	# Get the URL and assign it to a value here. If the parsing function returns an error, return an error
	svn_parse_url_func "$1"
	if [ $? -ne 0 ]; then
		return 1
	else
		NEW_URL="$SVN_URL"
		BRANCH_NAME="$1"
	fi

	# Test if the branch exists, and if it doesn't end the function
	svn_branch_exists_func "$BRANCH_NAME"
	if [ $? != 0 ]; then
		return 1
	fi

	printf "$TAG $BRANCH_NAME: Switching to SVN branch."

	# Get the current URL and execute depending on if it's the same as the current one
	SVN_CUR_URL="$(svn info | awk '/^URL:/{print $2}')"
	if [ "$SVN_CUR_URL" != "$NEW_URL" ]; then
		# If the new URL and the current URL are different, execute the switch
		ERROR=$(svn switch "$NEW_URL" --accept postpone 2>&1 >/dev/null) &
		PID=$!
		while pkill -0 svn; do
			printf "."
			sleep 1
		done
		printf "\n"

		if [ $? -ne 0 ]; then
			printf "${RED}${BOLD}$TAG $BRANCH_NAME: Unable to switch to SVN Branch.${NORM}${NC}\n"
			printf "${RED}$ERROR${NC}\n"
			return 1
		else
			echo "$TAG $BRANCH_NAME: Successfully switched to SVN branch."
		fi
	else
		printf "\n"
		# If the new URl and the current URL are the same, update the directory if that option was chosen
		echo "$TAG $BRANCH_NAME: Directory is already on this SVN Branch."
	fi

	# Alert the user if there are any merge conflicts
	IFS=$'\n'
	CONFLICTS=($(svn status | grep '^[ADMRCXI\?\!~ ]\? *C\|>'))
	if [ "$CONFLICTS" != "" ]; then
		printf "${RED}${BOLD}$TAG Error! Merge conflicts exist and must be resolved.${NORM}${NC}\n"
		for i in "${CONFLICTS[@]}"; do
			printf "${RED}$i${NC}\n"
		done
	fi
	IFS=$' '

	return 0
}

# FUNCTION
# NAME: svn_copy_func
# DESCRIPTION: A convenience function for the SVN copy command. Rather than using
#				the standard SVN command, which requires providing full URL paths, 
#				this is designed to use abbreviated ones that are merely the names
#				of the branches involved. "trunk" indicates the trunk of the repository,
#				anything else is considered the name of a branch.
# OPTIONS:
#			[url1] : (Required) The first URL, the "from" URL. This is the repository that
#						is the source of the copy operation. It must already exist.
#			[url2] : (Required) The second URL, the "to" URL. This is the repository that
#						is the target of the copy operation. If it already exists, an error may
#						occur.
function svn_copy_func {
	# Test the number of arguments first before proceeding
	if [ $# -ne 2 ]; then
		printf "${RED}${BOLD}$TAG Error! svn_copy_func requires two valid path arguments.${NORM}${NC}\n"
		return 1
	fi

	# The two URL parameters
	URL1=""
	URL2=""

	# Parse the first URL parameter and assign it. If an error is returned from the parsing function, return an error
	svn_parse_url_func "$1"
	if [ $? -ne 0 ]; then
		return 1
	else
		URL1="$SVN_URL"
	fi

	# Parse the second URL parameter and assign it. If an error is returned from the parsing function, return an error
	svn_parse_url_func "$2"
	if [ $? -ne 0 ]; then
		return 1
	else
		URL2="$SVN_URL"
	fi

	# Test if the first branch, the source branch, exists before proceeding
	svn_branch_exists_func "$1"
	if [ $? -ne 0 ]; then
		return 1
	fi

	printf "$TAG $2: Creating SVN Branch"
	ERROR=$(svn copy "$URL1" "$URL2" -m "$2 - Branch created." 2>&1 >/dev/null) &
	PID=$!
	while pkill -0 svn; do
		printf "."
		sleep 1
	done
	printf "\n"

	if [ $? -ne 0 ]; then
		printf "${RED}${BOLD}$TAG $2: Failed to create branch.${NORM}${NC}\n"
		printf "${RED}$ERROR${NC}\n"
		return 1
	else
		echo "$TAG $2: Successfully created branch"
	fi

	return 0
}

# FUNCTION
# NAME: svn_merge_func
# DESCRIPTION: A convenience function for the SVN merge operation. This function
#				accepts arguments that are abbreviations for the URLs that the
#				standard SVN command requires, thus making it easier to use.
# OPTIONS:
#			[branch name] : (Required) The name of the SVN branch/trunk that is to be merged.
#					The name should be abreviated, with "trunk" meaning the trunk, and anything
#					else assumed to be the name of a branch that currently exists.
function svn_merge_func {
	# Test the number of arguments first
	if [ $# -ne 1 ]; then
		printf "${RED}${BOLD}$TAG Error! Invalid number of arguments to svn_merge_func.${NORM}${NC}\n"
		return 1
	fi

	URL=""

	# Parse the URL parameter. If it's invalid, return an error code. Otherwise, assign it
	svn_parse_url_func "$1"
	if [ $? -ne 0 ]; then
		return 1
	else
		URL="$SVN_URL"
	fi

	# Test if the branch exists. If it doesn't, return an error code.
	svn_branch_exists_func "$1"
	if [ $? -ne 0 ]; then
		return 1
	fi

	printf "$TAG Merging [$1] into working directory"
	ERROR=$(svn merge "$URL" "$DEV_MAIN_PATH" --accept postpone 2>&1 >/dev/null) &
	while pkill -0 svn; do
		printf "."
		sleep 1
	done
	printf "\n"

	if [ $? -ne 0 ]; then
		printf "${RED}${BOLD}$TAG Error! Something went wrong during SVN merge.${NORM}${NC}\n"
		printf "${RED}$ERROR${NC}\n"
		return 1
	fi

	#### TODO the regex test for "C" isn't good enough, because it gets words with C in it too

	# Alert the user if there are any merge conflicts
	IFS=$'\n'
	CONFLICTS=($(svn status | grep '^[ADMRCXI\?\!~ ]\? *C\|>'))
	if [ "$CONFLICTS" != "" ]; then
		printf "${RED}${BOLD}$TAG Error! Merge conflicts exist and must be resolved.${NORM}${NC}\n"
		for i in "${CONFLICTS[@]}"; do
			printf "${RED}$i${NC}\n"
		done
	fi
	IFS=$' '

	return 0
}