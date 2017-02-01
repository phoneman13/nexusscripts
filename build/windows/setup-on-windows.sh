#!/bin/bash
# Setup deps for building nexus and bitcoin on windows
# First, you need to install mingw
# Usage: ./setup-on-windows.sh 0.2.2.2
# Author: BryanGmyrek.com <bryangmyrekcom@gmail.com>
# License: GPL v2
# Enable error checking (snippet=basherror!)
set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   # set -u : exit the script if you try to use an uninitialised variable
set -o errexit   # set -e : exit the script if any statement returns a non-true return value
error() {
  echo "Error on or near line ${1}: ${2:-}; exiting with status ${3:-1}"
  exit "${3:-1}"
}
trap 'error ${LINENO}' ERR
set -v
set -x

# It's up to the user to pass a valid version.
DEFAULT_VERSION=0.2.2.2

# Get the version from the command line
NEXUS_VERSION=${1:-}
SETUP_NEXUS_CONF=${2:-}

# If no version passed, use the default
[[ $NEXUS_VERSION = "" ]] && NEXUS_VERSION="${DEFAULT_VERSION}"

echo "${NEXUS_VERSION}"

#TODO: RESARCH USING THIS TO INSTALL MINGW FROM BAT FILE
#THEN, HAVE BAT FILE RUN THIS BAT FILE AND OTHERS
#TO FULLY COMPLETE INSTALL AND BUILD OF STUFF

ls /c/deps || mkdir -p /c/deps

ls build-boost.bat && cp *.sh *.bat /c/deps

cd /c/deps

echo "DOWNLOADING DEPENDENCIES - THIS WILL TAKE A WHILE"

ls openssl-1.0.1l.tar.gz || wget --no-check-certificate  http://www.openssl.org/source/openssl-1.0.1l.tar.gz

ls db-4.8.30.NC.tar.gz || wget  --no-check-certificate  http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz

ls boost_1_57_0.zip || wget --no-check-certificate https://sourceforge.net/projects/boost/files/boost/1.57.0/boost_1_57_0.zip/download

ls miniupnpc-1.9.20150206.tar.gz || wget --no-check-certificate http://miniupnp.free.fr/files/download.php?file=miniupnpc-1.9.20150206.tar.gz

ls protobuf-2.6.1.tar.gz || wget --no-check-certificate https://github.com/google/protobuf/releases/download/v2.6.1/protobuf-2.6.1.tar.gz

ls libpng-1.6.16.tar.gz || wget --no-check-certificate http://download.sourceforge.net/libpng/libpng-1.6.16.tar.gz

ls qrencode-3.4.4.tar.gz || wget --no-check-certificate http://fukuchi.org/works/qrencode/qrencode-3.4.4.tar.gz

ls qt-everywhere-opensource-src-4.8.6.zip || wget --no-check-certificate http://download.qt-project.org/official_releases/qt/4.8/4.8.6/qt-everywhere-opensource-src-4.8.6.zip

##2. Download, unpack and build required dependencies.
##I'll save them in c:\deps folder.

echo "UNPACKING AND CONFIGURING DEPENDENCIES"

##2.1 OpenSSL: http://www.openssl.org/source/openssl-1.0.1l.tar.gz
##From a MinGw shell (C:\MinGW\msys\1.0\msys.bat), unpack the source archive with tar (this will avoid symlink issues) then configure and make:
##Code:

cd /c/deps/

if [ ! -d "openssl-1.0.1l" ]; then

	tar xvfz openssl-1.0.1l.tar.gz

	cd openssl-1.0.1l

	./Configure no-zlib no-shared no-dso no-krb5 no-camellia no-capieng no-cast no-cms no-dtls1 no-gost no-gmp no-heartbeats no-idea no-jpake no-md2 no-mdc2 no-rc5 no-rdrand no-rfc3779 no-rsax no-sctp no-seed no-sha0 no-static_engine no-whirlpool no-rc2 no-rc4 no-ssl2 no-ssl3 mingw

make

fi

##2.2 Berkeley DB: http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz
##We'll use version 4.8 to preserve binary wallet compatibility.
##From a MinGW shell unpack the source archive, configure and make:
##Code:

cd /c/deps/

if [ ! -d "db-4.8.30.NC/build_unix" ]; then

	tar xvfz db-4.8.30.NC.tar.gz

	cd db-4.8.30.NC/build_unix

	../dist/configure --enable-mingw --enable-cxx --disable-shared --disable-replication

	make

fi

##2.3 Boost: http://sourceforge.net/projects/boost/files/boost/1.57.0/
##Download either the zip or the 7z archive, unpack boost inside your C:\deps folder, then bootstrap and compile from a Windows command prompt:
##Code:

cd /c/deps/

if [ ! -d "boost_1_57_0" ]; then

	unzip boost_1_57_0.zip

# http://stackoverflow.com/questions/16967836/need-help-to-build-boost-from-source-for-mingw
# https://vijay.tech/articles/wiki/Programming/Cpp/Boost/BuildingBoostOnMinGw
#SOLVED#
### HAVE TO INSTALL BOOST FROM WINDOWS CMD PROMPT AND HAVE CORRECT PATH
### SEE WINDOWS BOOST INSTALL SHELL SCRIPT I MADE IN DEPS

	cmd //c build-boost.bat

fi

##2.4 Miniupnpc: http://miniupnp.free.fr/files/download.php?file=miniupnpc-1.9.20150206.tar.gz
##Unpack Miniupnpc to C:\deps, rename containing folder from "miniupnpc-1.9.20150206" to "miniupnpc" then from a Windows command prompt:
##Code:

cd /c/deps/

if [ ! -d "miniupnpc-1.9.20150206" ]; then

	# They called it a .tar.gz - but it's really just a .tar
	#   so - we only use tar -xvf below. If they ever fix it, use tar -xvzf instaead.
	#dev@DESKTOP-0AOPV3V /c/deps
    #$ file miniupnpc-1.9.20150206.tar.gz
    #miniupnpc-1.9.20150206.tar.gz: POSIX tar archive

	tar -xvf miniupnpc-1.9.20150206.tar.gz

	cmd //c build-miniupnpc.bat

fi

#2.5 protoc and libprotobuf:
#Download https://github.com/google/protobuf/releases/download/v2.6.1/protobuf-2.6.1.tar.gz
#Then from msys shell
#Code:

cd /c/deps

# IF YOU HAVE ISSUES WITH extracting PROTOBUF - USE WINDOWS GUI 7Z TO UNTAR THE .tar.gz file
#  There was something weird about it - it either wasn't actually a .tar.gz and was just a .tar or ...
#    trying to auto-correct it below ... 

if [ ! -d "protobuf-2.6.1" ]; then

	ls protobuf-2.6.1 || tar -xvzf protobuf-2.6.1.tar.gz || tar -xvf protobuf-2.6.1.tar.gz

	cd /c/deps/protobuf-2.6.1

	configure --disable-shared

	make

fi

#2.6 qrencode:
#Download and unpack http://download.sourceforge.net/libpng/libpng-1.6.16.tar.gz inside your deps folder then configure and make:
#Code:

cd /c/deps

if [ ! -d "libpng-1.6.16" ]; then

	ls libpng-1.6.16 ||  tar -xvzf libpng-1.6.16.tar.gz

	cd /c/deps/libpng-1.6.16

	configure --disable-shared

	make

	cp .libs/libpng16.a .libs/libpng.a

fi


#Download and unpack http://fukuchi.org/works/qrencode/qrencode-3.4.4.tar.gz inside your deps folder then configure and make:
#Code:

cd /c/deps

if [ ! -d "qrencode-3.4.4" ]; then

	ls qrencode-3.4.4 || tar -xvzf qrencode-3.4.4.tar.gz

	cd /c/deps/qrencode-3.4.4

	LIBS="../libpng-1.6.16/.libs/libpng.a ../../mingw32/i686-w64-mingw32/lib/libz.a" \

	png_CFLAGS="-I../libpng-1.6.16" \

	png_LIBS="-L../libpng-1.6.16/.libs" \

	./configure --enable-static --disable-shared --without-tools

	make

fi

# QT TIME

cd /c/deps

if [ ! -d "qt-everywhere-opensource-src-4.8.6" ]; then

	unzip qt-everywhere-opensource-src-4.8.6.zip

	cmd //c build-qt-qmake.bat

fi

if [ ${SETUP_NEXUS_CONF} -eq 1 ]; then

	# Set up nexus.conf - necessary for daemon only

	NCONFDIR=$APPDATA/Nexus
	NCONFFILE=nexus.conf
	NCONF=$NCONFDIR/$NCONFFILE

	ls "$NCONFDIR" || mkdir -p $NCONFDIR

	# (or when tried to start it on double click it
	#  flashes an error about rpcpassword and closes)

	echo "rpcuser=rpcserver" > $NCONF
	echo "rpcpassword=YOUSHOULDREALLYCHANGETHIS4785Y4H" >> $NCONF
	echo "rpcallowip=127.0.0.1" >> $NCONF
	echo "daemon=1" >> $NCONF
	echo "server=1" >> $NCONF
	echo "debug=1" >> $NCONF
	echo "mining=1" >> $NCONF

fi

# TODO Get the correct database
# http://nexusearth.com/bootstrap/LLD-Database/recent.rar
# http://nexusearth.com/bootstrap/Oracle-Database/recent.rar

# Get ready for Nexus

./create-nexus.sh ${NEXUS_VERSION}

echo "Process Complete."

echo "THE TRUTH IS OUT THERE"