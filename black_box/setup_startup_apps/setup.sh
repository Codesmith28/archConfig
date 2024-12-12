#!/bin/bash

cat <<"EOF"
     _             _
 ___| |_ __ _ _ __| |_ _   _ _ __
/ __| __/ _` | '__| __| | | | '_ \
\__ \ || (_| | |  | |_| |_| | |_) |
|___/\__\__,_|_|   \__|\__,_| .__/
                            |_|
EOF


echo "Setting the startup apps for arch linux..."
STARTUP_DIR=~/dotfiles/systemd/user

setup_service() {
    local service_name=$1
    local service_file="${service_name}.service"

    echo "Setting up ${service_name} startup script..."
    echo "Checking for ${service_file} in current directory..."

    if [ -f "./${service_file}" ]; then
        echo "${service_file} found."

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

for service in $(ls ${STARTUP_DIR}/*.service); do
    echo "Setting up $(basename -s .service $service) startup script..."
    setup_service $(basename -s .service $service)
done

echo "Script execution completed."
