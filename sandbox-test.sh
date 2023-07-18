#!/usr/bin/env bash

# Parse command line arguments
for arg in "$@"
do
    case $arg in
        --url=*)
        URL="${arg#*=}"
        shift
        ;;
        --timeout=*)
        TIMEOUT="${arg#*=}"
        shift
        ;;
        *)
        OTHER_ARGUMENTS+=("$1")
        shift
        ;;
    esac
done

# Set the default timeout value if not provided
TIMEOUT="${TIMEOUT:-60}"

# Create a temporary VM and run it
tart clone ventura-ci-vanilla-base ventura-temp
tart run ventura-temp --net-softnet &
sleep 10

# Get the IP address of the VM
IP=$(tart ip ventura-temp)

# SSH into the VM using provided credentials
ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa runner@$IP << EOF
    # Open the specified URL in Chrome
    /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --new-window $URL &
EOF

# Wait for the specified timeout duration
sleep $TIMEOUT

# Stop and clean up the VM
tart stop ventura-temp
tart delete ventura-temp
