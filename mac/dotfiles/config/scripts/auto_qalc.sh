#!/usr/bin/expect -f

# Start qalc
spawn qalc

# Wait for the prompt (which is usually "> ")
expect "> "

# Send the "set autocalc" command
send "set autocalc\r"

# Interact hands control back to you
interact
