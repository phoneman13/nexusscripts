#!/bin/bash

# Author: BryanGmyrek.com <bryangmyrekcom@gmail.com>

set -e

echo "Welcome. This script is designed to install and set up Nexus from source in one step on an Ubuntu 14.04 system."

cd ${HOME}

ls code >/dev/null 2>&1 || mkdir code

cd ${HOME}/code

which git >/dev/null 2>&1 || sudo apt-get install git

ls ${HOME}/code/nexusscripts >/dev/null 2>&1 || git clone https://github.com/physicsdude/nexusscripts.git

cd ${HOME}/code/nexusscripts

./install-nexus-on-ubuntu.sh
