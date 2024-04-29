# Xcode Tools
Collection of few tools and utils make life easier.

## SimGuard
SimGuard is a script which checks for a specific process and if an LLDB session finishes and that process still active then shuts down Simulator.  

### Match error - 308 - (ipc/mig) server died
In some cases LLDB makes processes zombie which was atteched on and since on Simulator the parent process is the `launchd` we cant simply kill it. The issue happens when a new debug session is starting and waits for the previous to finish. Xcode shows no error or warnings (debugger doesn't even started at this point) and will stuck "Installing..." forever or until you kill the simulator manually with CMD+Q and that's when it shows "server died "message. Haven't find the root cause yet, something to do with C++ interoperability but coulnd't manage to sort it out yet.  

### How it works
Unfortunately we can't hook on LLDB when debug session ends but we can hook on log messages. The script will watch on `debugserver` and if emits a message when session ends it will check if a process with the given bundle ID is still exist. If the process is present then it simply shuts down the simulator so next time the debug session will start a new one.

```shell
./simguard.sh -b "com.myapp" -n
```

With paramenter `-n` sends notification to destop when a shutdown was needed.