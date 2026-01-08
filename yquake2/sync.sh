#!/bin/bash

DIRS='yquake2remaster yquake2 xatrix rogue zaero ctf 3zb2'

for D in $DIRS; do
    if [ ! -d $D ]; then
        echo "Clone https://github.com/abalfoort/$D.git"
        git clone https://github.com/abalfoort/$D.git
    fi
    
    echo "Enter $D"
    cd $D
    
    URL=$(git remote get-url upstream 2>/dev/null)
    if [ -z "$URL" ]; then
        echo "Add upstream https://github.com/yquake2/$D.git"
        git remote add upstream https://github.com/yquake2/$D.git
    fi

    echo "Pull from upstream and push to origin"
    git switch master
    PULL=$(git pull upstream master)
    if [[ "$PULL" != *date. ]]; then
        git push origin master
    fi
    STATUS=$(git status)
    echo $STATUS

    if [[ "$STATUS" == *"git push"* ]]; then
        git push --set-upstream origin $BRANCH
        PUSH="$BRANCH $PUSH"
    elif [[ "$STATUS" != *"nothing to commit"* ]]; then
        FIX="$BRANCH $FIX"
    fi
    
    echo "========== $D done =========="
    
    cd ..
done

if [ -n "$PUSH" ]; then
    echo
    echo "Updated and pushed branches: $PUSH"
fi

if [ -n "$FIX" ]; then
    echo
    echo "Fix branches: $FIX"
    echo '1. Manually fix conflicts: search for "<<<<"'
    echo "2. Build the project and fix errors."
    echo "3. git add ."
    echo '4. git commit -m "Sync with upstream"'
    echo "5. git push --set-upstream origin master"
fi
