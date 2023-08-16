#!/usr/bin/env bash
if ! command -v tart list &> /dev/null
then
    echo "<the_command> could not be found"
    brew install tart
    exit
fi

tart stop $BASE_IMAGE 2> /dev/null
BASE_IMAGE="ventura-ci-vanilla-base"
tart run $BASE_IMAGE --net-softnet &
# wait 10 seconds
sleep 10
#Get ip address of VM
IP=$(tart ip $BASE_IMAGE)
# echo ask user to enter "runner" as password
echo "Enter 'runner' as the password"
ssh-copy-id -f runner@$IP
sleep 500
# stop tart base VM
tart stop $BASE_IMAE