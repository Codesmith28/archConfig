#!/bin/bash

# check if Virtualization is supported
if [ $(egrep -c '(vmx|svm)' /proc/cpuinfo) -ge 1 ]; then
    # Install dependencies:
    sudo apt update && sudo apt install -y qemu-system-x86 qemu-utils libvirt-daemon-system libvirt-clients bridge-utils virt-manager

    # Enable service:
    sudo systemctl enable --now libvirtd

    # update user group:
    sudo usermod -aG libvirt $USER
    sudo usermod -aG kvm $USER

    echo "Setup completed!"
    echo "Please log-out and re-login into your machine"
else
    echo "Virtualization is not supported :("
fi
