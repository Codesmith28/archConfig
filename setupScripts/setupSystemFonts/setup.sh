#!/bin/bash

if [ $EUID -ne 0 ]; then
    echo "This should run as sudo"
    exit 1
fi


cp ./conf.d/60-latin.conf ~/.config/fontconfig/conf.d/60-latin.conf