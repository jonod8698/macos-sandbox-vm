#!/usr/bin/env bash

# Parse command line arguments
URL=""
FILE_PATH=""
BASE_IMAGE="ventura-ci-vanilla-base"

# u - URL to open in the VM
# f - File to run in the VM
# t - VM duration, default no time limit

while getopts "u:f:" flag
do
    case "${flag}" in
        u) URL=${OPTARG};;
        f) FILE_PATH=${OPTARG};;
        t) TIME_LIMIT=${OPTARG};;
        *) echo "Invalid option: -$OPTARG" >&2
           exit 1;;
    esac
done


# Create a temporary VM and run it
tart clone $BASE_IMAGE ventura-temp
if [ ! -z "$URL" ]; then
    echo "Starting VM and opening link $URL..."
else
    echo "Starting VM and running the file $FILE_PATH..."
fi
# start cloned vm with isolated networking
tart run ventura-temp --net-softnet &
# Because apple doesn't let you check via API if the VM fully started in Ventura

# Get the IP address of the VM

until IP=$(tart ip ventura-temp 2> /dev/null)
do
    sleep 1
done


# SSH into the VM using provided credentials
echo "Close this VM using command + C"
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
tart stop ventura-temp 2> /dev/null
tart delete ventura-temp