#!/bin/bash

if [ $EUID -ne 0 ]; then
    echo "This should run as sudo"
    exit 1
fi

# remove all the monospace fonts under /usr/share/fonts/noto && /usr/share/fonts/liberation/
rm -rf /usr/share/fonts/noto/*Mono*
rm -rf /usr/share/fonts/liberation/*Mono*

cp ./conf.d/60-latin.conf ~/dotfiles/fontconfig/conf.d/60-latin.conf
