#!/bin/bash
#  ___           _        _ _   _   _           _       _             
# |_ _|_ __  ___| |_ __ _| | | | | | |_ __   __| | __ _| |_ ___  ___  
#  | || '_ \/ __| __/ _` | | | | | | | '_ \ / _` |/ _` | __/ _ \/ __| 
#  | || | | \__ \ || (_| | | | | |_| | |_) | (_| | (_| | ||  __/\__ \ 
# |___|_| |_|___/\__\__,_|_|_|  \___/| .__/ \__,_|\__,_|\__\___||___/ 
#                                    |_|                              
# ----------------------------------------------------- 
# Required: yay trizen timeshift btrfs-grub
# ----------------------------------------------------- 

sleep 1
clear

cat <<"EOF"
 _   _           _       _            
| | | |_ __   __| | __ _| |_ ___  ___ 
| | | | '_ \ / _` |/ _` | __/ _ \/ __|
| |_| | |_) | (_| | (_| | ||  __/\__ \
 \___/| .__/ \__,_|\__,_|\__\___||___/
      |_|                             

EOF

_isInstalledYay() {
	package="$1";
	check="$(yay -Qs --color always "${package}" | grep "local" | grep "${package} ")";
	if [ -n "${check}" ] ; then
		echo 0; #'0' means 'true' in Bash
		return; #true
	fi;
	echo 1; #'1' means 'false' in Bash
	return; #false
}

# ------------------------------------------------------
# Confirm Start
# ------------------------------------------------------

while true; do
	read -p "DO YOU WANT TO START THE UPDATE NOW? (Yy/Nn): " yn
	case $yn in
		[Yy]* )
			echo ""
			break;;
		[Nn]* ) 
			exit;
			break;;
		* ) echo "Please answer yes or no.";;
	esac
done

if [[ $(_isInstalledYay "Timeshift") == 1 ]];
then
	while true; do
		read -p "DO YOU WANT TO CREATE A SNAPSHOT? (Yy/Nn): " yn
		case $yn in
			[Yy]* )
				echo ""
				read -p "Enter a comment for the snapshot: " c
				sudo timeshift --create --comments "$c"
				sudo timeshift --list
				sudo grub-mkconfig -o /boot/grub/grub.cfg
				echo "DONE. Snapshot $c created!"
				echo ""
				break;;
			[Nn]* ) 
				break;;
			* ) echo "Please answer yes or no.";;
		esac
	done
fi

echo "-----------------------------------------------------"
echo "Start update"
echo "-----------------------------------------------------"
echo ""

yay

notify-send "Update complete"
