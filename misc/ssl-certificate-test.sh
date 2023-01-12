#!/bin/bash

set -eufo pipefail

pages="datamole.cz"

for web in $pages
do
	printf "\n\n##### Page: $web\n"
	echo \
	  | openssl s_client -showcerts -servername $web -connect ${web}:443 2>/dev/null \
	  | openssl x509 -inform pem -noout -text \
	  | grep -A 2 "Validity"
done

printf "\n\n"

