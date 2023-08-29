#!/usr/bin/env bash


ATOMIC_RED_TEAM_REPO="https://github.com/jonod8698/atomic-red-team.git"

# Create a temporary VM and run it
tart clone ventura-ci-vanilla-base ventura-temp

# start cloned vm with isolated networking
tart run ventura-temp --net-softnet &

# Get the IP address of the VM
# Because apple doesn't let you check via API if the VM fully started in Ventura
until IP=$(tart ip ventura-temp 2> /dev/null)
do
    sleep 1
done


# SSH into the VM using provided credentials
echo "Close this VM using command + C"

ssh -o StrictHostKeyChecking=no -t admin@$IP  << EOF
brew install go;pwsh -c "git clone --filter=tree:0 -b T1539-macOS $ATOMIC_RED_TEAM_REPO";pwsh -c "Invoke-AtomicTest T1539-3 -GetPrereqs -PathToAtomicsFolder \"./atomic-red-team/atomics\"";sudo eslogger exec mmap fork | jq;pwsh -c "Invoke-AtomicTest T1539-3 -PathToAtomicsFolder "./atomic-red-team/atomics" -ExecutionLogPath "~/executionlog.json" -LoggingModule "Attire-ExecutionLogger" -TimeoutSeconds 60; return $true"
# Add a newline to close the VM after command execution
EOF

# Stop and clean up the VM
tart stop ventura-temp 2> /dev/null
tart delete ventura-temp