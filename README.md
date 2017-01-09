# nexusscripts

Scripts related to Nexus. View the script source for more info on how to run.

## install-nexus-on-ubuntu.sh

You can use this script to install Nexus from scratch on an Ubuntu.
It should also work on other Debian-like systems but hasn't been tested.
You can run it with the command:

 ./install-nexus-on-ubuntu.sh

##  printblocks.pl

This script queries the Nexus blockchain for information and otuputs it in a JSON format with extra information.
See the source code for documentation.

Example: See info on the last 10 blocks which contain at least one non-coinbase transaction.

 ./printblocks.pl -b current -n 10 -m 2


# THE TRUTH IS OUT THERE
