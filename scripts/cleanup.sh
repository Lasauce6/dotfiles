#!/bin/bash
#       _                                 
#   ___| | ___  __ _ _ __    _   _ _ __   
#  / __| |/ _ \/ _` | '_ \  | | | | '_ \  
# | (__| |  __/ (_| | | | | | |_| | |_) | 
#  \___|_|\___|\__,_|_| |_|  \__,_| .__/  
#                                 |_|     
# ----------------------------------------------------- 

yay -Scc
su -c 'pacman -Qtdq | pacman -Rns -'
su -c 'pacman -Qqd | pacman -Rsu -'
