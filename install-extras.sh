#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
    echo "This program must be run as root, try: sudo ./install-extras.sh" 1>&2
    exit 1
fi

if [[ -z $SUDO_USER ]]; then
    echo "This program must be run using sudo." 1>&2
    exit 1
fi

if [[ $SUDO_UID -eq 0 ]]; then
   echo "Please execute this script as a normal user using sudo." 1>&2
   exit 1
fi

echo "University of Amsterdam - E.M. Kooistra - S.J.R. van Schaik - R. de Vries"

# Install gnome-flashback-session
echo "[1/8] Installing gnome-flashback-session"
apt-get -y install gnome-session-flashback > /dev/null
gsettings set org.gnome.desktop.wm.keybindings panel-run-dialog "['<Alt>F2']"
gsettings set org.gnome.desktop.wm.preferences button-layout :minimize,maximize,close

# Set gnome-session-flashback as default
echo "[2/8] Setting gnome-session-flashback as default"
sed -i 's/user-session=ubuntu/user-session=gnome-fallback/g' /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf
sed -i 's/XSession=ubuntu/Xsession=gnome-fallback/g' /var/lib/AccountsService/users/$SUDO_USER

# Install oracle java and UvAvpn
echo "[3/8] Installing Java / UvA-VPN"
add-apt-repository -y ppa:webupd8team/java 2> /dev/null > /dev/null
add-apt-repository -y ppa:uva-informatica/uvavpn 2> /dev/null > /dev/null
apt-get -y update  > /dev/null
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
apt-get -y install oracle-java8-installer oracle-java8-set-default uvavpn > /dev/null

# Install development tools
echo "[4/8] Installing development tools"
apt-get -y install build-essential git vim valgrind flex bison gnuplot graphviz > /dev/null

# Programming languages for the programming-languages course
echo "[5/8] Installing Prolog, Erlang and Haskell"
apt-get -y install swi-prolog erlang ghc haskell-platform > /dev/null

# Install several python packages
echo "[6/8] Installing several Python packages"
apt-get -y install python-scipy python-numpy python-matplotlib python3-scipy python3-numpy python3-matplotlib > /dev/null

# Install Chromium
echo "[7/8] Installing Chromium webbrowser"
apt-get -y install chromium-browser > /dev/null

# Install LaTeX
echo "[8/8] Installing LaTeX (this can take up to 45 minutes)"
apt-get -y install texlive-full  > /dev/null

# Finish and reboot!
echo "Reboot your computer now"
