#!/bin/bash

echo "Get Ubuntu Nerd Fonts and RecMonoCasual Nerd Fonts from Nerd fonts"
ehco "put them under /usr/share/fonts/custom/"
echo ""
sudo cp ./local.conf /etc/fonts/local.conf
echo "font confif under /etc/fonts/local.conf is now set!"
