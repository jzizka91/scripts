#!/bin/bash

set -veufo pipefail

server=<domain>
# Regenerate CRLs for VPN(s)
ssh -t root@$server "docker exec openvpn /bin/sh -c 'cd /vpn && ./easyrsa gen-crl'"
