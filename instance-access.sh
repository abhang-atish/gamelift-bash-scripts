#!/bin/bash

machine=
fleet_id=
fleet_os=
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
fleet_os=$(echo "${instances}" | jq '.[0].OperatingSystem' | sed -e 's/^"//' -e 's/"$//')
instance_ids=$(echo "${instances}" | jq -c '.[].InstanceId')

for i in $instance_ids; do
	instance_list[${#instance_list[@]}]=$i
done

clear

# Creates a RDP file.
WinRDP() {
	instance_id=$(sed -e 's/^"//' -e 's/"$//' <<<$1)

	ip_address=$(aws gamelift get-instance-access --fleet-id $fleet_id --instance-id $instance_id --query 'InstanceAccess.IpAddress')
	ip_address=$(sed -e 's/^"//' -e 's/"$//' <<<$ip_address)

	echo "screen mode id:i:2
	use multimon:i:1
	session bpp:i:24
	full address:s:$ip_address
	audiomode:i:0
	username:s:gl-user-remote
	disable wallpaper:i:0
	disable full window drag:i:0
	disable menu anims:i:0
	disable themes:i:0
	alternate shell:s:
	shell working directory:s:
	authentication level:i:2
	connect to console:i:0
	redirectclipboard:i:1
	gatewayusagemethod:i:0
	disable cursor setting:i:0
	allow font smoothing:i:1
	allow desktop composition:i:1
	redirectprinters:i:0
	prompt for credentials on client:i:1
	autoreconnection enabled:i:1
	bookmarktype:i:3
	use redirection server name:i:0
	authoring tool:s:rdmac" | tee $instance_id.rdp

	clear

	password=$(aws gamelift get-instance-access --fleet-id $fleet_id --instance-id $instance_id --query 'InstanceAccess.Credentials.Secret')
	
	echo "Fleet instances have windows OS, check for a RDP file in script folder."
	echo password: $password
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
