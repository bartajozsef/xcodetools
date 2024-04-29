#!/bin/bash

printHelp()
{
    echo "Simguard, check if a process is still exist when lldb exists and restarts Simulator if needed."
    echo
    echo "options:"
    echo "-h    Print help"
    echo "-b    bundle if of the process to check"
    echo "-n    Send notification when restart is needed"
}

killSimulatorIfNeeded()
{
    xcrun simctl spawn booted launchctl list | grep $1
    if [ $? -eq 0 ]; then
        if [ $2 -eq "true" ]; then
            osascript -e 'display notification "Process $1 has stuck,\nshutdown Simulator..." with title "SimGuard"'
        fi
        echo "Process $1 has stuck, shutdown Simulator..."
        xcrun simctl shutdown booted
    fi
}

error() { echo -e "\xF0\x9F\x9A\xA8 \033[0;31m$1\033[0m"; }

BUNDLE_ID=""
SEND_NOTIFICATION="false"

while getopts "b:nh" option; do
    case $option in
        h)
            printHelp
            exit;;
        b)
            BUNDLE_ID=("$OPTARG");;
        n)
            SEND_NOTIFICATION="true";;
        \?)
            error "Invalid option"
            echo
            printHelp
            exit 1
    esac
done

if [[ -z $BUNDLE_ID ]]; then
    error "Bundle ID is not specified!"
    echo
    printHelp
    exit 1
fi

echo "SimGuard started..."

if [ $SEND_NOTIFICATION == "false" ]; then
    echo "Notifications are turned off."
else
    echo "Sending notification if process has stuck."
fi

# First line is the command itself
FIRSTLINE="true"
log stream --debug --predicate 'process == "debugserver" and eventMessage contains "Exiting"' | while read line ; do
    if [ $FIRSTLINE == "true" ]; then
        FIRSTLINE="false"
        continue
    fi

    if [[ $line =~ .*debugserver.*Exiting ]]; then
        killSimulatorIfNeeded $SEND_NOTIFICATION
    fi
done

