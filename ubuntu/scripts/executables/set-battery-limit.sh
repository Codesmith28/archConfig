#!/bin/bash
echo 90 | sudo tee /sys/class/power_supply/BAT0/charge_control_end_threshold
