#!/usr/bin/env bash

# macOS virtualization framework only works on macOS arm64
if [[ "$OSTYPE" != "darwin"* || "$(uname -m)" != "arm64" ]]; then
    echo "This feature is only for macOS arm64"
    exit 1
fi

if ! command -v tart list &> /dev/null
then
    echo "<the_command> could not be found"
    brew install cirruslabs/cli/tart
    exit
fi

tart stop $BASE_IMAGE 2> /dev/null
BASE_IMAGE="ventura-ci-vanilla-base"
tart clone ventura-base $BASE_IMAGE
tart run $BASE_IMAGE --net-softnet &
# Because apple doesn't let you check via API if the VM fully started in Ventura
until IP=$(tart ip $BASE_IMAGE 2> /dev/null)
do
    sleep 1
done

#Check if host system has ssh key

# Add ssh key to authorized hosts on VM
echo "Enter 'admin' as the password"
ssh-copy-id -f admin@$IP

#Install powershell, atomic red team and other dependencies

echo "Initial provisioning complete. Perform any manual modifications to the base template"
echo "then press command + c"
sleep 500 # time to allow users to make manual changes
# stop tart base VM
tart stop $BASE_IMAGE