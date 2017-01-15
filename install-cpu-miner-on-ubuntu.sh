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

echo "This script is only intended to be used to install a fresh version of Nexus CPU miner on Ubuntu."
echo "No warranty is expressed or implied and if you chose to run this on an existing Nexus install you do so at your own risk (ABBU - Always Be Backing Up)."
echo "This script prints out everything it is doing (usually mutiple times)"
echo "This is so that if/when things go wrong, you can fix them."

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

echo "Attempting to install the Nexus prime miner code under ~/code/"

ls code || mkdir code

cd code

which git >/dev/null 2>&1 || sudo apt-get install git

ls PrimeSoloMiner >/dev/null 2>&1 || git clone https://github.com/Nexusoft/PrimeSoloMiner.git
 
sudo apt-get install libgmp3-dev

cd PrimeSoloMiner

ls Makefile || ln -s makefile.unix Makefile

make -j$(nproc)

# This commented section is a work in progress... do not use unless you know what you're doing...
# <<You normally have to handle this when running nexus command line for the first time. Automate this step for the user.>>
#Error: To use Nexus, you must set a rpcpassword in the configuration file:
# /home/dev/.Nexus/nexus.conf
#It is recommended you use the following random password:
#rpcuser=rpcserver
#rpcpassword=
#(you do not need to remember this password)
#If the file does not exist, create it with owner-readable-only file permissions.
#if [ ! -e nexus.conf.example ]; then
#	RANDPASS=`strings /dev/urandom | grep -o '[[:alnum:]]' | head -n 43 | tr -d '\n'`
#	echo "rpcuser=rpcserver\nrpcpassword=${RANDPASS}\n" >> nexus.conf.example
#	chmod 600 nexus.conf.example
#	echo "Automatically created a file at nexus.conf.example with a random password for you."
#       echo "You should review this file, compare it to any existing file at ~/.Nexus/nexus.conf."
#       echo "If you are satisfied with this file or don't already have a nexus.conf, then run this command:"
#       echo "cp nexus.conf.example ~/.Nexus/nexus.conf"
#fi

-e $HOME/code/PrimeSoloMiner/startminer.sh || printf "#!/bin/bash\n${HOME}/code/PrimeSoloMiner/miner localhost 9325 $(nproc)" > $HOME/code/PrimeSoloMiner/startminer.sh && chmod 755 $HOME/code/PrimeSoloMiner/startminer.sh

echo "Make sure you already have nexus running and your config file is set up correctly."

echo "If you want to solo CPU mine nexus, you'll want your nexus.conf file to look something like the one in examples/nexus.conf.example. The real config file is in .Nexus/nexus.conf under your home directory (you may need to create it)."

echo "Process complete."
echo "You should see a file called 'miner' in ${HOME}/code/PrimeSoloMiner. This is the miner."
echo "You can run it like this on the command line $HOME/code/PrimeSoloMiner/startminer.sh"
echo "Have a nice day."
