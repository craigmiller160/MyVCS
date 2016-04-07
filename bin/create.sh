#!/bin/bash
# SCRIPT
# NAME: create.sh
# DESCRIPTION: This is the script that handles the CREATE command. This command
#				creates a new branch to work on the project. It updates the Git
#				master branch to the newest version of Trunk, creates a new Git
#				branch with the provided name, creates a new directory of the
#				same name, and configures both Git and the directory so that work
#				can quickly begin. It will also be able to create a new branch in
#				Subversion as well.
# OPTIONS:
#			[branch name] : (Required) The name of the branch to create, both in Git
#									and in SVN.

# The name of the branch to create.
NAME=""

# Test that there is at least two parameters for this command.
# Param $2 will always be the command name, so there need to be
#   at least two total params for this script to be able to run
if [ $# -lt 2 ]; then
	printf "${RED}${BOLD}$TAG Error! Invalid number of parameters supplied to create command.${NORM}${NC}\n"
	exit 1
fi



# Set the MYVCS_PATH variable and source bin files
MYVCS_PATH="$1"
source "$MYVCS_PATH/myvcs-config.properties"
source "$MYVCS_PATH/bin/global.sh"

echo "$DEV_MAIN_PATH"

# If there is only one parameter (two total, including the command),
#   then that parameter MUST be the name of the branch. If it is another
#   parameter value, then an error will be thrown.
if [ $# -eq 2 ]; then
	case "$2" in
		# If it has a parameter prefix (-) or (--), then it is an invalid argument
		-* | --*)
			printf "${RED}${BOLD}$TAG Error! No valid branch name supplied. Branch names cannot start with parameter prefixes (-) and (--).${NORM}${NC}\n"
			exit 1
		;;
		# Otherwise, set it as the branch name variable
		*)
			NAME="$2"
		;;
	esac
fi

# Output what the command is going to do
echo "$TAG Creating new branch [$NAME] on local machine."

# Change directory to the main dev directory
cd "$DEV_MAIN_PATH"

# Ensure that the Git Branch is on trunk
git_switch_func "master"
if [ $? -ne 0 ]; then
	return 1
fi

# Ensure that the SVN Branch is on trunk
svn_switch_func "trunk"
if [ $? -ne 0 ]; then
	return 1
fi

# Test if there are any files that SVN sees having changes, and revert them
#   Git Trunk should always be a pure version of SVN's Trunk, with no files differing
if [ ! -z "$(svn status)" ]; then
	echo "$TAG Resolving conflicts with SVN files on trunk."
	svn revert -R . 1>/dev/null 2>/dev/null &
	PID=$!
	while pkill -0 svn; do
		printf "."
		sleep 1
	done
	printf "\n"
fi

# Test if there are any changes that need to be committed to the Git Trunk
if [ ! -z "$(git status --porcelain)" ]; then
	echo "$TAG Commiting to Git resolved conflicts with files on SVN trunk."
	git add . 1>/dev/null 2>/dev/null
	git commit -m "Resolving conflicts with SVN Trunk. `date +%Y-%m-%d::%H:%M:%S`" 1>/dev/null 2>/dev/null
fi

# Create a Git branch for the new directory
echo "$TAG Creating Git branch [$NAME]."
git branch "$NAME" 1>/dev/null 2>/dev/null

# Create a directory for the branch that is a sister for the main Trunk directory
echo "$TAG Creating directory for branch [$NAME]."
cd "$DEV_ROOT_PATH"
mkdir "$NAME"

# Start Git in the new directory and pull the files from the Git branch into it
printf "$TAG Initializing and pulling Git branch into new directory. This may take a few moments."
cd "$DEV_ROOT_PATH/$NAME"
git init 1>/dev/null 2>/dev/null
git remote add origin "$DEV_MAIN_PATH" 1>/dev/null 2>/dev/null
git pull origin "$NAME" 1>/dev/null 2>/dev/null &
PID=$!
while pkill -0 git; do
	printf "."
	sleep 1
done
printf "\n"

git branch -u origin/"$NAME" 1>/dev/null 2>/dev/null

# Copy workspace.xml & vcs.xml files into .idea directory
echo "$TAG Configuring IntelliJ preferences"
git update-index --assume-unchanged "$DEV_ROOT_PATH/$NAME/.idea/vcs.xml"
rm -f "$DEV_ROOT_PATH/$NAME/.idea/vcs.xml"
cp "$MYVCS_PATH/bin/vcs.xml" "$DEV_ROOT_PATH/$NAME/.idea"
cp "$MYVCS_PATH/bin/workspace.xml" "$DEV_ROOT_PATH/$NAME/.idea"

echo "$TAG New local Git branch & directory set up for [$NAME]."
exit 0

