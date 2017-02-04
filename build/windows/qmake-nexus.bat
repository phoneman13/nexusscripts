rem experimental bat file to run qmake to prep to build Nexus

set NEXUS_VERSION=%1

set PATH=C:\deps\qt-everywhere-opensource-src-4.8.6\bin;C:\deps\qt-everywhere-opensource-src-4.8.6;C:\mingw32\bin;%PATH%

cd C:\Nexus\Nexus-%NEXUS_VERSION%

qmake "USE_UPNP=-" "USE_LLD=1" "RELEASE=1" nexus-qt.pro

rem next run build-nexus.bat