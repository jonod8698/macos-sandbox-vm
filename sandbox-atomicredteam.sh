#!/usr/bin/env bash
# 
# Script to run Atomic Red Team tests in a temporary VM using the macOS virtualization framework.
#
# Prereqs:
# - Host: macOS arm64 and tart https://github.com/cirruslabs/tart
# - Base VM image: pwsh and invoke-atomicredteam
#
# Basic usage: 
# - ./sandbox-atomicredteam.sh -t T1569.001-1 # run test T1569.001-1
# - ./sandbox-atomicredteam.sh -c 'pwsh -c "Invoke-AtomicTest T1569.001-1 -GetPrereqs -PathToAtomicsFolder "./atomic-red-team/atomics""' # run custom command
#

atomic_red_team_repo="https://github.com/redcanaryco/atomic-red-team.git"
atomic_red_team_branch="master"
atomic_red_team_number="T1569.001-1"
custom_command=""
os_version="ventura"
macos_username="admin"
delete_temp_vm=true
atomics_folder="./atomic-red-team/atomics"
logging_folder="./output"
logging_module="Attire-ExecutionLogger"

timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

cleanup_vm() {
    echo "Copying execution log from VM..."
    scp -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o ServerAliveInterval=10 -o ServerAliveCountMax=20 -q $macos_username@$IP:~/$atomic_red_team_number.json $logging_folder/$atomic_red_team_number-$TEST_START_TIME.json
    # use scp to copy any files you want to save from the VM to the host
    if [ "$delete_temp_vm" = true ]; then
        tart stop $temp_image 2> /dev/null
        tart delete $temp_image
        echo -e '\nTemp vm deleted'
    fi
}

while getopts "t:c:d:b:r:u:o:i:h" flag
do
    case "${flag}" in
        t) atomic_red_team_number=${OPTARG};;
        c) custom_command=${OPTARG};;
        d) delete_temp_vm=${OPTARG};;
        b) atomic_red_team_branch=${OPTARG};;
        r) atomic_red_team_repo=${OPTARG};;
        u) macos_username=${OPTARG};;
        o) os_version=${OPTARG};;
        i) base_image=${OPTARG};;
        h) echo "Usage: $0 [-t test number] [-c custom bash command] [-d delete temp vm (true/false)] [-b branch] [-r repo] [-u username] [-o os version] [-i base image] [-h help]"
           exit 1;;
        *) echo "Invalid option: -$OPTARG" >&2
           exit 1;;
    esac
done

temp_image="$os_version-ART-$atomic_red_team_number"
base_image=$os_version-ART-base
temp_image="$os_version-ART-$atomic_red_team_number"

if [[ "$OSTYPE" != "darwin"* || "$(uname -m)" != "arm64" ]]; then
    echo "This feature is only for macOS arm64" # macOS virtualization framework only works on macOS arm64
    exit 1
fi

tart clone $base_image $temp_image # APFS clones only consume the space of the changes made to the original image
tart run $temp_image --net-softnet & # start cloned vm with isolated networking (no outbound host or local network access)

# Get the IP address of the VM when it fully starts
until IP=$(tart ip $temp_image 2> /dev/null)
do
    sleep 1
done

# Provision atomic red team test suite
ssh-keygen -R $IP
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=15 -o ServerAliveInterval=5 -o ServerAliveCountMax=20 -t -q $macos_username@$IP  << EOF
echo "------------------------------------------------------------"
echo "Cloning $atomic_red_team_repo"
pwsh -c "git clone --depth=1 -b $atomic_red_team_branch $atomic_red_team_repo"
EOF

TEST_START_TIME=$(timestamp)

if [[ ! -z "$custom_command" ]]; then
    echo "Running custom command $custom_command"
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o ServerAliveInterval=10 -o ServerAliveCountMax=20 -t -q $macos_username@$IP << EOF
    echo "------------------------------------------------------------"
    echo "Running custom command $custom_command"
    pwsh -c "Invoke-AtomicTest "T1553.004-3" -PathToAtomicsFolder "./atomic-red-team/atomics" -ExecutionLogPath "~/$atomic_red_team_number.json" -LoggingModule $logging_module" 
EOF
else
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o ServerAliveInterval=10 -o ServerAliveCountMax=20 -t -q $macos_username@$IP << EOF
    echo "------------------------------------------------------------"
    echo "Getting prerequisites for $atomic_red_team_number"
    pwsh -c "Invoke-AtomicTest $atomic_red_team_number -GetPrereqs -PathToAtomicsFolder \"$atomics_folder\""
    echo "------------------------------------------------------------"
    echo "Running $atomic_red_team_number"
    # You can start logging tools here. e.g. sudo eslogger exec fork mmap  > ~/eslogger.json &
    pwsh -c "Invoke-AtomicTest $atomic_red_team_number -PathToAtomicsFolder "$atomics_folder" -ExecutionLogPath "~/$atomic_red_team_number.json" -LoggingModule $logging_module"
    echo "Test complete"
    echo "------------------------------------------------------------"
EOF
fi

echo "Type 'exit' to close the VM"
echo "!!! This is a shell inside the VM !!!"
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o ServerAliveInterval=10 -o ServerAliveCountMax=20 -q $macos_username@$IP

# Stop and clean up the VM if delete_temp_vm is true
#cleanup_vm
trap cleanup_vm 0 1 SIGHUP SIGINT SIGQUIT SIGKILL