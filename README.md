# nexusscripts

Scripts related to Nexus. View the script source for more info on how to run.

## Install Nexus from source on Ubuntu by copy/pasting a single command

Use with caution, but this can be a fast way to get up and running.

This does it all, including downloading and installing this very repository, which it will install under $HOME/code.

 $ curl -L https://raw.githubusercontent.com/physicsdude/nexusscripts/master/bootstrap/bootstrap.sh | bash

## install-nexus-on-ubuntu.sh

You can use this script to install Nexus from scratch on an Ubuntu (this is used by bootstrap.sh).
It should also work on other Debian-like systems but hasn't been tested.
You can run it with the command:

 ./install-nexus-on-ubuntu.sh

##  printblocks.pl

This script queries the Nexus blockchain for information and otuputs it in a JSON format with extra information.
See the source code for documentation.

Example: See info on the last 10 blocks which contain at least one non-coinbase transaction.

 ./printblocks.pl -b current -n 10 -m 2


# THE TRUTH IS OUT THERE
