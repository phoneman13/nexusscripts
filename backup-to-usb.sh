#!/bin/bash
# ./backup-to-usb.sh
# Backs up Nexus wallet to usb drive.
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

# Attempts to auto back up wallet to an inserted usb drive

NBAK='NexusBackups'
TIME=`date +%s`

echo "Current unix time is $TIME"

USBDIR=`ls /media/$USER`

if [[ "${USBDIR}" == ""  ]]; then
	echo "Please insert a USB drive."
	exit 1
fi

echo "Found usb directory: $USBDIR"

SUBDIR="/media/${USER}/${USBDIR}/${NBAK}/${TIME}"

echo "Making nexus subdirectory ${SUBDIR}"

mkdir -p ${SUBDIR}

echo "Running paper wallet printer."

${HOME}/code/nexusscripts/paperwallet.pl --noview

echo "Copying wallet.dat and paper wallet files to usb at ${SUBDIR}."

cp ${HOME}/.Nexus/wallet.dat ${SUBDIR}

rsync -av ${HOME}/NexusPaperWallets/* ${SUBDIR}

echo "Process complete."

echo "THE TRUTH IS OUT THERE"
