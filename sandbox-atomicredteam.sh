#!/usr/bin/env bash
# Basic usage: ./sandbox-atomicredteam.sh

ATOMIC_RED_TEAM_REPO="https://github.com/jonod8698/atomic-red-team.git"
ATOMIC_RED_TEAM_BRANCH="T1539-macOS"
ATOMIC_RED_TEAM_TEST_NUMBER="T1539-3"
OS_VERSION="ventura"
BASE_IMAGE=$OS_VERSION-base
BASE_IMAGE="ventura-ci-vanilla-base" # for testing
TEMP_IMAGE=$OS_VERSION-ART-$ATOMIC_RED_TEAM_TEST_NUMBER
macOS_username="admin"
DELETE_TEMP_VM=true
ATOMICS_FOLDER="./atomic-red-team/atomics"
LOGGING_MODULE="Attire-ExecutionLogger"

# Command line parameters
# -t test number
# -d true/false delete temp vm at end
# -b branch
# -r repo
# -u username
# -o os version
# -h help

function cleanup_vm() {
    scp admin@$IP:~/executionlog-$ATOMIC_RED_TEAM_TEST_NUMBER.json ./output/executionlog-$ATOMIC_RED_TEAM_TEST_NUMBER.json
    if [ "$DELETE_TEMP_VM" = true ]; then
        tart stop $TEMP_IMAGE 2> /dev/null
        tart delete $TEMP_IMAGE
        echo -e '\nTemp vm deleted'
    fi
}

while getopts "t:b:r:u:o:h" flag
do
    case "${flag}" in
        t) ATOMIC_RED_TEAM_TEST_NUMBER=${OPTARG};;
        d) DELETE_TEMP_VM=${OPTARG};;
        b) ATOMIC_RED_TEAM_BRANCH=${OPTARG};;
        r) ATOMIC_RED_TEAM_REPO=${OPTARG};;
        u) macOS_username=${OPTARG};;
        o) OS_VERSION=${OPTARG};;
        h) echo "Usage: $0 [-t ATOMIC_RED_TEAM_TEST_NUMBER] [-d true/false delete temp vm] [-b branch] [-r repo] [-u username] [-o os version] [-h help]"
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
tart run $TEMP_IMAGE --net-softnet & # start cloned vm with isolated networking

# Get the IP address of the VM when it fully starts
until IP=$(tart ip $TEMP_IMAGE 2> /dev/null)
do
    sleep 1
done

echo "Close this VM using command + C"

# Provision and run atomic red team test
ssh -o StrictHostKeyChecking=no -t -q $macOS_username@$IP  << EOF
pwsh -c "git clone --depth=1 -b $ATOMIC_RED_TEAM_BRANCH $ATOMIC_RED_TEAM_REPO"
EOF
# Strict host checking disabled - connection is local anyways.
ssh -o StrictHostKeyChecking=no -t -q $macOS_username@$IP  << EOF
pwsh -c "Invoke-AtomicTest $ATOMIC_RED_TEAM_TEST_NUMBER -GetPrereqs -PathToAtomicsFolder \"$ATOMICS_FOLDER\""
# sudo eslogger exec mmap fork | jq
pwsh -c "Invoke-AtomicTest $ATOMIC_RED_TEAM_TEST_NUMBER -PathToAtomicsFolder "$ATOMICS_FOLDER" -ExecutionLogPath "~/executionlog-$ATOMIC_RED_TEAM_TEST_NUMBER.json" -LoggingModule "Attire-ExecutionLogger" -TimeoutSeconds 60"
# Add a newline to close the VM after command execution
# cat ~/executionlog-$ATOMIC_RED_TEAM_TEST_NUMBER.json
#sleep 500
EOF

# Stop and clean up the VM if DELETE_TEMP_VM is set
trap cleanup_vm 0 1 SIGHUP SIGINT SIGQUIT SIGABRT SIGTERM SIGKILL