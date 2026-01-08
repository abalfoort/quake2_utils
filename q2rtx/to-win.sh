#!/bin/bash

WINDIR="/media/WIN11/Users/arjen/Downloads"

rm -rf $WINDIR/q2rtx
rsync -av --progress src/ $WINDIR/q2rtx --include=CMakeLists.txt --exclude=*{build,cmake-build-debug,q2rtx,q2rtxded} --exclude=*.{exe,dll,so,csv,menu,txt,cfg,bak} --exclude={3zb2/chctf,3zb2/chdtm,3zb2/models,3zb2/pics,3zb2/players,3zb2/sound} --exclude={baseq2/env,baseq2/maps,baseq2/materials,baseq2/models,baseq2/overrides,baseq2/pics,baseq2/shader_vkpt,baseq2/sound,baseq2/sprites,baseq2/textures} --exclude={rogue/maps,rogue/materials,rogue/models,rogue/pics,rogue/textures} --exclude={xatrix/maps,xatrix/materials,xatrix/models,xatrix/pics,xatrix/textures} --exclude={zaero/models,zaero/pics,zaero/sprites,zaero/textures}
#rsync -av --progress workingdir/q2rtx_media/ $WINDIR/q2rtx/baseq2
rsync -av --progress workingdir/_pak/ $WINDIR/q2rtx
rsync -av --progress q2rtx_media/ $WINDIR/q2rtx --include="*/" --include="*.pkz" --exclude="*"
cp -vf build.bat $WINDIR/
cp -vf q2rtx.bat $WINDIR/
#cp -rvf workingdir/_win_install/.vs $WINDIR/q2rtx/

echo
echo "Boot Windows > Downloads > build.bat"
