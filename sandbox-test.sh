#!/usr/bin/env bash

# Parse command line arguments
URL=$1

# Create a temporary VM and run it
tart clone ventura-ci-vanilla-base ventura-temp
echo "Starting VM and opening link $URL..."
tart run ventura-temp --net-softnet &
sleep 10

# Get the IP address of the VM
IP=$(tart ip ventura-temp)

# SSH into the VM using provided credentials
echo "Close this VM using command + C"
ssh -o StrictHostKeyChecking=no -tt runner@$IP > /dev/null 2>&1 << EOF
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --new-window $URL > /dev/null 2>&1
EOF

# Stop and clean up the VM
tart stop ventura-temp 2> /dev/null
tart delete ventura-temp