#!/bin/bash
#   ____      _     __  __             _ _                 
#  / ___| ___| |_  |  \/  | ___  _ __ (_) |_ ___  _ __ ___ 
# | |  _ / _ \ __| | |\/| |/ _ \| '_ \| | __/ _ \| '__/ __|
# | |_| |  __/ |_  | |  | | (_) | | | | | || (_) | |  \__ \
#  \____|\___|\__| |_|  |_|\___/|_| |_|_|\__\___/|_|  |___/
#                                                          
# ---------------------------------------------------------

output=$(hyprctl monitors | grep Monitor)

monitors=()

while read -r line; do
	monitor_name=$(echo "$line" | awk -F'Monitor | \\(ID [0-9]+\\):' '{print $2}')
	monitors+=("$monitor_name")
done <<< "$output"

echo "${monitors[@]}"

