#!/usr/bin/env bash

# Secret Variable for GH ACT
# KERNEL_NAME | Your kernel name
# BRANCH | Your Kernel Branches
# LINUXVER | Latest Linux Version
# TG_TOKEN | Your Telegram Bot Token
# TG_CHAT_ID | Your Telegram Channel / Group Chat ID
# GH_USERNAME | Your Github Username
# GH_EMAIL | Your Github Email
# GH_TOKEN | Your Github Token ( repo & repo_hook )
# GH_PUSH_REPO_URL | Your Repository for store compiled Toolchain ( without https:// or www. ) ex. github.com/xyz-prjkt/xRageTC.git

# Configure
git config --global user.name $GH_USERNAME
git config --global user.email $GH_EMAIL

#clone kernel
git clone https://$GH_USERNAME:$GH_TOKEN@$GH_URL kernel -b $BRANCH
cd kernel

# Function to show an informational message
msg() {
    echo -e "\e[1;32m$*\e[0m"
}

err() {
    echo -e "\e[1;41m$*\e[0m"
}

# Set a directory
DIR="$(pwd ...)"

# Inlined function to post a message
export BOT_MSG_URL="https://api.telegram.org/bot$TG_TOKEN/sendMessage"
tg_post_msg() {
	curl -s -X POST "$BOT_MSG_URL" -d chat_id="$TG_CHAT_ID" \
	-d "disable_web_page_preview=true" \
	-d "parse_mode=html" \
	-d text="$1"

}
tg_post_build() {
	curl --progress-bar -F document=@"$1" "$BOT_MSG_URL" \
	-F chat_id="$TG_CHAT_ID"  \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=html" \
	-F caption="$3"
}

# Build Info
rel_date="$(date "+%Y%m%d")" # ISO 8601 format
rel_friendly_date="$(date "+%B %-d, %Y")" # "Month day, year" format
builder_commit="$(git rev-parse HEAD)"

# Send a notificaton to TG
tg_post_msg "<b>$KERNEL_NAME: Kernel Upstreamer Script Started</b>%0A<b>Date : </b><code>$rel_friendly_date</code>%0A<b>Linux Version : </b><code>$LINUXVER</code>%0A"

# Upstream msg
msg "$KERNEL_NAME: Upstreaming To $LINUXVER"
tg_post_msg "<b>$KERNEL_NAME: Upstreaming To $LINUXVER</b>"
TomTal=$(nproc)
if [[ ! -z "${2}" ]];then
    TomTal=$(($TomTal*2))
fi

# Upstream
git remote add upstream https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/
git fetch upstream $LINUXVER
git merge FETCH_HEAD

#Auto fix git merge/cherry-pick conflicts in files
#Revision 1

#Startup check
if [[ -e /tmp/conflicts ]]; then
		rm -f /tmp/conflicts
fi;

#HEADER
echo "--- GIT Conflict Resolver v1.0"
echo "-- Created by broodplank"
echo "- broodplank.net"
echo
echo "-> Checking for .git folder"
echo -n "Result: "

#Check for .git folder for behavior
if [[ -d ${PWD}/.git ]]; then

	echo "found, using git diff"
	echo
	echo "-> Finding conflicts..."
	git diff --name-only --diff-filter=U > /tmp/conflicts

else 

	echo "not found, using native tools"
	echo
	echo "-> Finding conflicts..."
	grep -l -H -r '<<<<<<< HEAD' ${PWD}/* | awk '!a[$0]++' > /tmp/conflicts

fi;


#Check if conflicts exist
if [[ `cat /tmp/conflicts` != "" ]]; then
	echo 
	echo "-> Conflicts found in files:"
	while read F  ; do
	        echo '- '$F
	done </tmp/conflicts
else
	echo "STOP, No conflicts found!"
fi;

#Start executing standard conflict resolve strategy
echo 
echo "-> Fixing conflicts..."
echo
while read G  ; do
		echo "--> Working on file: $G"
		echo "Removing text between HEAD and middle"
        sed -i -s '/<<<<<<< HEAD/,/=======/d' $G
        echo "Removing conflict footer"
		sed -i -s '/>>>>>>>/d' $G
		echo
done </tmp/conflicts

#Assume conflicts are actually solved
echo "--> Conflicts have been automatically fixed!"
echo
echo "Please note:"
echo "Although most of the conflicts can be resolved this way, It does not count for all conflicts."
echo "If you experience errors on compiling please review the changes made"
echo

#Stage commit?
if [[ -d ${PWD}/.git ]]; then
	echo "Would you like to stage the commit? () [Y/n]"
	echo -n ": "
	read choice
	if [[ $choice != "n" ]]; then
		git add .
		git commit
	fi


fi;
echo
echo "All done!"

tg_post_msg "<b>$KERNEL_NAME: Upstream Complete</b>%0A<b>Linux Version : </b><code>$LINUXVER</code>%0A<b>

# Push to GitHub
pushd kernel || exit
git checkout README.md 

git push --set-upstream https://$GH_USERNAME:$GH_TOKEN@$GH_URL
popd || exit
tg_post_msg "<b>$KERNEL_NAME: Toolchain pushed to <code>https://$GH_PUSH_REPO_URL</code></b>"
