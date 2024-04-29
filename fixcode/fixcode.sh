#!/bin/bash

osascript -e 'display notification "Purge all Xcode processes..." with title "Fixcode"'
ps aux | awk '{print $2"\t"$11}' | grep "/Xcode.*.app" | awk '{print $1}' | xargs kill -SIGKILL

if [ "$1" == "-D" ]; then
    pgrep "Xcode|xcodebuild" > /dev/null
    if [ $? -eq 0 ]; then
        osascript -e 'display dialog "Cannot delete derived data, Xcode is still running!" with icon stop buttons {"OK"} with title "Fixcode"'
    else
        osascript -e 'display notification "Start deleting derived data..." with title "Fixcode"'
        rm -rf ~/Library/Developer/Xcode/DerivedData
        if [ $? -eq 0 ]; then
            osascript -e 'display notification "Finished deleting derived data" with title "Fixcode"'
        else
            osascript -e 'display dialog "Failed to derived data!" with icon stop buttons {"OK"} with title "Fixcode"'
        fi
    fi
fi
