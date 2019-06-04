#!/bin/bash

#Get AWS gamelift instance access

fleet_id=
instance_id=
ip_address=
password=
status=true

echo -n "Enter fleet id: "

read fleet_id

if [ -n  "$fleet_id" ]; then
    fleet_id=$fleet_id
else
    echo "Please enter fleet id"
    exit 1
fi


instance_id=` aws gamelift describe-instances --fleet-id $fleet_id --query 'Instances[0].InstanceId' `
instance_id=` sed -e 's/^"//' -e 's/"$//' <<< $instance_id `

ip_address=` aws gamelift get-instance-access --fleet-id $fleet_id --instance-id $instance_id --query 'InstanceAccess.IpAddress' `
ip_address=`sed -e 's/^"//' -e 's/"$//' <<< $ip_address `

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
authoring tool:s:rdmac" | tee $fleet_id.rdp

clear

password=`aws gamelift get-instance-access --fleet-id $fleet_id --instance-id $instance_id --query 'InstanceAccess.Credentials.Secret'`

status=true
echo password: $password

