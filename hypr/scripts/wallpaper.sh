#!/bin/bash
#                _ _                              
# __      ____ _| | |_ __   __ _ _ __   ___ _ __  
# \ \ /\ / / _` | | | '_ \ / _` | '_ \ / _ \ '__| 
#  \ V  V / (_| | | | |_) | (_| | |_) |  __/ |    
#   \_/\_/ \__,_|_|_| .__/ \__,_| .__/ \___|_|    
#                   |_|         |_|               
# ----------------------------------------------------- 

case $1 in

	# Load wallpaper from .cache of last session 
	"init")
	if [ -f ~/.cache/wallpaper/current_wallpaper.jpg ]; then
		rm ~/.cache/wal/schemes/*current_wallpaper_jpg*
		wal -q -i ~/.cache/wallpaper/current_wallpaper.jpg
	else
		wal -q -i ~/dotfiles/wallpaper/
	fi
	;;

	# Select wallpaper with rofi
	"select")
	selected=$(ls -1 ~/dotfiles/wallpaper | grep "jpg" | rofi -dmenu -replace -config ~/dotfiles/rofi/config-wallpaper.rasi)
	if [ ! "$selected" ]; then
		echo "No wallpaper selected"
		exit
	fi
	wal -q -i ~/dotfiles/wallpaper/$selected
	;;

	# Randomly select wallpaper 
	*)
	wal -q -i ~/dotfiles/wallpaper/
	;;

esac

# ----------------------------------------------------- 
# Load current pywal color scheme
# ----------------------------------------------------- 
source "$HOME/.cache/wal/colors.sh"
echo "Wallpaper: $wallpaper"

# ----------------------------------------------------- 
# Copy selected wallpaper into .cache folder
# ----------------------------------------------------- 
cp $wallpaper ~/.cache/wallpaper/current_wallpaper.jpg

# ----------------------------------------------------- 
# get wallpaper image name
# ----------------------------------------------------- 
newwall=$(echo $wallpaper | sed "s|$HOME/dotfiles/wallpaper/||g")

# ----------------------------------------------------- 
# Reload waybar with new colors
# -----------------------------------------------------
~/dotfiles/waybar/launch.sh

# ----------------------------------------------------- 
# Set the new wallpaper
# -----------------------------------------------------
transition_type="wipe"
# transition_type="outer"
# transition_type="random"

swww img $wallpaper \
	--transition-bezier .43,1.19,1,.4 \
	--transition-fps=60 \
	--transition-type=$transition_type \
	--transition-duration=0.7 \
	--transition-pos "$( hyprctl cursorpos )"

# ----------------------------------------------------- 
# Send notification
# ----------------------------------------------------- 
sleep 1
notify-send "Colors and Wallpaper updated" "with image $newwall"

echo "DONE!"
