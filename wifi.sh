#!/bin/bash
#
# cyrille <cyrille@cbiot.fr>
# https://framagit.org/CyrilleBiot/wifi-issues
# https://cbiot.fr/
#
# Script d'aide au diagnostic de problèmes wifi
#

# Test des droits admin
if [ "$EUID" -ne 0 ]; then
    echo "Lancer ce script en mode administrateur"
    echo "Utiliser sudo wifi.sh"
    echo "Ou un accès root : sudo -s"
    exit 1
fi

# -----------------------------
# Vérification des paquets nécessaires
# -----------------------------
packages=(rfkill xclip mokutil)
missing=()

echo
for pkg in "${packages[@]}"; do
    printf "Vérification de %s... " "$pkg"
    if dpkg -s "$pkg" &>/dev/null; then
        echo "installé"
    else
        echo "absent"
        missing+=("$pkg")
    fi
done

if [ ${#missing[@]} -gt 0 ]; then
    echo -e "\nPaquets à installer : ${missing[*]}"
    echo "Mise à jour des listes de paquets..."
    if ! apt-get update -y; then
        echo "Échec de apt-get update. Vérifie la connexion réseau ou les sources APT."
        exit 2
    fi

    echo "Installation..."
    if ! apt-get install -y "${missing[@]}"; then
        echo "Échec lors de l'installation de : ${missing[*]}"
        exit 3
    fi
fi

echo -e "\nTous les paquets nécessaires sont installés.\n"

# -----------------------------
# Collecte d'informations Wi-Fi
# -----------------------------
export DISPLAY=:0

# Carte réseau
CARTE_RESEAU=$(lspci -nnd ::0280)
# Prise en charge par le kernel
PRISE_EN_CHARGE=$(lspci -nnkd ::0280)
# Présence firmware
PRESENCE_FIRMWARE=$(ip a)
# Firmware manquant
FIRMWARE_MANQUANT=$(dmesg | grep firmware)
# Verrouillage soft / hard
VERROUILLAGE=$(rfkill list)
# IP Box
IP_BOX=$(ip r | grep default | awk '{print $3}')
# Ping vers la box
if [ -n "$IP_BOX" ]; then
    PING=$(ping -c 3 "$IP_BOX" 2>&1)
else
    PING="Impossible de déterminer l'IP de la box"
fi
# Version kernel
KERNEL=$(uname -a)
# Liste des kernels installés
KERNEL_INSTALLES=$(dpkg --list | grep linux-image | grep ii)
# Secure Boot
SECURE_BOOT=$(mokutil --sb-state 2>/dev/null || echo "mokutil non disponible")

# -----------------------------
# Génération du fichier texte
# -----------------------------
TMPFILE=$(mktemp /tmp/wifi_report.XXXXXX)

cat <<EOF > "$TMPFILE"
Carte réseau :
$CARTE_RESEAU

Prise en charge par le kernel :
$PRISE_EN_CHARGE

Présence firmware (ip a) :
$PRESENCE_FIRMWARE

Firmware manquant :
$FIRMWARE_MANQUANT

Verrouillage soft / hard :
$VERROUILLAGE

IP Box :
$IP_BOX

Ping vers la box :
$PING

Kernel :
$KERNEL

Kernel(s) installé(s) :
$KERNEL_INSTALLES

Secure Boot :
$SECURE_BOOT
EOF

# Affichage sur sortie standard
cat "$TMPFILE"

# Copie dans le presse-papier de l'utilisateur principal
USER_MAIN=$(logname 2>/dev/null || echo "$SUDO_USER")
if [ -n "$USER_MAIN" ] && command -v xclip &>/dev/null; then
    cat "$TMPFILE" | sudo -u "$USER_MAIN" xclip -selection clipboard
fi

# Suppression fichier temporaire
rm "$TMPFILE"
