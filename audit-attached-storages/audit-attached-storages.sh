#!/bin/bash

#------------------------------------------------------------------------------------------------------------------------------------
# THIS SCRIPT WILL AUDIT ALL ATTACHED STORAGES ACROSS ALL NODES AND SAVE THEIR STORAGE PATH(S) INTO A FILE IN CURRENT DIRECTORY.
#------------------------------------------------------------------------------------------------------------------------------------
nodes=(
    <node1-domain>
    <node2-domain>
    <node3-domain>
    <node4-domain>
)
for n in ${nodes[*]}
do
    # List all LXD Containers in node.
    containers_list=$(ssh root@$n lxc list --format csv | grep RUNNING | cut -d, -f 1-1)
    for c in $containers_list;
    do
        # Get list of attached storages in container.
        storage_list=$(ssh root@$n lxc config show $c | grep source | cut -d ' ' -f  6-7)
        # If container have some attached storages, save that information into a file.
        if [ -n "$storage_list" ]; then
            echo -e "Container: $c\nStorages:\n$storage_list\n--------------------------------------------------------------------------" >> ./storage_audit
            echo "$c - Storage(s) was found!"
        # If container don't have any attached storages, save that information into the file.       
        else
            echo -e "Container: $c\nStorages:\nNo storages attached to this container!\n--------------------------------------------------------------------------" >> ./storage_audit
            echo "$c - No Storage found!"
        fi
    done
done
