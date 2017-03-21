#!/bin/bash

CRONITOR=CHANGETHIS
NEXUSPATH=/home/dev/code/Nexus/$PROG
PROG=nexus-qt

# You can use this script to
#  ensure that nexus-qt is running
#  and get alerts when it fails
#  and be able to easily check onine
#  if it's running.
#  Report info to cronitor.io

# If you want to get alerts when it
#  fails or is not running, you can
#  to create an account at cronitor.io
# Create a heartbeat monitor.
# You'll get a unique code for your cronitor
#    replace the value to the right of CRONITOR=
#    with your code above.

# Also, make sure to update NEXUSPATH to the
#  directory which contains your nexus-qt file

# When this is all set, add lines like this to 
#  your crontab file. Edit it with 'crontab -e'
# (add the following two lines only to your crontab
#  file, without the #)

#*/1 * * * * touch /home/dev/code/nexusscripts/.ensure-wallet-running-lastrun-marker >/dev/null
#*/1 * * * * /bin/bash /home/dev/code/nexusscripts/ensure-wallet-running.sh >/dev/null 2>&1

# The first line is a 'sanity' check - you can check the time stamp of this file
#  to see the last time the cron ran.
# The second line runs this script.

# Does it look like the program is running?
if ps ax | grep -v grep | grep $PROG > /dev/null
then
    # Yes, ok let cronitor know it's running.
    curl https://cronitor.link/$CRONITOR/run -m 10
    exit
else
    # No, ut, oh, better alert that there was a failure (or system restart)
    curl https://cronitor.link/$CRONITOR/fail -m 10
    # Try to start the program.
    $PROG &
    # Wait a few seconds before checking.
    sleep 10
    # Check again if it looks like the program is running.
    if ps ax | grep -v grep | grep $PROG > /dev/null
    then
        # It's running! Alert cronitor.
        curl https://cronitor.link/$CRONITOR/run -m 10
    else
        # It failed again, let cronitor know.
        curl https://cronitor.link/$CRONITOR/fail -m 10
    fi
fi

exit
