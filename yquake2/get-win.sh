#/bin/bash

WINDIR="/media/WIN11/Users/arjen/Downloads/yquake2"

rm -rf release_windows release_windows_remaster
cp -vrf "$WINDIR/release_windows" ./
cp -vrf "$WINDIR/release_windows_remaster" ./
