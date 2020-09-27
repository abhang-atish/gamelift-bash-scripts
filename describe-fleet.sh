#!/bin/bash

#Get AWS gamelift instance access

fleet_id=

echo -n "Enter fleet id: "
read fleet_id
 if [ -n  "$fleet_id" ]; then
      fleet_id=$fleet_id
 fi

aws gamelift describe-instances --fleet-id $fleet_id

