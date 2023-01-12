#!/bin/bash

set -eufo pipefail

if [ ! $# -eq 1 ]
then
	printf "\n\nUsage: bash revoke-all-users-certificates.sh <username>\n\n"
	exit 1
fi

user="$1"
server=<domain>

echo "Do you want to revoke all VPN certificates for user $1?"
echo "Press enter to continue ..."
read "dummy"

set +e
# Revoke certificate on Datamole VPN
ssh root@$server "docker exec openvpn-server revoke-certificate.sh $user"
set -e
