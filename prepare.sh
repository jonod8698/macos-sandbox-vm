#!/usr/bin/env bash

VANILLA_IMAGE="ventura-base"
BASE_IMAGE="ventura-ART-base"

# macOS virtualization framework only works on macOS arm64
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

tart stop $BASE_IMAGE 2> /dev/null
tart stop $VANILLA_IMAGE 2> /dev/null
tart clone $VANILLA_IMAGE $BASE_IMAGE
tart run $BASE_IMAGE --net-softnet &

# Check VM is online
until IP=$(tart ip $BASE_IMAGE 2> /dev/null)
do
    sleep 1
done

# Add ssh key to authorized hosts on VM
echo "Enter 'admin' as the password"
ssh-keygen -R $IP
ssh-copy-id -o StrictHostKeyChecking=no -f admin@$IP

#Install powershell, atomic red team and other dependencies
ssh -o StrictHostKeyChecking=no -t -q admin@$IP << EOF
brew install powershell
# This uses the master branch of ART instead of PowerShell Gallery
pwsh -c "IEX (IWR 'https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1' -UseBasicParsing);Install-AtomicRedTeam -InstallPath "~/.local/powershell/Modules""
pwsh -c "New-Item -ItemType File -Path ~/.config/powershell/Microsoft.PowerShell_profile.ps1 -Force"
pwsh -c "echo 'Import-Module -Name ~/.local/powershell/Modules/invoke-atomicredteam' > ~/.config/powershell/Microsoft.PowerShell_profile.ps1"
# Add code here to install security tools / EDR. Lima charlie example:
# curl -o lc_sensor -L https://downloads.limacharlie.io/sensor/mac/arm64
# chmod +x lc_sensor ; sudo ./lc_sensor -i <key>
EOF

echo "Initial provisioning complete. You may perform any required manual modifications to the base template"
echo "then type 'exit'"
ssh -o StrictHostKeyChecking=no -t -q admin@$IP # time to allow users to make manual changes