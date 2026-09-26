# Troubleshooting: Fixing `<bits/stdc++.h>` on macOS

## Problem
On macOS, Clang is the default compiler and Apple SDK headers do not include GNU's `<bits/stdc++.h>` (commonly used in competitive programming and GCC projects).

## Solution

1. Install modern GCC via Homebrew:
   ```bash
   brew install gcc
   ```

2. Symlink `stdc++.h` into `/usr/local/include/bits/`:
   ```bash
   HEADER_PATH=$(find /opt/homebrew/Cellar/gcc -name stdc++.h 2>/dev/null | head -n 1)
   sudo mkdir -p /usr/local/include/bits
   sudo ln -sf "$HEADER_PATH" /usr/local/include/bits/stdc++.h
   ```

3. Compile with modern GCC (`g++-14`, `g++-15`, `g++-16`):
   ```bash
   # Use the automated run_cpp helper from your shell:
   run_cpp solution.cpp
   ```
