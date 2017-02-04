rem experimental bat file to build Nexus
rem this is the last step to compiling Nexus - hopefully

set NEXUS_VERSION=%1

set PATH=C:\deps\qt-everywhere-opensource-src-4.8.6\bin;C:\deps\qt-everywhere-opensource-src-4.8.6;C:\mingw32\bin;%PATH%

cd C:\Nexus\Nexus-%NEXUS_VERSION%

rem make the qt version
mingw32-make -f Makefile.Release

rem make the non-qt version
mingw32-make -f makefile.mingw

rem BEFORE you run nexus, you should download and install the boostrap database
rem this will save you a lot of time
rem see http://nexusearth.com/tutorials.html

rem PROCESS COMPLETE