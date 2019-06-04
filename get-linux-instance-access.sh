#!/bin/bash

#Get AWS gamelift instance access

fleet_id=
instance_id=
ip_address=

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

echo Found Instance :  $instance_id

ip_address=`aws gamelift get-instance-access --fleet-id $fleet_id --instance-id $instance_id --query 'InstanceAccess.IpAddress'`
ip_address=`sed -e 's/^"//' -e 's/"$//' <<< $ip_address `

echo Found Instance IP address :  $ip_address

aws gamelift get-instance-access --fleet-id $fleet_id --instance-id $instance_id --query 'InstanceAccess.Credentials.Secret' --output text > $instance_id.pem

chmod 600 $instance_id.pem

ssh -i $instance_id.pem gl-user-remote@$ip_address
