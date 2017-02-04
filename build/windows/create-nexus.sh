#!/bin/bash
# Script to build nexus-qt.exe after other prereqs complete
#  Usage: ./create-nexus.sh 0.2.2.2
#  Valid versions as of 2016-01: 0.2.2.2 and 0.2.0.5.
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

# If no version passed, use the default
[[ $NEXUS_VERSION = "" ]] && NEXUS_VERSION="${DEFAULT_VERSION}"

echo "${NEXUS_VERSION}"

cd /c/

ls Nexus || mkdir Nexus

cd Nexus

# Download the release zip file and unzip it.

ZIPFILE="${NEXUS_VERSION}"

if [ ! -s ${ZIPFILE} ]; then
	wget --no-check-certificate https://github.com/Nexusoft/Nexus/archive/${ZIPFILE}.zip
fi

if [ ! -d "Nexus-${NEXUS_VERSION}" ]; then
	unzip ${ZIPFILE}
fi

cd /c/deps

echo "Running qmake to prepare Nexus for building."

cmd //c qmake-nexus.bat ${NEXUS_VERSION}

cd C:\\Nexus\\Nexus-${NEXUS_VERSION}

echo "There may be some errors in the Makefile.Release, let's attemt to fix them with sed"

chmod 666 Makefile.Release

cp Makefile.Release .Makefile.Release.bk

sed s/openssl-1.0.1p/openssl-1.0.1l/g .Makefile.Release.bk > Makefile.Release

cp Makefile.Release .Makefile.Release.bk

sed s/1_55/1_57/g .Makefile.Release.bk > Makefile.Release

cd /c/deps

echo "Time to build Nexus!"

cmd //c build-nexus.bat ${NEXUS_VERSION}

echo "Verifying that Nexus.exe (command line version) exists"
ls C:\\Nexus\\Nexus-${NEXUS_VERSION}\\release\\Nexus.exe

echo "Verifying that nexus-qt.exe exists."

ls C:\\Nexus\\Nexus-${NEXUS_VERSION}\\release\\nexus-qt.exe

echo "You can find nexus in  C:\\Nexus\\Nexus-${NEXUS_VERSION}\\release\\nexus-qt"

echo "Process Complete"

# THE TRUTH IS OUT THERE