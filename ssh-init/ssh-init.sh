#!/bin/sh

# This script will initialize ssh and rsync for CI

set -ef

log() {
    echo "[ssh-init] ${*}"
}

# Install openssh-client and rsync packages
log 'Install openssh-client and rsync package'

# Alpine
if command -v apk >/dev/null; then
    apk --no-cache add openssh-client rsync
fi

# Debian based
if command -v apt-get >/dev/null; then
    apt-get update --yes
    apt-get install --yes openssh-client rsync
fi

# Load ssh-agent
log 'Starting ssh-agent'
eval $(ssh-agent -s)

# Create .ssh directory with the correct permissions
log 'Creating .ssh directory'
( umask 077 && mkdir -p ~/.ssh )

# Load SSH private key if exists
if [ -z "$SSH_PRIVATE_KEY" ]; then
    log 'Varible SSH_PRIVATE_KEY does not exist or is empty'
else
    # Load SSH private key into ssh-agent
    log 'Loading SSH private key to ssh-agent'
    echo "$SSH_PRIVATE_KEY" | tr -d '\r' | ssh-add - >/dev/null

    # Dump SSH private key into file
    log 'Dumping SSH private key to ~/.ssh/id_ed25519'
    ( umask 077 && echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_ed25519 )
fi

# Dump SSH_KNOWN_HOSTS into file or disable host key checking
if [ -z "$SSH_KNOWN_HOSTS" ]; then
    log 'Disabling StrictHostKeyChecking'
    echo 'StrictHostKeyChecking no' > ~/.ssh/config
else
    log 'Dumping SSH_KNOWN_HOSTS into ~/.ssh/known_hosts'
    ( umask 133 && echo "$SSH_KNOWN_HOSTS" > ~/.ssh/known_hosts )