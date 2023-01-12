#!/bin/bash

server=<domain>

printf "\n\n\n##### $server #####\n"

ssh root@$server "cat ~/vpn-data/pki/index.txt"

printf "\n\n"
