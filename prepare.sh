#!/usr/bin/env bash
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
# wait 10 seconds
sleep 10
#Get ip address of VM
IP=$(tart ip $BASE_IMAGE)
#Check if host system has ssh key

# echo ask user to enter "runner" as password
echo "Enter 'admin' as the password"
ssh-copy-id -f admin@$IP
echo "Initial provisioning complete. Perform any manual modifications to the base template"
echo "then press command + c"
sleep 500
# stop tart base VM
tart stop $BASE_IMAGE