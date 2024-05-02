# Xcode Tools
Collection of few tools and utils for Xcode to make life ~~easier~~ bearable.

## SimGuard
SimGuard is a workaround for a LLDB issue when attached process will become zombie and Xcode can't start new debug session. Script looks for a stuck process in the background after LLDB session ends and shuts down Simulator if needed.

### Match error - 308 - (ipc/mig) server died
In some cases (on macOS 14 with Xcode 15.2) LLDB makes processes zombie which was attached on. Issue happens when a new debug session is starting and waits for the previous session to finish. Xcode shows no error or warnings (debugger doesn't even started at this point) and will stuck "Installing..." state forever or until you close the simulator manually with CMD + Q. After that it shows the "server died "message.  
I haven't found the root cause yet, something to do with C++ interoperability, but I haven't been able to figure out yet and neither has Apple, it seems.

### How it works
The script will hooks on `debugserver` logs and if LLDB server emits a message when session ends it will check the process with the given bundle ID and simply shuts down the Simulator if still exists, so next time the debug session will start a new one and won't wait forever. Unfortunately LLDB has no event for session end so the script needs to run in the background and process the log messages.

```shell
./simguard.sh -h
# Simguard, check if a process is still exist when lldb exists and restarts Simulator if needed.
#
#options:
#-h    Print help
#-b    bundle if of the process to check
#-n    Send notification when restart is needed

./simguard.sh -b "com.myapp.bundleid" -n
```

With paramenter `-n` will send notification to desktop when a shutdown was needed.

Intended to run in the background, so no need to add to your Xcode project just run from terminal or you can schedule to run at login with `LaunchAgent`

## Fixcode
Fixcode is a script which stops all the Xcode processes and/or delete dervied data.

Sometimes Xcode needs take a break and delete all the cache. Fixcode simply pgreps all "Xcode" and "xcodebuild" processes and kills them with -9.  
If you run with `-D` it deletes everything with `rm -rf ~/Library/Developer/Xcode/DerivedData`. Its important to terminate all Xcode processes before deleting DerivedData because it sometimes holds the cache and `rm` can't delete it even with `-rf` (and thats why reads old cache after you pressed CMD + SHIFT + K)

```shell
alias fixcode="~/fixcode.sh"
alias deletederiveddata="~/fixcode.sh -D"
```