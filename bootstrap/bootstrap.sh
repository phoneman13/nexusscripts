#!/bin/bash
# Author: BryanGmyrek.com <bryangmyrekcom@gmail.com>
set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   # set -u : exit the script if you try to use an uninitialised variable
set -o errexit   # set -e : exit the script if any statement returns a non-true return value
error() {
  echo "Error on or near line ${1}: ${2:-}; exiting with status ${3:-1}"
  exit "${3:-1}"
}
trap 'error ${LINENO}' ERR

echo "Welcome. This script is designed to install and set up Nexus from source in one step on an Ubuntu 14.04 system."

cd ${HOME}

ls code >/dev/null 2>&1 || mkdir code

cd ${HOME}/code

which git >/dev/null 2>&1 || sudo apt-get install git

ls ${HOME}/code/nexusscripts >/dev/null 2>&1 || git clone https://github.com/physicsdude/nexusscripts.git

cd ${HOME}/code/nexusscripts

echo "Attempting to run the install script at ${HOME}/code/nexusscripts/install-nexus-on-ubuntu.sh"

/bin/bash ${HOME}/code/nexusscripts/install-nexus-on-ubuntu.sh
