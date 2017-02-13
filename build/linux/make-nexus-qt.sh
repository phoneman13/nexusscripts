#!/bin/bash
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

# quick check - make sure we are in a nexus dir
ls nexus-qt.pro

if [ -x nexus-qt ]; then
	echo "The 'nexus-qt' binary appears to exist already. Skipping. Remove this file and run again if you want to re-build it."
else
	echo "Building Nexus Qt GUI Wallet"

	make clean || true

	rm Makefile || true

	qmake nexus-qt.pro "RELEASE=1" "USE_UPNP=-" "USE_LLD=1"
	#qmake nexus-qt.pro "RELEASE=1" "USE_LLD=1" "INCLUDEPATH+=/usr/include/qt5/QtWidgets"

	make -j$(nproc)

	echo "You should be able to run the Qt wallet with a command like $./nexus-qt"
fi
