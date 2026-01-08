#!/bin/bash

BRANCH='master'

# The following dependencies were recommended but I only needed a few:
#apt install zlib1g-dev libcurl4-gnutls-dev libsdl2-dev libstb-dev libtinyobjloader-dev libvulkan-dev glslang-tools

# check version of libpipewire-0.3-dev
# Version 0.3.19-4 gave the following error:
# error: ‘PW_KEY_CONFIG_NAME’ was not declared in this scope
# Upgrade from backports to version 0.3.61-1~bpo11+1 fixed the error
apt install libpipewire-0.3-dev libvulkan-dev libsdl2-dev zlib1g-dev libssl-dev

if [ ! -d src ]; then
    git clone --recursive https://github.com/abalfoort/Q2RTX.git
    mv Q2RTX src
fi

cd src

# 11-12-2025: Nvidia discontinued Q2RTX - now standalone
#URL=$(git remote get-url upstream)
#if [ -z "$URL" ]; then
#    git remote add upstream https://github.com/NVIDIA/Q2RTX.git
#fi

# Backup the src directory
#rm -rf src.bak
#cp -rvf src src.bak
echo

git switch master
#git pull upstream master
git pull origin master
git submodule update --recursive
git push origin master
if [ "$BRANCH" != 'master' ]; then
    git switch $BRANCH
    git merge --no-ff master
fi
STATUS=$(git status)
echo $STATUS

if [[ "$STATUS" == *"git push"* ]]; then
    git push --set-upstream origin $BRANCH
    echo
    echo "Updated and pushed branche: $BRANCH"
elif [[ "$STATUS" != *"nothing to commit"* ]]; then
    echo
    echo "Fix branche: $BRANCH"
    echo '1. Manually fix conflicts: search for "<<<<" in src'
    echo "2. Build the project and fix errors."
    echo "3. cd src; git add ."
    echo '4. git commit -m "Sync with upstream"'
    echo "5. git push --set-upstream origin $BRANCH"
fi
