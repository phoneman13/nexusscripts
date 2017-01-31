rem bat file to build boost - mainly, it sets up the path for you

set PATH=C:\mingw32\bin;%PATH%

cd C:\deps\boost_1_57_0\

bootstrap.bat mingw

b2 --build-type=complete --with-chrono --with-filesystem --with-program_options --with-system --with-thread toolset=gcc variant=release link=static threading=multi runtime-link=static stage

rem if b2 doesn't run, grab the command from this file and run it in the windows cmd.exe prompt
