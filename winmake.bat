@echo off
rem
rem 4cade Makefile for Windows
rem assembles source code, optionally builds a disk image
rem
rem a qkumba monstrosity from 2018-10-29
rem

setlocal enabledelayedexpansion
set DISK=4cade.hdv
set VOLUME=TOTAL.REPLAY

rem third-party tools required to build (must be in path)
rem https://sourceforge.net/projects/acme-crossass/
set ACME=acme
rem https://bitbucket.org/magli143/exomizer/wiki/Home
set EXOMIZER=exomizer mem -q -P23 -lnone
rem https://www.brutaldeluxe.fr/products/crossdevtools/cadius/
rem https://github.com/mach-kernel/cadius
set CADIUS=cadius
rem https://github.com/
set GIT=git


if "%1" equ "dsk" (
call :index
call :asmproboot
call :asmlauncher
1>nul copy /y res\blank.hdv "build\%DISK%" >>build\log
1>nul copy /y res\_FileInformation.txt build\ >>build\log
%CADIUS% ADDFILE "build\%DISK%" "/%VOLUME%/" "build\LAUNCHER.SYSTEM" >>build\log
1>nul copy /y "res\PREFS.CONF" "build" >>build\log
cscript /nologo bin\padto.js 512 build\PREFS.CONF
rem
rem create _FileInformation.txt files for subdirectories
rem
cscript /nologo bin\buildfileinfo.js res\ICONS "CA" "0000" >>build/log
cscript /nologo bin\buildfileinfo.js build\FX "06" "6000" >>build/log
cscript /nologo bin\buildfileinfo.js build\PRELAUNCH "06" "0106" >>build/log
rem
rem add everything to the disk
rem
echo|set/p="adding files..."
%CADIUS% ADDFILE "build\%DISK%" "/%VOLUME%/" "build\TOTAL.DATA" >>build\log
%CADIUS% ADDFILE "build\%DISK%" "/%VOLUME%/" "build\PREFS.CONF" >>build\log
%CADIUS% ADDFILE "build\%DISK%" "/%VOLUME%/" "res\Finder.Data" >>build\log
%CADIUS% ADDFILE "build\%DISK%" "/%VOLUME%/" "res\Finder.Root" >>build\log
%CADIUS% ADDFOLDER "build\%DISK%" "/%VOLUME%/DEMO" "res\DEMO" >>build\log
%CADIUS% ADDFOLDER "build\%DISK%" "/%VOLUME%/TITLE.ANIMATED" "res\TITLE.ANIMATED" >>build\log
%CADIUS% ADDFOLDER "build\%DISK%" "/%VOLUME%/ICONS" "res\ICONS" >>build\log
%CADIUS% ADDFOLDER "build\%DISK%" "/%VOLUME%/FX/" "build\FX" >>build\log
%CADIUS% ADDFOLDER "build\%DISK%" "/%VOLUME%/PRELAUNCH/" "build\PRELAUNCH" >>build\log
%CADIUS% RENAMEFILE "build\%DISK%" "/%VOLUME%/DEMO/SPCARTOON.11" "SPCARTOON.1." >>build\log
%CADIUS% RENAMEFILE "build\%DISK%" "/%VOLUME%/DEMO/SPCARTOON.22" "SPCARTOON.2." >>build\log
%CADIUS% RENAMEFILE "build\%DISK%" "/%VOLUME%/DEMO/SPCARTOON.33" "SPCARTOON.3." >>build\log
%CADIUS% RENAMEFILE "build\%DISK%" "/%VOLUME%/DEMO/SPCARTOON.44" "SPCARTOON.4." >>build\log
%CADIUS% RENAMEFILE "build\%DISK%" "/%VOLUME%/DEMO/SPCARTOON.55" "SPCARTOON.5." >>build\log
%CADIUS% RENAMEFILE "build\%DISK%" "/%VOLUME%/DEMO/SPCARTOON.66" "SPCARTOON.6." >>build\log
for %%q in (res\dsk\*.po) do %CADIUS% EXTRACTVOLUME "%%q" build\X\ >>build\log
1>nul 2>nul del /s build\X\.DS_Store build\X\PRODOS build\X\LOADER.SYSTEM
%CADIUS% CREATEFOLDER "build\%DISK%" "/%VOLUME%/X/" >>build\log
%CADIUS% ADDFOLDER "build\%DISK%" "/%VOLUME%/X" "build\X" >>build\log
cscript /nologo bin\changebootloader.js "build\%DISK%" build\proboothd
echo done
goto :EOF
)

if "%1" equ "index" (
call index
goto :EOF
)

if "%1" equ "clean" (
echo y|1>nul 2>nul rd build /s
goto :EOF
)

if "%1" equ "compress" (
call :compress
goto :EOF
)

echo usage: %0 clean / asm / dsk
goto :EOF

:index
call :md
call :asmfx
call :asmprelaunch
rem
rem precompute binary data structure for mega-attract mode configuration file
rem
cscript /nologo bin\buildokvs.js res\ATTRACT.CONF build\ATTRACT.IDX >>build\log
rem
rem precompute binary data structure and substitute special characters
rem in game help and other all-text pages
rem
cscript /nologo bin\converthelp.js res\HELPTEXT build\HELPTEXT >>build\log
cscript /nologo bin\converthelp.js res\CREDITS build\CREDITS >>build\log
echo|set/p="converting gamehelp..."
for %%q in (res\GAMEHELP\*) do cscript /nologo bin\converthelp.js %%q build\GAMEHELP\%%~nxq >>build\log
echo done
rem
rem create a list of all game filenames, without metadata or display names, sorted by game filename
rem
cscript /nologo bin\makesorted.js
cscript /nologo bin\builddisplaynames.js
rem
rem precompute indexed files for prelaunch
rem note: prelaunch must be first in TOTAL.DATA due to a hack in LoadStandardPrelaunch
rem note 2: these can not be padded because they are loaded at $0106 and padding would clobber the stack
rem
echo|set/p="indexing prelaunch..."
1>nul copy /y nul build\TOTAL.DATA
cscript /nologo bin\buildpre.js build\PRELAUNCH.INDEXED build\PRELAUNCH.IDX build\TOTAL.DATA >>build\log
echo done
rem
rem precompute indexed files for HGR & DHGR titles
rem note: these are not padded because they are all an exact block-multiple anyway
rem
echo|set/p="indexing titles..."
cscript /nologo bin\padto.js 512 build\TOTAL.DATA
cscript /nologo bin\buildss.js res\TITLE.HGR build\TITLE.IDX build\HGR.TITLES.LOG build\TOTAL.DATA build\TOTAL.DATA >>build\log
cscript /nologo bin\buildss.js res\TITLE.DHGR build\DTITLE.IDX build\DHGR.TITLES.LOG build\TOTAL.DATA build\TOTAL.DATA >>build\log
cscript /nologo bin\addfile.js res\COVER src\index\res.cover.idx.a
cscript /nologo bin\addfile.js res\TITLE src\index\res.title.idx.a
cscript /nologo bin\addfile.js res\HELP src\index\res.help.idx.a
echo done
rem
rem precompute indexed files for game help
rem note: these can be padded because they're loaded into $800 at a time when $800..$1FFF is clobber-able
rem
echo|set/p="indexing gamehelp..."
cscript /nologo bin\makesorted.js
cscript /nologo bin\buildpre.js build\GAMEHELP build\GAMEHELP.IDX build\TOTAL.DATA pad >>build\log
echo done
rem
rem precompute indexed files for slideshows
rem note: these can be padded because they're loaded into $800 at a time when $800..$1FFF is clobber-able
rem
echo|set/p="indexing slideshows..."
for %%q in (res\SS\*) do (
  set _ss=%%~nxq
  set _ss=!_ss:~0,3!
  if !_ss!==ACT (
    cscript /nologo bin\buildslideshow.js %%q build\SS\%%~nxq -d >>build\log
  ) else (
    cscript /nologo bin\buildslideshow.js %%q build\SS\%%~nxq >>build\log
  )
)
cscript /nologo bin\buildss.js build\SS build\SLIDESHOW.IDX nul build\TOTAL.DATA nul pad >>build\log
for %%q in (res\ATTRACT\*) do cscript /nologo bin\buildokvs.js %%q build\ATTRACT\%%~nxq >>build\log
cscript /nologo bin\buildss.js build\ATTRACT build\MINIATTRACT.IDX nul build\TOTAL.DATA nul pad >>build\log
echo done
rem
rem precompute indexed files for graphic effects
rem note: these can be padded because they're loaded into $6000 at a time when $6000..$BEFF is clobber-able
rem
echo|set/p="indexing fx..."
cscript /nologo bin\buildfx.js res\FX.CONF build\FX.IDX build\TOTAL.DATA build\FX.INDEXED >>build\log
cscript /nologo bin\buildfx.js res\DFX.CONF build\DFX.IDX build\TOTAL.DATA build\FX.INDEXED >>build\log
cscript /nologo bin\buildfx.js res\SFX.CONF build\SFX.IDX build\TOTAL.DATA build\FX.INDEXED >>build\log
echo done
rem
rem precompute indexed files for HGR & DHGR action screenshots
rem note: these can not be padded because they are compressed and the decompressor needs the exact size
rem
echo|set/p="indexing (d)hgr action..."
1>nul copy /y nul build\ACTIONHGR0
1>nul copy /y nul build\ACTIONHGR1
1>nul copy /y nul build\ACTIONHGR2
1>nul copy /y nul build\ACTIONHGR3
1>nul copy /y nul build\ACTIONHGR4
1>nul copy /y nul build\ACTIONHGR5
1>nul copy /y nul build\ACTIONHGR6
1>nul copy /y nul build\ACTIONDHGR
for %%q in (res\ACTION.HGR\A* res\ACTION.HGR\B* res\ACTION.HGR\C* res\ACTION.HGR\D*) do 1>nul >>build\ACTIONHGR0 echo %%q
for %%q in (res\ACTION.HGR\E* res\ACTION.HGR\F* res\ACTION.HGR\G* res\ACTION.HGR\H*) do 1>nul >>build\ACTIONHGR1 echo %%q
for %%q in (res\ACTION.HGR\I* res\ACTION.HGR\J* res\ACTION.HGR\K* res\ACTION.HGR\L*) do 1>nul >>build\ACTIONHGR2 echo %%q
for %%q in (res\ACTION.HGR\M* res\ACTION.HGR\N* res\ACTION.HGR\O* res\ACTION.HGR\P*) do 1>nul >>build\ACTIONHGR3 echo %%q
for %%q in (res\ACTION.HGR\Q* res\ACTION.HGR\R* res\ACTION.HGR\S* res\ACTION.HGR\T*) do 1>nul >>build\ACTIONHGR4 echo %%q
for %%q in (res\ACTION.HGR\U* res\ACTION.HGR\V* res\ACTION.HGR\W* res\ACTION.HGR\X*) do 1>nul >>build\ACTIONHGR5 echo %%q
for %%q in (res\ACTION.HGR\Y* res\ACTION.HGR\Z*) do 1>nul >>build\ACTIONHGR6 echo %%q
for %%q in (res\ACTION.DHGR\*) do 1>nul >>build\ACTIONDHGR echo %%q
cscript /nologo bin\buildss.js build\ACTIONHGR0* build\HGR0.IDX nul build\TOTAL.DATA nul >>build\log
cscript /nologo bin\buildss.js build\ACTIONHGR1* build\HGR1.IDX nul build\TOTAL.DATA build\TOTAL.DATA >>build\log
cscript /nologo bin\buildss.js build\ACTIONHGR2* build\HGR2.IDX nul build\TOTAL.DATA build\TOTAL.DATA >>build\log
cscript /nologo bin\buildss.js build\ACTIONHGR3* build\HGR3.IDX nul build\TOTAL.DATA build\TOTAL.DATA >>build\log
cscript /nologo bin\buildss.js build\ACTIONHGR4* build\HGR4.IDX nul build\TOTAL.DATA build\TOTAL.DATA >>build\log
cscript /nologo bin\buildss.js build\ACTIONHGR5* build\HGR5.IDX nul build\TOTAL.DATA build\TOTAL.DATA >>build\log
cscript /nologo bin\buildss.js build\ACTIONHGR6* build\HGR6.IDX nul build\TOTAL.DATA build\TOTAL.DATA >>build\log
cscript /nologo bin\buildss.js build\ACTIONDHGR* build\DHGR.IDX nul build\TOTAL.DATA build\TOTAL.DATA >>build\log
echo done
rem precompute indexed files for GR and DGR action screenshots
rem note: these can be padded because they are not compressed
rem
echo|set/p="indexing (d)gr action..."
1>nul copy /y nul build\ACTIONGR
1>nul copy /y nul build\ACTIONDGR
for %%q in (res\ACTION.GR\*) do 1>nul >>build\ACTIONGR echo %%q
for %%q in (res\ACTION.DGR\*) do 1>nul >>build\ACTIONDGR echo %%q
cscript /nologo bin\buildss.js build\ACTIONGR* build\GR.IDX nul build\TOTAL.DATA build\TOTAL.DATA pad >>build\log
cscript /nologo bin\buildss.js build\ACTIONDGR* build\DGR.IDX nul build\TOTAL.DATA build\TOTAL.DATA pad >>build\log
echo done
rem
rem precompute indexed files for SHR artwork
rem note: these can not be padded because they are compressed and the decompressor needs the exact size
rem
echo|set/p="indexing shr..."
cscript /nologo bin\buildss.js res\ARTWORK.SHR build\ARTWORK.IDX nul build\TOTAL.DATA nul >>build\log
echo done
rem
rem create search indexes for each variation of (game-requires-joystick) X (game-requires-128K)
rem in the form of OKVS data structures, plus game counts in the form of source files
rem
echo|set/p="indexing search..."
cscript /nologo bin\buildsearch.js "00" src\index\count00.a build\SEARCH00.IDX
cscript /nologo bin\buildsearch.js "0" src\index\count01.a build\SEARCH01.IDX
cscript /nologo bin\buildsearch.js ".0" src\index\count10.a build\SEARCH10.IDX
cscript /nologo bin\buildsearch.js "." src\index\count11.a build\SEARCH11.IDX
echo done
rem
rem add IDX files to the combined index file and generate
rem the index records that callers use to reference them
rem
echo|set/p="preparing index file..."
cscript /nologo bin\addfile.js build\SEARCH00.IDX src\index\search00.idx.a
cscript /nologo bin\addfile.js res\CACHE00.IDX src\index\cache00.idx.a
cscript /nologo bin\addfile.js build\SEARCH01.IDX src\index\search01.idx.a
cscript /nologo bin\addfile.js res\CACHE01.IDX src\index\cache01.idx.a
cscript /nologo bin\addfile.js build\SEARCH10.IDX src\index\search10.idx.a
cscript /nologo bin\addfile.js res\CACHE10.IDX src\index\cache10.idx.a
cscript /nologo bin\addfile.js build\SEARCH11.IDX src\index\search11.idx.a
cscript /nologo bin\addfile.js res\CACHE11.IDX src\index\cache11.idx.a
cscript /nologo bin\addfile.js build\PRELAUNCH.IDX src\index\prelaunch.idx.a
cscript /nologo bin\addfile.js build\ATTRACT.IDX src\index\attract.idx.a
cscript /nologo bin\addfile.js build\FX.IDX src\index\fx.idx.a
cscript /nologo bin\addfile.js build\DFX.IDX src\index\dfx.idx.a
cscript /nologo bin\addfile.js build\SFX.IDX src\index\sfx.idx.a
cscript /nologo bin\addfile.js build\GAMEHELP.IDX src\index\gamehelp.idx.a
cscript /nologo bin\addfile.js build\SLIDESHOW.IDX src\index\slideshow.idx.a
cscript /nologo bin\addfile.js build\MINIATTRACT.IDX src\index\miniattract.idx.a
cscript /nologo bin\addfile.js build\TITLE.IDX src\index\title.idx.a
cscript /nologo bin\addfile.js build\DTITLE.IDX src\index\dtitle.idx.a
cscript /nologo bin\addfile.js build\HGR0.IDX src\index\hgr0.idx.a
cscript /nologo bin\addfile.js build\HGR1.IDX src\index\hgr1.idx.a
cscript /nologo bin\addfile.js build\HGR2.IDX src\index\hgr2.idx.a
cscript /nologo bin\addfile.js build\HGR3.IDX src\index\hgr3.idx.a
cscript /nologo bin\addfile.js build\HGR4.IDX src\index\hgr4.idx.a
cscript /nologo bin\addfile.js build\HGR5.IDX src\index\hgr5.idx.a
cscript /nologo bin\addfile.js build\HGR6.IDX src\index\hgr6.idx.a
cscript /nologo bin\addfile.js build\DHGR.IDX src\index\dhgr.idx.a
cscript /nologo bin\addfile.js build\GR.IDX src\index\gr.idx.a
cscript /nologo bin\addfile.js build\DGR.IDX src\index\dgr.idx.a
cscript /nologo bin\addfile.js build\ARTWORK.IDX src\index\artwork.idx.a
rem
rem add additional miscellaneous files
rem
cscript /nologo bin\addfile.js build\COVERFADE src\index\coverfade.idx.a
cscript /nologo bin\addfile.js build\GR.FIZZLE src\index\gr.fizzle.idx.a
cscript /nologo bin\addfile.js build\DGR.FIZZLE src\index\dgr.fizzle.idx.a
cscript /nologo bin\addfile.js build\HELPTEXT src\index\helptext.idx.a
cscript /nologo bin\addfile.js build\CREDITS src\index\credits.idx.a
cscript /nologo bin\addfile.js res\DECRUNCH src\index\decrunch.idx.a
cscript /nologo bin\addfile.js res\JOYSTICK src\index\joystick.idx.a
echo done
goto :EOF

:md
2>nul md build
2>nul md build\X
2>nul md build\FX.INDEXED
2>nul md build\FX
2>nul md build\PRELAUNCH.INDEXED
2>nul md build\PRELAUNCH
2>nul md build\ATTRACT
2>nul md build\SS
2>nul md build\GAMEHELP
1>nul copy nul build\log
goto :EOF

:asmlauncher
1>build\buildnum.log git rev-list --count HEAD
for /f "tokens=*" %%q in (build\buildnum.log) do set _build=%%q
2>build\relbase.log %ACME% -DBUILDNUMBER=%_build% src\4cade.a
for /f "tokens=*" %%q in (build\relbase.log) do set _make=%%q
%ACME% -DBUILDNUMBER=%_build% -DRELBASE=$!_make:~-5,4! -r build\4cade.lst src\4cade.a
goto :EOF

:asmfx
echo|set/p="building fx..."
for %%q in (src\fx\*.a) do (
  for /f "tokens=* usebackq" %%k in (`find "^!to" %%q`) do set _to=%%k
  set _to=!_to:~0,1!
  if !_to!==t %ACME% %%q
)
echo done
goto :EOF

:asmprelaunch
echo|set/p="building prelaunch..."
for %%q in (src\prelaunch\*.a) do (
  for /f "tokens=* usebackq" %%k in (`find "^!to" %%q`) do set _to=%%k
  set _to=!_to:~0,1!
  if !_to!==t %ACME% %%q
)
echo done
goto :EOF

:asmproboot
%ACME% -r build\proboothd.lst src\proboothd\proboothd.a >> build\log
goto :EOF

:compress
for %%q in (res\action.dhgr.uncompressed\*) do if not exist res\action.dhgr\%%~nxq %EXOMIZER% res\action.dhgr.uncompressed\%%~nxq@0x4000 -o res\action.hgr\%%~nxq
for %%q in (res\action.hgr.uncompressed\*) do if not exist res\action.hgr\%%~nxq %EXOMIZER% res\action.hgr.uncompressed\%%~nxq@0x4000 -o res\action.hgr\%%~nxq
for %%q in (res\artwork.shr.uncompressed\*) do if not exist res\artwork.shr\%%~nxq %EXOMIZER% res\artwork.shr.uncompressed\%%~nxq@0x2000 -o res\artwork.shr\%%~nxq
