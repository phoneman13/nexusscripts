rem bat file to build miniupnpc

set PATH=C:\mingw32\bin;%PATH%

cd C:\deps\miniupnpc

mingw32-make -f Makefile.mingw init upnpc-static

rem complete
