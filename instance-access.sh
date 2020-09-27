#!/bin/bash

fleet_id=
fleet_os=
fleet_name=
instances=
declare -a instance_list=()

if ! command -v jq >/dev/null 2>&1; then
	echo 'Install jq from your package manager'
	exit 1
fi

while ! [[ "$_fleet" != "" ]]; do
	echo -n "FleetId: "
	read _fleet
done
fleet_id=$_fleet

instances=$(aws gamelift describe-instances --fleet-id $fleet_id --query 'Instances')
fleet_name=$(aws gamelift describe-fleet-attributes --fleet-id $fleet_id --query 'FleetAttributes[0].Name')
echo "Fleet $fleet_name is in" $(aws gamelift describe-fleet-attributes --fleet-id $fleet_id --query 'FleetAttributes[0].Status') "State"
fleet_os=$(echo "${instances}" | jq '.[0].OperatingSystem' | sed -e 's/^"//' -e 's/"$//')
instance_ids=$(echo "${instances}" | jq -c '.[].InstanceId')
fleet_name=$(tr -s ' ' '_' <<< $fleet_name)
for i in $instance_ids; do
	instance_list[${#instance_list[@]}]=$i
done

# clear

# Creates a RDP file.
WinRDP() {
	mkdir -p $fleet_name/$fleet_id/

	instance_id=$(sed -e 's/^"//' -e 's/"$//' <<<$1)

	ip_address=$(aws gamelift get-instance-access --fleet-id $fleet_id --instance-id $instance_id --query 'InstanceAccess.IpAddress')
	ip_address=$(sed -e 's/^"//' -e 's/"$//' <<<$ip_address)

	echo "remoteapplicationappid:s:
wvd endpoint pool:s:
gatewaybrokeringtype:i:0
use redirection server name:i:0
alternate shell:s:
disable themes:i:0
disable cursor setting:i:0
resourceprovider:s:
disable menu anims:i:1
remoteapplicationcmdline:s:
redirected video capture encoding quality:i:0
promptcredentialonce:i:0
audiocapturemode:i:0
prompt for credentials on client:i:0
gatewayhostname:s:
remoteapplicationprogram:s:
gatewayusagemethod:i:2
screen mode id:i:2
use multimon:i:0
authentication level:i:2
desktopwidth:i:0
desktopheight:i:0
redirectsmartcards:i:0
redirectclipboard:i:1
full address:s:$ip_address
drivestoredirect:s:
loadbalanceinfo:s:
enablecredsspsupport:i:1
redirectprinters:i:0
autoreconnection enabled:i:1
session bpp:i:32
administrative session:i:0
authoring tool:s:
remoteapplicationmode:i:0
disable full window drag:i:1
gatewayusername:s:
shell working directory:s:
audiomode:i:0
username:s:gl-user-remote
allow font smoothing:i:1
connect to console:i:0
camerastoredirect:s:
disable wallpaper:i:0
gatewayaccesstoken:s:" | tee $fleet_name/$fleet_id/$instance_id.rdp

	clear

	password=$(aws gamelift get-instance-access --fleet-id $fleet_id --instance-id $instance_id --query 'InstanceAccess.Credentials.Secret')

	echo "Fleet instances have windows OS, check for a RDP file in script folder."
	echo password: $password
	echo "password copied to clipboard"
	echo $(sed -e 's/^"//' -e 's/"$//' <<<$password) | pbcopy
}
# Creates a .pem file and SSH to the instance.
LinuxSSH() {
	instance_id=$(sed -e 's/^"//' -e 's/"$//' <<<$1)

	ip_address=$(aws gamelift get-instance-access --fleet-id $fleet_id --instance-id $instance_id --query 'InstanceAccess.IpAddress')
	ip_address=$(sed -e 's/^"//' -e 's/"$//' <<<$ip_address)

	aws gamelift get-instance-access --fleet-id $fleet_id --instance-id $instance_id --query 'InstanceAccess.Credentials.Secret' --output text >$instance_id.pem

	chmod 600 $instance_id.pem

	ssh -i $instance_id.pem gl-user-remote@$ip_address
}

Remote() {
	case $fleet_os in

	"WIN_2012")
		WinRDP $1
		;;
	*)
		echo "Fleet has Linux os, connecting via SSH"
		LinuxSSH $1
		;;
	esac
}

PS3='Select instance Id to remote connect: '
select id in "${instance_list[@]}"; do
	Remote $id
	break
done
