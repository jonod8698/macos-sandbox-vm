

# Requirements
Host System
- macOS arm64 / Apple Silicon
- tart

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

Run a Test
```zsh
./sandbox-atomicredteam.sh -t T1553.004-3 # run test T1553.004-3
./sandbox-atomicredteam.sh -c 'pwsh -c "Invoke-AtomicTest T1553.004-3 -GetPrereqs -PathToAtomicsFolder "./atomic-red-team/atomics""' # run custom command
```
#


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