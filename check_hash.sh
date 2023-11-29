#!/bin/bash

# Set the file path containing subdirectories and hashes
hashes_file="submodule_hash_ls.txt"

# Set the parent directory path
parent_dir="/root/build2/parts"

# Read each line
while IFS=' ' read -r subdir desired_hash; do
    # Construct the complete tree directory path
    tree_dir="${parent_dir}/${subdir}/tree"

    # Check if the directory exists
    if [ -d "${tree_dir}" ]; then
        echo "Checking ${tree_dir}..."

        # Go to tree directory
        cd "${tree_dir}"

        # Get the current Git hash
        current_hash=$(git rev-parse HEAD)

        # Compare the current hash with the desired hash
        if [ "$current_hash" != "$desired_hash" ]; then
            # Checkout the desired hash
            git checkout "$desired_hash"
        else
            echo "Already at desired hash in ${subdir}."
        fi

        # Go back to the parent directory
        cd "${parent_dir}"
    else
        echo "Directory ${tree_dir} does not exist or is not a Git repository."
    fi
done < "$hashes_file"
