


# Requirements
Host System
- macOS arm64 / Apple Silicon
- tart
```zsh
brew install cirruslabs/cli/tart
```

Base VM
- PowerShell Core
- Invoke-AtomicRedTeam

# Quick Start
Download a pre-built Base VM from cirruslabs.
```zsh
tart clone ghcr.io/cirruslabs/macos-ventura-base:latest ventura-base
```

Start the VM and configure `softnet` for network isolation.
```zsh
tart run ventura-base --net-softnet
```

Close the VM. Run `prepare.sh`.
```zsh
./prepare.sh
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