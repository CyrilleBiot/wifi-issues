#!/bin/bash
#
# cyrille <cyrille@cbiot.fr>
# 
# https://framagit.org/CyrilleBiot/wifi-issues
# https://cbiot.fr/
# 
# Soucis aider au diagnostic de problèmes wifi
#
#

# Test des droits admin
if [ "$EUID" -ne 0 ]
  then 
  	echo "Lancer ce script en mode administrateur"
  	echo "Utiliser sudo wifi.sh"
  	echo "Ou un accès root : sudo -s "
  exit
fi

# Test de la présence des paquets nécessaires

dpkg -s rfkill  &> /dev/null

if [ $? -eq 0 ]; then
    echo -e "\n\nrfkill est installé. Continuons.\n\n"
else
    echo -e "\n\nrfkill n'est pas installé. Installons le !\n\n"
    apt install -y rfkill 
fi


# Nécessaire pour le presse papier
export DISPLAY=:0


# Identifier la carte réseau
CARTE_RESEAU=$(lspci -nnd ::0280)

# prise en charge par un module du noyau. 
PRISE_EN_CHARGE=$(lspci -nnkd ::0280)


# Présence du firmware
PRESENCE_FIRMWARE=$(ip a)

# Firmware manquant
FIRMWARE_MANQUANT=$(dmesg | grep firmware)

#  verrouillage soft / hard 
VERROUILLAGE=$(rfkill list)

# IP BOX
IP_BOX=$(ip r | grep default | cut -d " " -f 3)

# PING BOX
PING=$(ping $IP_BOX -c 3)

# VERSION KERNEL
KERNEL=$(uname -a)

# Liste des kernels installés
KERNEL_INSTALLES=$(dpkg --list | grep linux-image | grep ii)

echo -e "Carte réseau : \n $CARTE_RESEAU \n\n" > tmp.wifi.txt

echo -e "Prise en charge par le kernel :  \n$PRISE_EN_CHARGE \n\n" >> tmp.wifi.txt

echo -e "Présence firmware (ip _a) : \n$PRESENCE_FIRMWARE \n\n" >> tmp.wifi.txt

echo -e "Firmware manquant :  \n$FIRMWARE_MANQUANT \n\n" >> tmp.wifi.txt

echo -e "Verrouillage soft / hard :  \n$VERROUILLAGE \n\n" >> tmp.wifi.txt

echo -e "IPBox : \n$PING\n\n" >> tmp.wifi.txt

echo -e "Ping vers la box : \n$PING\n\n" >> tmp.wifi.txt

echo -e "Kernel : \n$KERNEL  \n\n" >> tmp.wifi.txt

echo -e "Kernel(s) installé(s) : \n$KERNEL_INSTALLES  \n\n" >> tmp.wifi.txt

# Affichage sur sortie standard
cat tmp.wifi.txt

# Copie dans le presse papier
cat tmp.wifi.txt | sudo -u $(cat /etc/passwd | grep 1000 | cut -d ":" -f 1) xclip -selection clipboard

# Suppression fichier temporaire
rm tmp.wifi.txt
