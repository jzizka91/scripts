#! /bin/bash

lfs_dir="<gitlab_lfs_dir>"
repo_dir="<gitlab_repo_dir>"

server="<domain>"
project_bare=$1
project_clonned=$(echo $project_bare | sed 's/.git//')
project_url=$2
project_lfs_objects_dir="$project_clonned/.git/lfs/objects"

# Search for the project name and save it's path into a variable
repo=$(ssh root@$server find $repo_dir -type d -name $project_bare)

if [[ -n $repo ]]; then
    # Download project from gitlab backup
    echo "Hold on. Downloading $project_bare repository..."
    rsync -a root@$server:$repo .

    # Clone the project repository
    echo "Cloning $project_bare repository..."
    git clone $project_bare

    # Set new origin for clonned project
    echo "Setting new origin for $project_clonned to $project_url"
    cd $project_clonned
    git remote remove origin
    git remote add origin $project_url

    # Fetch all LFS objects
    echo "Fetching LFS objects..."
    git lfs fetch --all || true && cd ..

    # Print restore success message
    echo "Hold on. Restoring all lfs files for $project_clonned now. It might take a couple of minutes..."
    echo "-----------------------------------------------------------------------------------"

    # Restore project lfs_objects
    for lfs_objects_all_dir in $(find DatamoleUI/.git/lfs/objects -mindepth 2 -maxdepth 4 -type d | cut -d/ -f 5-6)
    do
        for lfs_objects_dir in $lfs_objects_all_dir
        do
            # Get all lfs files per each gitlab/lfs-objects/xx/xx directory
            lfs_files=$(ssh root@$server ls -al $lfs_dir/$lfs_objects_dir/ | grep '^-' | awk '{print $9}')
            
            for lfs_file_single in $lfs_files
            do
                # Get single lfs file per each gitlab/lfs-objects/xx/xx directory
                lfs_file=$(echo $lfs_file_single)

                for lfs_file_check in $lfs_file
                do
                    # Check if the lfs_file name(ref.name) in the gitlab backup repository matches to the name get from the "git lfs ls-files" list.
                    lfs_file_status=$(cd $project_clonned && git lfs ls-files --all --long | grep -c "$lfs_file_check")
                    
                    # If lfs_the file matches restore it with the name that matches to the name in lfs list.
                    if [[ $lfs_file_status -gt 0 ]]; then
                        lfs_file_info=$(cd $project_clonned && git lfs ls-files --all --long | grep "$lfs_file_check")
                        lfs_file_ref_name=$(echo $lfs_file_info | cut -d- -f 1-1)
                        lfs_path_full=${lfs_file_info#*-?}
                        lfs_real_name=$(basename "$lfs_path_full")

                        # Restore lfs_objects into correct directories.
                        echo "LFS File Real Name: $lfs_real_name"
                        echo "LFS File Ref Name: $lfs_file_ref_name"
                        echo "-----------------------------------------------------------------------------------"
                        rsync root@$server:$lfs_dir/$lfs_objects_all_dir/$lfs_file_check $project_lfs_objects_dir/$lfs_objects_all_dir/$lfs_file_ref_name
                    else
                        continue
                    fi
                done
            done  
        done
    done

    # Print restore success message
    echo -e "\033[32mYour project $project_clonned and it's all lfs_objects was successfully restored.\033[m"    
else
    # Close, if project wasn't found
    echo "$project_bare wasnt't found. Closing ..."
fi