#!/bin/bash

# Define paths and variables
d_drive_path="/mnt/d"
backup_internal="/mnt/c/backup_internal_gateway"
backup_external="${d_drive_path}/backup_external_warehouse"
backup_queue="${backup_internal}/backup_queue"
log_dir="${backup_internal}/logs"
external_log_dir="${backup_external}/logs"
current_date=$(date +%F-%H-%M-%S)
temp_backup_dir="${backup_queue}/backup-${current_date}"
log_file="${log_dir}/log-${current_date}.log"
execution_status=""
tree_output=""

# Define the list of files and folders to backup
backup_items=(
    "/home/obs1230/.bashrc"
    "/home/obs1230/.bash_aliases"
    "/home/obs1230/Code/"
)

# Define exclusion patterns
exclude_patterns=(
    "--exclude=.venv"
    "--exclude=.git"
    "--exclude=lib"
    "--exclude=lib64"
    "--exclude=bin"
    "--exclude=share"
    "--exclude=node_modules"
    "--exclude=__pycache__"

    "--exclude=sandbox/images"
)

# Append message to execution status
append_status() {
    execution_status+="$1\n"
    echo $1
}

# Save log contents to file
save_log() {
    echo -e "Backup directory tree:\n$tree_output\n\nExecution Status:\n$execution_status" > "$log_file"
    echo "Saved log to internal gateway backup queue"
}

# Mount the D: drive
mount_d_drive() {
    if [ ! -d "$d_drive_path" ]; then
        mkdir -p "$d_drive_path"
        sudo mount -t drvfs D: $d_drive_path
        append_status "Mounted D: drive at $d_drive_path"
    fi
}

# Check directory existence
check_directory() {
    if [ ! -d "$1" ]; then
        append_status "$2 does not exist. Error backing up"
        save_log
        exit 1
    fi
}

# Manage the backup queue
manage_backup_queue() {
    mkdir -p "$backup_queue"
    local count=$(find "$backup_queue" -maxdepth 1 -name 'backup-*.zip' | wc -l)
    if [ $count -ge 10 ]; then
        local oldest=$(ls -t1 "$backup_queue"/backup-*.zip | tail -1)
        rm -f "$oldest"
        append_status "Deleted oldest backup from queue: $oldest"
    fi
}

# Copy the wanted files into the temporary directory
copy_backup_files() {
    # Ensure the destination directory exists
    mkdir -p "$temp_backup_dir/backups"

    # Iterate over the array of items
    for item in "${backup_items[@]}"; do
        # Use rsync for copying with exclusion patterns
        rsync -av "${exclude_patterns[@]}" "$item" "$temp_backup_dir/backups" 2>>"$temp_backup_dir/copy_errors.log"
    done

    append_status "Backup files copied into the temp directory"
}

# Create the zip file in the backup queue
create_zip_file() {
    mkdir $temp_backup_dir
    mkdir -p "${temp_backup_dir}/backups"
    if [ -d "$temp_backup_dir" ] && [ "$(ls -A $temp_backup_dir)" ]; then
        copy_backup_files        
        tree_output=$(tree "${temp_backup_dir}/backups")
        append_status "Backup directory tree captured:$'\n'"$tree_output
    else
        append_status "Backup directory is empty or does not exist"
        save_log
        return 1
    fi

    local zip_file="${backup_queue}/backup-${current_date}.zip"
    if cd "$temp_backup_dir" && zip -r "$zip_file" ./*; then
        append_status "Temporary backup directory successfully zipped to file in queue"
    else
        append_status "Error zipping backup directory"
        save_log
        exit 1
    fi
    rm -rf "$temp_backup_dir"
}

# Copy the zip file to the external warehouse
copy_zip_to_warehouse() {
    local zip_file="${backup_queue}/backup-${current_date}.zip"
    if [ -f "$zip_file" ]; then
        if [ -d "$backup_external" ]; then
            cp "$zip_file" "$backup_external"
            append_status "Copied backup zip to external warehouse"
        else
            append_status "Backup destination on D: drive does not exist. Backup zipped to queue but not moved to warehouse"
        fi
    else
        append_status "Zip file does not exist in the queue. Cannot copy to warehouse"
    fi
}

# Copy log file to external warehouse
function copy_log_to_warehouse() {
    cp $log_file $external_log_dir
    echo "Copied log to external warehouse"
}

# Function to print folder sizes
print_folder_sizes() {
    # Directory to analyze (replace with your directory path)
    directory_to_analyze="/home/obs1230/Code"
    echo "Calculating sizes of subdirectories in $directory_to_analyze..."
    find "$directory_to_analyze" -type d -not -path "$directory_to_analyze" -exec du -sh {} + | sort -hr
}

# Main function to execute the backup script
main() {
    mount_d_drive
    check_directory "$backup_internal" "Internal backup directory"
    check_directory "$backup_external" "External backup warehouse"

    manage_backup_queue
    create_zip_file
    copy_zip_to_warehouse
    save_log
    copy_log_to_warehouse
}

main
# print_folder_sizes