#!/bin/bash

set -eufo pipefail

if [ ! $# -eq 1 ]
then
	printf "\n\nUsage: bash create-datamole-vpn-user.sh <username>\n\n"
	exit 1
fi

user="$1"
server="<domain>"

# create user
ssh root@$domain "docker exec openvpn-server create-user.sh $user"

# download created files
scp root@$domain:/opt/openvpn/clients/$user/${user}-bundle.ovpn ${user}-datamole-bundle.ovpn
