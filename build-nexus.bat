rem experimental bat file to build Nexus
rem this is the last step to compiling Nexus - hopefully

set PATH=C:\deps\qt-everywhere-opensource-src-4.8.6\bin;C:\deps\qt-everywhere-opensource-src-4.8.6;C:\mingw32\bin;%PATH%

cd C:\Nexus\Nexus-0.2.0.5

mingw32-make -f Makefile.Release

rem BEFORE you run nexus, you should download and install the boostrap database
rem this will save you a lot of time
rem see http://nexusearth.com/tutorials.html

rem PROCESS COMPLETE
