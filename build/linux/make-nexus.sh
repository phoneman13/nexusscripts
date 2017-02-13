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

ls makefile.unix

if [ -x nexus ]; then
	echo "The 'nexus' daemon appears to be built already. Skipping make."
else
	echo "Building Nexus daemon from source code."

	make clean || true

	cp makefile.unix Makefile

	RELEASE=1 USE_UPNP=- USE_LLD=1 make -j$(nproc)

	rm -f Makefile
	
	echo "Build process complete, you can run the nexus daemon from the command line with a command like ./nexus -daemon -debug -printtoconsole"
fi
