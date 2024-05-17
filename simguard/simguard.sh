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

error() { echo -e "\xF0\x9F\x9A\xA8 \033[0;31m$1\033[0m"; }

sendNotification()
{
    osascript \
        -e "on run argv" \
        -e "display notification item 1 of argv with title \"SimGuard\"" \
        -e "end run" \
        -- "$1"
}

killSimualtor()
{
    xcrun simctl shutdown $1
}

listBootedSimulators()
{
    xcrun simctl list devices booted | grep -E "[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}" -o
}

findPid() {
    xcrun simctl spawn $1 launchctl list | grep $2 | while read LINE ; do
        set -- $LINE
        echo $1
        exit 0
    done
}

isProcessStuck()
{
    STATE=($(ps -p "$1" -o state=))
    if [[ $STATE -eq "Z" ]]; then
        return 0
    else
        return 1
    fi
}

shutdownSimulatorIfNeeded() {
    listBootedSimulators | while read SIM ; do
        PID=$(findPid $SIM $1)
        if [[ -nz $PID ]]; then
            if isProcessStuck $PID; then
                echo "Process $1 has stuck on $SIM, reset simulator..."
                if [ $2 == "true" ]; then
                    SIM_NAME=$(xcrun simctl list devices $SIM | awk '{n=split($0,a,"("); if (n>1) { gsub(/^[ \t]+/, "", a[1]); gsub(/[ \t]+$/, "", a[1]); print a[1]}}')
                    MESSAGE="Reset simulator $SIM_NAME..."
                    sendNotification "$MESSAGE"
                fi
                killSimualtor $SIM
                echo $PID
            fi
        fi
    done
}

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

shutdownSimulatorIfNeeded $BUNDLE_ID $SEND_NOTIFICATION

# First line is the command itself
FIRSTLINE=1
log stream --debug --predicate 'process == "debugserver" and eventMessage contains "Exiting"' | while read line ; do
    if [ $FIRSTLINE == 1 ]; then
        FIRSTLINE=0
        continue
    fi

    if [[ $line =~ .*debugserver.*Exiting ]]; then
        shutdownSimulatorIfNeeded $BUNDLE_ID $SEND_NOTIFICATION
    fi
done

