#!/bin/bash
# ./install-nexus-on-ubuntu.sh
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

echo "This script is only intended to be used to install a fresh version of Nexus on Ubuntu."
echo "No warranty is expressed or implied and if you chose to run this on an existing Nexus install you do so at your own risk (ABBU - Always Be Backing Up)."
echo "This script prints out everything it is doing (usually mutiple times)"
echo "This is so that if/when things go wrong, you can fix them."
echo "Many packages will be installed/removed automaticaly. If you're not sure if this is OK, inspect the source code of this script first and/or run the commands independently."
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

cd $HOME

echo "Attempting to install the Nexus source code at ~/code/Nexus"

ls code || mkdir code

cd code

which git || sudo apt-get -y install git

ls Nexus || git clone https://github.com/Nexusoft/Nexus.git

echo "Installing dependencies for Nexus."

#First ensure you have build essentials installed:
sudo apt-get -y install build-essential

#Install Boost:
sudo apt-get -y install libboost-all-dev

#Install Berklee DB:
sudo apt-get -y install libdb-dev libdb++-dev

#Install Open SSL:
sudo apt-get -y install libssl-dev

#Install Mini UPNP:
sudo apt-get -y install libminiupnpc-dev

#Install QrenCode:
sudo apt-get -y install libqrencode-dev

#For the Qt, install QT Framework:
sudo apt-get -y install qt4-qmake libqt4-dev qt4-default

# The qtbase5-dev deb can't be installed for successful qt compilation
sudo apt-get -y remove qtbase5-dev || true

# Will need unrar to unpack the bootstrap
which unrar || sudo apt-get -y install unrar

echo "Setting up .Nexus configuration directory."

cd $HOME

ls .Nexus || mkdir .Nexus

cd $HOME/.Nexus

echo "Downloading and Setting Up Nexus blockchain bootstrap file."

which wget || sudo apt-get -y install wget

LLD_BOOTSTRAP="recent.rar"

ls ${LLD_BOOTSTRAP} ||  wget http://nexusearth.com/bootstrap/LLD-Database/${LLD_BOOTSTRAP}

unrar x ${LLD_BOOTSTRAP}

cd $HOME/code/Nexus

if [ -x nexus ]; then
	echo "The 'nexus' daemon appears to be built already. Skipping make."
else
	echo "Building Nexus daemon from source code."

	cp makefile.unix Makefile

	USE_LLD=1 make -j$(nproc)

	rm -f Makefile
	
	echo "Build process complete, you can run the nexus daemon from the command line with a command like ./nexus -daemon -debug -printtoconsole"
fi

if [ -x nexus-qt ]; then
	echo "The 'nexus-qt' binary appears to exist already. Skipping. Remove this file and run again if you want to re-build it."
else
	echo "Building Nexus Qt GUI Wallet"

	cd $HOME/code/Nexus

	qmake nexus-qt.pro "RELEASE=1" "USE_UPNP=-" "USE_LLD=1"

	make -j$(nproc)

	echo "You should be able to run the Qt wallet with a command like $./nexus-qt"
fi

# This commented seciton is a work in progress... do not use unless you know what you're doing...
# <<You normally have to handle this when running nexus command line for the first time. Automate this step for the user.>>
#Error: To use Nexus, you must set a rpcpassword in the configuration file:
# /home/dev/.Nexus/nexus.conf
#It is recommended you use the following random password:
#rpcuser=rpcserver
#rpcpassword=
#(you do not need to remember this password)
#If the file does not exist, create it with owner-readable-only file permissions.
#if [ ! -e ${HOME}/.Nexus/nexus.conf ]; then
#	RANDPASS=`strings /dev/urandom | grep -o '[[:alnum:]]' | head -n 43 | tr -d '\n'`
#	echo "rpcuser=rpcserver\nrpcpassword=${RANDPASS}\n" >> ${HOME}/.Nexus/nexus.conf
#	chmod 600 ${HOME}/.Nexus/nexus.conf
#	echo "Automatically created a file at ${HOME}/.Nexus/nexus.conf with a random password for youa."
#fi

echo "Process complete."
echo "Nexus should be installed in ${HOME}/code/Nexus"
echo "You should be able to start the Qt wallet with a command like $./nexus-qt in that directory, or daemon mode with ./nexus"
echo "Remember to back up your ${HOME}/.Nexus/wallet.dat file on e.g. a USB drive after starting Nexus for the first time."
echo "Have a nice day."
