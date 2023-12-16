#!/usr/bin/env bash

# Parse command line arguments
URL=""
FILE_PATH=""
os_version="ventura"

# u - URL to open in the VM
# f - File to run in the VM
# t - VM duration, default no time limit

if [[ "$OSTYPE" != "darwin"* || "$(uname -m)" != "arm64" ]]; then
    echo "This feature is only for macOS arm64"
    exit 1
fi

if ! command -v tart list &> /dev/null
then
    echo "tart is not installed"
    brew install cirruslabs/cli/tart
    exit
fi

while getopts "u:f:t:o:h" flag
do
    case "${flag}" in
        u) URL=${OPTARG};;
        f) FILE_PATH=${OPTARG};;
        t) TIME_LIMIT=${OPTARG};;
        o) os_version=${OPTARG};;
        h) echo "Usage: $0 [-u URL] [-f file path] [-t time limit] [-h help]"
           exit 1;;
        *) echo "Invalid option: -$OPTARG" >&2
           exit 1;;
    esac
done

BASE_IMAGE="$os_version-ART-base"
temp_vm_name="$os_version-temp"

# Create a temporary VM and run it
tart clone $BASE_IMAGE $temp_vm_name
if [ ! -z "$URL" ]; then
    echo "Starting VM and opening link $URL..."
else
    echo "Starting VM and running the file $FILE_PATH..."
fi
# start cloned vm with isolated networking
tart run $temp_vm_name --net-softnet &

# Get the IP address of the VM
until IP=$(tart ip $temp_vm_name 2> /dev/null)
do
    sleep 1
done

# SSH into the VM using provided credentials
echo "Close this VM using command + C"
ssh -R $IP
if [ ! -z "$URL" ]; then
ssh -o StrictHostKeyChecking=no -tt admin@$IP > /dev/null 2>&1 << EOF
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --new-window $URL > /dev/null 2>&1
# Add a newline to close the VM after command execution
EOF
elif [ ! -z "$FILE_PATH" ]; then
# Copy file to VM
scp -o StrictHostKeyChecking=no $FILE_PATH admin@$IP:/tmp/

# Simulate double clicking the file 
ssh -o StrictHostKeyChecking=no -tt admin@$IP > /dev/null 2>&1 << EOF
open /tmp/$(basename $FILE_PATH)
# Add a newline to close the VM after command execution
EOF
fi

# Stop and clean up the VM
tart stop $temp_vm_name 2> /dev/null
tart delete $temp_vm_name
ssh -R $IP