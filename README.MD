

# Requirements
Host System
- macOS arm64 / Apple Silicon
- [tart](https://github.com/cirruslabs/tart)

Base VM
- PowerShell Core
- Invoke-AtomicRedTeam

# Quick Start
Install Tart
```zsh
brew install cirruslabs/cli/tart
```

Download a pre-built Base VM from cirruslabs.
```zsh
tart clone ghcr.io/cirruslabs/macos-ventura-base:latest ventura-base
```

Start the VM and configure `softnet` for network isolation.
```zsh
tart run ventura-base --net-softnet
```

Close the VM then run `prepare.sh`. Enter the password for the VM when prompted.
```zsh
./prepare.sh
```

Run an [atomic red team test](https://atomicredteam.io/tags/#macos). Std out will be shown in the terminal and the execution log will be copied to your host.
```zsh
./sandbox-atomicredteam.sh -t T1553.004-3 # run test T1553.004-3
```

You may also run a custom command instead of a specific test.
```zsh
./sandbox-atomicredteam.sh -c 'pwsh -c "Invoke-AtomicTest T1553.004-3 -GetPrereqs -PathToAtomicsFolder "./atomic-red-team/atomics""' # run custom command
```
# Output
Std out will be shown in the terminal and the execution log will be copied to your host.

By default [Attire-ExecutionLog](https://github.com/redcanaryco/invoke-atomicredteam/wiki/Execution-Logging#attire-logger) is enabled, allowing for direct import into [Vectr](https://github.com/SecurityRiskAdvisors/VECTR). After test execution, the log is copied to the host and can be found in the `output` directory. Example.


# Base VM Customization


# Example Scripts

# Todo
### v1
- [x] Create a temporary macOS VM
- [x] Network isolation
- [x] Run Atomic red team
- [x] Command Line paramters to customize Atomic red team test
- [x] Flag for arbitrary commands to be run
- [x] Copy the execution log from the VM to the host
- [ ] Base VM prepration guide