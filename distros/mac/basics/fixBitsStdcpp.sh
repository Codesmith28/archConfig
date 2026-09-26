#!/bin/bash

echo "Searching for stdc++.h..."
HEADER_PATH=$(find /opt/homebrew/Cellar/gcc -name stdc++.h | head -n 1)

if [ -z "$HEADER_PATH" ]; then
    echo "Error: could not find stdc++.h. Is GCC installed via Homebrew?"
    exit 1
fi

echo "Found header at: $HEADER_PATH"

echo "Creating /usr/local/include/bits..."
sudo mkdir -p /usr/local/include/bits

echo "Creating symlink..."
sudo ln -sf "$HEADER_PATH" /usr/local/include/bits/stdc++.h

echo "Success! You can now use #include <bits/stdc++.h> in your C++ files."
