# Xcode Tools
Collection of few tools and utils for Xcode to make life ~~easier~~ bearable.

## SimGuard
SimGuard is a workaround script which looks for a stuck process in the background after LLDB session ends and shuts down Simulator if needed.

### Match error - 308 - (ipc/mig) server died
In some cases LLDB makes processes zombie which was attached on and since on Simulator the parent process is always `launchd` we can't simply kill it. The issue happens when a new debug session is starting and tries to wait for the previous session to finish. Xcode shows no error or warnings (debugger doesn't even started at this point) and will stuck "Installing..." state forever or until you kill the simulator manually with CMD+Q. That's when it shows "server died "message.  
I haven't found the root cause yet, something to do with C++ interoperability, but I haven't been able to figure out yet and neither has Apple, it seems.

### How it works
Unfortunately we can't hook on LLDB when debug session ends but we can hook on log messages. The script will watch on `debugserver` and if emits a message when session ends it will check if a process with the given bundle ID is still exist. If the process is present then it simply shuts down the simulator, so next time the debug session will start a new one and won't wait forever.

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

With paramenter `-n` sends notification to destop when a shutdown was needed.

Intended to run in the background, so no need to add to your Xcode project.

## Fixcode
Fixcode is a script which stops all the Xcode processes and delete dervied data.

Sometimes Xcode needs take a break and/or delete all the cache. Fixcode simply pgreps all "Xcode" and "xcodebuild" processes and kills them with -9.  
If you run with `-D` it deletes everything with `rm -rf ~/Library/Developer/Xcode/DerivedData`. Its important to terminate all Xcode processes because it sometimes holds the cache and `rm` can't delete it even with `-rf` (and thats why reads old cache after you pressed CMD+SHIFT+K)

```shell
alias fixcode="~/fixcode.sh"
alias deletederiveddata="~/fixcode.sh -D"
```