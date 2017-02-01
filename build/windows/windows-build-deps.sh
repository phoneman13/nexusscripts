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

##2. Download, unpack and build required dependencies.
##I'll save them in c:\deps folder.

##2.1 OpenSSL: http://www.openssl.org/source/openssl-1.0.1l.tar.gz
##From a MinGw shell (C:\MinGW\msys\1.0\msys.bat), unpack the source archive with tar (this will avoid symlink issues) then configure and make:
##Code:
cd /c/deps/
tar xvfz openssl-1.0.1l.tar.gz
cd openssl-1.0.1l
./Configure no-zlib no-shared no-dso no-krb5 no-camellia no-capieng no-cast no-cms no-dtls1 no-gost no-gmp no-heartbeats no-idea no-jpake no-md2 no-mdc2 no-rc5 no-rdrand no-rfc3779 no-rsax no-sctp no-seed no-sha0 no-static_engine no-whirlpool no-rc2 no-rc4 no-ssl2 no-ssl3 mingw
make

##2.2 Berkeley DB: http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz
##We'll use version 4.8 to preserve binary wallet compatibility.
##From a MinGW shell unpack the source archive, configure and make:
##Code:
cd /c/deps/
tar xvfz db-4.8.30.NC.tar.gz
cd db-4.8.30.NC/build_unix
../dist/configure --enable-mingw --enable-cxx --disable-shared --disable-replication
make

##2.3 Boost: http://sourceforge.net/projects/boost/files/boost/1.57.0/
##Download either the zip or the 7z archive, unpack boost inside your C:\deps folder, then bootstrap and compile from a Windows command prompt:
##Code:

wget --no-check-certificate https://sourceforge.net/projects/boost/files/boost/1.57.0/boost_1_57_0.tar.bz2/download

bunzip2 boost_1_57_0.tar.bz2

cd /c/deps/boost_1_57_0

./bootstrap.sh mingw

b2 --build-type=complete --with-chrono --with-filesystem --with-program_options --with-system --with-thread toolset=gcc variant=release link=static threading=multi runtime-link=static stage

##This will compile the required boost libraries and put them into the stage folder (C:\deps\boost_1_57_0\stage).
##Note: make sure you don't use tarballs, as unix EOL markers can break batch files.

##2.4 Miniupnpc: http://miniupnp.free.fr/files/download.php?file=miniupnpc-1.9.20150206.tar.gz
##Unpack Miniupnpc to C:\deps, rename containing folder from "miniupnpc-1.9.20150206" to "miniupnpc" then from a Windows command prompt:
##Code:

tar -xvzf miniupnpc-1.9.20150206.tar.gz

cd /c/deps/miniupnpc

mingw32-make -f Makefile.mingw init upnpc-static

#2.5 protoc and libprotobuf:
#Download https://github.com/google/protobuf/releases/download/v2.6.1/protobuf-2.6.1.tar.gz
#Then from msys shell
#Code:

tar xvfz protobuf-2.6.1.tar.gz

cd /c/deps/protobuf-2.6.1

configure --disable-shared

make

#2.6 qrencode:
#Download and unpack http://download.sourceforge.net/libpng/libpng-1.6.16.tar.gz inside your deps folder then configure and make:
#Code:

cd /c/deps/libpng-1.6.16

configure --disable-shared

make

cp .libs/libpng16.a .libs/libpng.a

#Download and unpack http://fukuchi.org/works/qrencode/qrencode-3.4.4.tar.gz inside your deps folder then configure and make:
#Code:

cd /c/deps/qrencode-3.4.4

LIBS="../libpng-1.6.16/.libs/libpng.a ../../mingw32/i686-w64-mingw32/lib/libz.a" \

png_CFLAGS="-I../libpng-1.6.16" \

png_LIBS="-L../libpng-1.6.16/.libs" \

./configure --enable-static --disable-shared --without-tools

make

echo "Process Complete."

echo "THE TRUTH IS OUT THERE"
