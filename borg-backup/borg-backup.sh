#!/bin/bash

set -veufo pipefail

export BORG_PASSPHRASE="nrRUmPe8ce"

logname="/tmp/borg-backup-$(date +"%Y%m%d").log"
STAMP="$(date +"%Y%m%d%H%M%S")"
server=<domain>

# -c 3 = idle, $$ = current process
ionice -c 3 -p $$
renice -n 16 -p $$

# create ragnarok snapshot
btrfs subvolume snapshot -r / /SNAPSHOTS/SNAP-$STAMP-ragnarok

# Get list of LXD subvolumes
subvolumes=$(btrfs subvolume list / | grep -o " var/lib/lxd/storage-pools/lxd-pool/containers/.*$" | grep -v "/var/lib/docker/btrfs/subvolumes")

for subvol in $subvolumes
do
	lxdname=$(basename $subvol)
	btrfs subvolume snapshot -r /$subvol /SNAPSHOTS/SNAP-$STAMP-$lxdname-rootfs
done

# backup ragnarok root
printf "\n\n\n##### Backup for / at $(date +"%d.%m.%Y %H:%M:%S")\n" >>$logname
START_TIME=$SECONDS
borg create -v --stats --compression auto,zlib,6 root@$server:/mnt/storage/backup/ragnarok.datamole.cz/ragnarok-borg::"ragnarok-$STAMP-ragnarok" /SNAPSHOTS/SNAP-$STAMP-ragnarok &>>$logname
ELAPSED_TIME=$(($SECONDS - $START_TIME))


for subvol in $subvolumes
do
	lxdname=$(basename $subvol)
	# backup ragnarok's LXD container
	printf "\n\n\n##### Backup for $lxdname at $(date +"%d.%m.%Y %H:%M:%S")\n" >>$logname
	START_TIME=$SECONDS
	borg create -v --stats --compression auto,zlib,6 root@$server:/mnt/storage/backup/ragnarok.datamole.cz/ragnarok-borg::"ragnarok-$STAMP-$lxdname-rootfs" /SNAPSHOTS/SNAP-$STAMP-$lxdname-rootfs &>>$logname
	ELAPSED_TIME=$(($SECONDS - $START_TIME))
done
