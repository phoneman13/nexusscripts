#!/bin/bash
# Setup deps for building nexus and bitcoin on windows
#   You need to download them to C:\deps first
#   For more info, check out 
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

#TODO: RESARCH USING THIS TO INSTALL MINGW FROM BAT FILE
#THEN, HAVE BAT FILE RUN THIS BAT FILE AND OTHERS
#TO FULLY COMPLETE INSTALL AND BUILD OF STUFF

cd /c/deps || mkdir -p /c/deps && cd /c/deps

##2. Download, unpack and build required dependencies.
##I'll save them in c:\deps folder.

##2.1 OpenSSL: http://www.openssl.org/source/openssl-1.0.1l.tar.gz
##From a MinGw shell (C:\MinGW\msys\1.0\msys.bat), unpack the source archive with tar (this will avoid symlink issues) then configure and make:
##Code:

cd /c/deps/

wget --no-check-certificate  http://www.openssl.org/source/openssl-1.0.1l.tar.gz

tar xvfz openssl-1.0.1l.tar.gz

cd openssl-1.0.1l

./Configure no-zlib no-shared no-dso no-krb5 no-camellia no-capieng no-cast no-cms no-dtls1 no-gost no-gmp no-heartbeats no-idea no-jpake no-md2 no-mdc2 no-rc5 no-rdrand no-rfc3779 no-rsax no-sctp no-seed no-sha0 no-static_engine no-whirlpool no-rc2 no-rc4 no-ssl2 no-ssl3 mingw

make

##2.2 Berkeley DB: http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz
##We'll use version 4.8 to preserve binary wallet compatibility.
##From a MinGW shell unpack the source archive, configure and make:
##Code:

wget  --no-check-certificate  http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz

cd /c/deps/

tar xvfz db-4.8.30.NC.tar.gz

cd db-4.8.30.NC/build_unix

../dist/configure --enable-mingw --enable-cxx --disable-shared --disable-replication

make

##2.3 Boost: http://sourceforge.net/projects/boost/files/boost/1.57.0/
##Download either the zip or the 7z archive, unpack boost inside your C:\deps folder, then bootstrap and compile from a Windows command prompt:
##Code:

wget --no-check-certificate https://sourceforge.net/projects/boost/files/boost/1.57.0/boost_1_57_0.zip/download

unzip boost_1_57_0.zip

# http://stackoverflow.com/questions/16967836/need-help-to-build-boost-from-source-for-mingw
# https://vijay.tech/articles/wiki/Programming/Cpp/Boost/BuildingBoostOnMinGw
#SOLVED#
### HAVE TO INSTALL BOOST FROM WINDOWS CMD PROMPT AND HAVE CORRECT PATH
### SEE WINDOWS BOOST INSTALL SHELL SCRIPT I MADE IN DEPS

cmd //c build-boost.bat

##2.4 Miniupnpc: http://miniupnp.free.fr/files/download.php?file=miniupnpc-1.9.20150206.tar.gz
##Unpack Miniupnpc to C:\deps, rename containing folder from "miniupnpc-1.9.20150206" to "miniupnpc" then from a Windows command prompt:
##Code:

wget --no-check-certificate http://miniupnp.free.fr/files/download.php?file=miniupnpc-1.9.20150206.tar.gz

tar -xvzf miniupnpc-1.9.20150206.tar.gz

cmd //c build-miniupnpc.bat

#2.5 protoc and libprotobuf:
#Download https://github.com/google/protobuf/releases/download/v2.6.1/protobuf-2.6.1.tar.gz
#Then from msys shell
#Code:

cd /c/deps

wget --no-check-certificate https://github.com/google/protobuf/releases/download/v2.6.1/protobuf-2.6.1.tar.gz

# IF YOU HAVE ISSUES WITH extracting PROTOBUF - USE WINDOWS GUI 7Z TO UNTAR THE .tar.gz file

ls protobuf-2.6.1 || tar -xvzf protobuf-2.6.1.tar.gz

cd /c/deps/protobuf-2.6.1

configure --disable-shared

make

#2.6 qrencode:
#Download and unpack http://download.sourceforge.net/libpng/libpng-1.6.16.tar.gz inside your deps folder then configure and make:
#Code:

wget --no-check-certificate http://download.sourceforge.net/libpng/libpng-1.6.16.tar.gz

ls libpng-1.6.16 ||  tar -xvzf libpng-1.6.16.tar.gz

cd /c/deps/libpng-1.6.16

configure --disable-shared

make

cp .libs/libpng16.a .libs/libpng.a

#Download and unpack http://fukuchi.org/works/qrencode/qrencode-3.4.4.tar.gz inside your deps folder then configure and make:
#Code:

cd /c/deps

wget --no-check-certificate http://fukuchi.org/works/qrencode/qrencode-3.4.4.tar.gz

ls qrencode-3.4.4 || tar -xvzf qrencode-3.4.4.tar.gz

cd /c/deps/qrencode-3.4.4

LIBS="../libpng-1.6.16/.libs/libpng.a ../../mingw32/i686-w64-mingw32/lib/libz.a" \

png_CFLAGS="-I../libpng-1.6.16" \

png_LIBS="-L../libpng-1.6.16/.libs" \

./configure --enable-static --disable-shared --without-tools

make

# QT TIME

cd /c/deps

wget --no-check-certificate http://download.qt-project.org/official_releases/qt/4.8/4.8.6/qt-everywhere-opensource-src-4.8.6.zip

unzip qt-everywhere-opensource-src-4.8.6.zip

cmd //c build-qt-qmake.bat

# Set up nexus.conf - necessary for daemon only

NCONFDIR=$APPDATA/Nexus
NCONFFILE=nexus.conf
NCONF=$NCONFDIR/$NCONFFILE

ls "$NCONFDIR" || mkdir -p $NCONFDIR

# (or when tried to start it on double click it
#  flashes an error about rpcpassword and closes)

#echo "rpcuser=rpcserver" > $NCONF
#echo "rpcpassword=somethingrandom2384y3uh34u" >> $NCONF
##echo "rpcallowip=127.0.0.1" >> $NCONF
#echo "daemon=1" >> $NCONF
#echo "server=1" >> $NCONF
#echo "debug=1" >> $NCONF
#echo "mining=1" >> $NCONF

# TODO Get the correct database
# http://nexusearth.com/bootstrap/LLD-Database/recent.rar
# http://nexusearth.com/bootstrap/Oracle-Database/recent.rar

# TODO unrar the file...
#dev@DESKTOP-0AOPV3V /c/Users/dev/AppData/Roaming/Nexus
#$ cp /c/Users/dev/Downloads/recent/* .

# Get ready for Nexus

cd /c/

ls Nexus || mkdir Nexus

cd Nexus

wget --no-check-certificate https://github.com/Nexusoft/Nexus/archive/0.2.0.5.zip

unzip 0.2.0.5

cd /c/deps

cmd //c qmake-nexus.bat

cd C:\\Nexus\\Nexus-0.2.0.5

# There are some errors in the Makefile.Release
#   attemt to fix them with sed

chmod 666 Makefile.Release

cp Makefile.Release .Makefile.Release.bk

sed s/openssl-1.0.1p/openssl-1.0.1l/g .Makefile.Release.bk > Makefile.Release

cp Makefile.Release .Makefile.Release.bk

sed s/1_55/1_57/g .Makefile.Release.bk > Makefile.Release

cd /c/deps

cmd //c build-nexus.bat

echo "Process Complete."

echo "THE TRUTH IS OUT THERE"
