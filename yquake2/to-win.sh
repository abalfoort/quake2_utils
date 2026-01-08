#/bin/bash

WINDIR="/media/WIN11/Users/arjen/Downloads/yquake2"

rm -rf $WINDIR
mkdir $WINDIR

cp -rvf 3zb2 $WINDIR/
cp -rvf ctf $WINDIR/
cp -rvf rogue $WINDIR/
cp -rvf xatrix $WINDIR/
cp -rvf yquake2 $WINDIR/
cp -rvf yquake2remaster $WINDIR/
cp -rvf zaero $WINDIR/
cp -rvf footsteps.pkz $WINDIR/
cp -rvf mingwbuild.sh $WINDIR/
cp -rvf *.bat $WINDIR/

echo
echo "Boot Windows > Downloads\yquake2 > build.bat"
