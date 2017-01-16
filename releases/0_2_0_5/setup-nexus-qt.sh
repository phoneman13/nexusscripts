#!/bin/bash
# setup-nexus-qt.sh - Optional nexus-qt setup script
#   This optional script will download and setup the 'bootstrap' 
#   database file, which will reduce the time it takes
#   for your wallet to sync with the network.
# Warranty: none.
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

echo "This script is only intended to be used to setup your downloaded nexus-qt."
echo "No warranty is expressed or implied and if you chose to run this on an existing Nexus install you do so at your own risk (ABBU - Always Be Backing Up)."
echo "This script prints out everything it is doing (usually mutiple times)"
echo "This is so that if/when things go wrong, you can fix them."
echo "You should be able to re-run the script after fixing a failed step, and it will retry a few steps and start where it left off."

while true; do
    read -p "Do you wish to continue [yes or no]?" yn
    case $yn in
        [Yy]* ) echo "OK!"; break;;
        [Nn]* ) echo "Bye!"; exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

# Comment out set -o verbose and set -o xtrace if you want to see less verbose output.
set -o verbose   # show commands as they are executed
set -o xtrace    # expand variables

echo "Setting up .Nexus configuration directory."

cd $HOME

ls .Nexus || mkdir .Nexus

cd $HOME/.Nexus

chmod 700 $HOME/.Nexus

echo "Downloading and Setting Up Nexus blockchain bootstrap file."

which wget || sudo apt-get install wget

DB_BASEURL="http://nexusearth.com/bootstrap/2.0.5-Database"

DB_BOOTSTRAP="recent.rar"

ls ${DB_BOOTSTRAP} || wget ${DB_BASEURL}/${DB_BOOTSTRAP}

which unrar || sudo apt-get install unrar

unrar x ${DB_BOOTSTRAP}

echo "Process complete."
echo "You can remove the ${DB_BOOTSTRAP} in your ${HOME}/.Nexus directory - it has been retained in case you want to save it for other installs, but you don't really need it anymore."
echo "You should be able to start the Qt wallet with a command like ${HOME}/Nexus-Qt/nexus-qt &"
echo "Remember, make sure to back up your ${HOME}/.Nexus/wallet.dat file on e.g. a USB drive after starting Nexus for the first time."
echo "THE TRUTH IS OUT THERE"
