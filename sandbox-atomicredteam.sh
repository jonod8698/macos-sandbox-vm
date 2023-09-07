#!/usr/bin/env bash
# 
# Script to run Atomic Red Team tests in a temporary VM using the macOS virtualization framework.
#
# Prereqs:
# - Host: macOS arm64 and tart https://github.com/cirruslabs/tart
# - Base VM image: pwsh and invoke-atomicredteam
#
# Basic usage: ./sandbox-atomicredteam.sh -t T1553.004-3 # run test T1553.004-3
# Command line parameters
# -t test number e.g. T1553.004-3
# -c bash command to run instead of automated test execution
# -d delete vm? true/false If true, delete temp vm at end
# -b branch
# -r repo
# -u username for ssh
# -o os version
# -h help

ATOMIC_RED_TEAM_REPO="https://github.com/redcanaryco/atomic-red-team.git"
ATOMIC_RED_TEAM_BRANCH="master"
ATOMIC_RED_TEAM_TEST_NUMBER="T1553.004-3"
CUSTOM_COMMAND=""
OS_VERSION="ventura"
BASE_IMAGE=$OS_VERSION-base
BASE_IMAGE="ventura-ci-vanilla-base" # for testing
TEMP_IMAGE=$OS_VERSION-ART-$ATOMIC_RED_TEAM_TEST_NUMBER
macOS_username="admin"
DELETE_TEMP_VM=true
ATOMICS_FOLDER="./atomic-red-team/atomics"
logging_folder="./output"
LOGGING_MODULE="Attire-ExecutionLogger"

timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

cleanup_vm() {
    echo "Copying execution log from VM..."
    scp -o StrictHostKeyChecking=no -o ConnectTimeout=10 admin@$IP:~/$ATOMIC_RED_TEAM_TEST_NUMBER.json $logging_folder/$ATOMIC_RED_TEAM_TEST_NUMBER-$TEST_START_TIME.json
    # use scp to copy any files you want to save from the VM to the host
    if [ "$DELETE_TEMP_VM" = true ]; then
        tart stop $TEMP_IMAGE 2> /dev/null
        tart delete $TEMP_IMAGE
        echo -e '\nTemp vm deleted'
    fi
}

while getopts "t:c:b:r:u:o:h" flag
do
    case "${flag}" in
        t) ATOMIC_RED_TEAM_TEST_NUMBER=${OPTARG};;
        c) CUSTOM_COMMAND=${OPTARG};;
        d) DELETE_TEMP_VM=${OPTARG};;
        b) ATOMIC_RED_TEAM_BRANCH=${OPTARG};;
        r) ATOMIC_RED_TEAM_REPO=${OPTARG};;
        u) macOS_username=${OPTARG};;
        o) OS_VERSION=${OPTARG};;
        h) echo "Usage: $0 [-t test number] [-c custom bash command] [-d delete vm (true/false)] [-b branch] [-r repo] [-u username] [-o os version]"
           exit 1;;
        *) echo "Invalid option: -$OPTARG" >&2
           exit 1;;
    esac
done

TEMP_IMAGE=$OS_VERSION-ART-$ATOMIC_RED_TEAM_TEST_NUMBER

# macOS virtualization framework only works on macOS arm64
if [[ "$OSTYPE" != "darwin"* || "$(uname -m)" != "arm64" ]]; then
    echo "This feature is only for macOS arm64"
    exit 1
fi

tart clone $BASE_IMAGE $TEMP_IMAGE # APFS clones only consume the space of the changes made to the original image
tart run $TEMP_IMAGE --net-softnet & # start cloned vm with isolated networking (no outbound host or local network access)

# Get the IP address of the VM when it fully starts
until IP=$(tart ip $TEMP_IMAGE 2> /dev/null)
do
    sleep 1
done

# Provision atomic red team test suite
ssh -o StrictHostKeyChecking=no -t -q $macOS_username@$IP  << EOF
echo "------------------------------------------------------------"
echo "Cloning $ATOMIC_RED_TEAM_REPO"
pwsh -c "git clone --depth=1 -b $ATOMIC_RED_TEAM_BRANCH $ATOMIC_RED_TEAM_REPO"
EOF

TEST_START_TIME=$(timestamp)

if [ ! -z "$CUSTOM_COMMAND" ]; then
    echo "Running custom command $CUSTOM_COMMAND"
    ssh -o StrictHostKeyChecking=no -t -q $macOS_username@$IP << EOF
    echo "------------------------------------------------------------"
    echo "Running custom command $CUSTOM_COMMAND"
    $CUSTOM_COMMAND
EOF
else
    ssh -o StrictHostKeyChecking=no -t -q $macOS_username@$IP << EOF
    echo "------------------------------------------------------------"
    echo "Getting prerequisites for $ATOMIC_RED_TEAM_TEST_NUMBER"
    pwsh -c "Invoke-AtomicTest $ATOMIC_RED_TEAM_TEST_NUMBER -GetPrereqs -PathToAtomicsFolder \"$ATOMICS_FOLDER\""
    echo "------------------------------------------------------------"
    echo "Running $ATOMIC_RED_TEAM_TEST_NUMBER"
    pwsh -c "Invoke-AtomicTest $ATOMIC_RED_TEAM_TEST_NUMBER -PathToAtomicsFolder "$ATOMICS_FOLDER" -ExecutionLogPath "~/$ATOMIC_RED_TEAM_TEST_NUMBER.json" -LoggingModule "Attire-ExecutionLogger" -TimeoutSeconds 60"
    echo "Test complete"
    echo "------------------------------------------------------------"
EOF
fi

echo "Type 'exit' to close the VM"
echo "!!! This is a shell inside the VM !!!"
ssh -o StrictHostKeyChecking=no -q $macOS_username@$IP

# Stop and clean up the VM if DELETE_TEMP_VM is set
cleanup_vm
#trap cleanup_vm 0 1 SIGHUP SIGINT SIGQUIT SIGKILL