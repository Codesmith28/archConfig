cat <<"EOF"
     _             _
 ___| |_ __ _ _ __| |_ _   _ _ __
/ __| __/ _` | '__| __| | | | '_ \
\__ \ || (_| | |  | |_| |_| | |_) |
|___/\__\__,_|_|   \__|\__,_| .__/
                            |_|

EOF

#!/bin/bash

# Set the startup script
echo "Setting the startup apps for arch linux..."
startup_dir=~/.config/systemd/user
mkdir -p $startup_dir
echo "Created startup directory: $startup_dir"

# Function to set up a service
setup_service() {
    local service_name=$1
    local service_file="${service_name}.service"

    echo "Setting up ${service_name} startup script..."
    echo "Checking for ${service_file} in current directory..."
    if [ -f "./${service_file}" ]; then
        echo "${service_file} found. Copying to $startup_dir..."
        cp -v "./${service_file}" "$startup_dir"
        echo "Enabling ${service_file}..."
        systemctl --user enable "${service_file}"
        echo "Starting ${service_file}..."
        systemctl --user start "${service_file}"
        echo "${service_name^} startup script set!"
    else
        echo "Error: ${service_file} not found in the current directory."
        echo "Current directory contents:"
        ls -l
    fi
}

# Set up Discord
setup_service "discord"

# Set up Slack
setup_service "slack"

echo "Script execution completed."
