#!/bin/sh
# NAME: testconfig.sh
# DESCRIPTION: A configuration script to run at the initialization of
#				of the main script. Its primary purpose is to initalize
#				key global values that all the scripts in this process
#				will need. THIS VERSION IS FOR TESTING ONLY

# Variables for the development directory locations
DEV_ROOT_PATH="/Users/craigmiller/TestDev"
DEV_MAIN_DIR="TestMain"
DEV_MAIN_PATH="$DEV_ROOT_PATH/$DEV_MAIN_DIR"

# Subversion Repository URLs
SVN_REPO_URL="https://subversion.assembla.com/svn/myvcs"
SVN_TRUNK="trunk"
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