#!/usr/bin/env bash
tput reset

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

if ! `lsb_release -c | grep -q bionic`; then
    echo "This script is recommended to be executed on a machine running Ubuntu 18.04 LTS"
    if ! check_answer "Do you wish to continue?"; then exit 1; fi
fi

echo "Installation script
University of Amsterdam

Made by:
 - E.M. Kooistra
 - S.J.R. van Schaik
 - R. de Vries
 - L.A. van Hijfte
 - S.J.N. van den Broek
 "
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

function aset {
    ${1#*,}
}

function check_answer {
    while true; do
        read -p "$1 (Y/n) " answer
        case $answer in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Pleases answer yes (y) or no (n)";;
        esac
    done
}

function install_app {
    app=$1
    echo -ne "$2 Installing ${app%;*}..."
    ${app#*;} &> install_extras_log
    if [[ $? -ne 0 ]]; then
        echo -e "\r$2 ${red}Something went wrong when installing ${app%;*}.${reset}"
        if check_answer "Would you like to read the log file?"; then
            less install_extras_log
        fi
    else
        echo -e "\r$2 ${green}Installed ${app%;*}${reset}    "
    fi
}

function initialize {
    # Add repositories
    add-apt-repository -y ppa:uva-informatica/meta-packages &&
    add-apt-repository -y ppa:webupd8team/java &&
    add-apt-repository -y ppa:uva-informatica/sim-pl &&
    add-apt-repository -y ppa:uva-informatica/uvavpn &&
    # Load repositories
    apt -y update &&
    # Configuring java
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
}

# Mandatory
function install_java {
    apt -y install oracle-java8-installer &&
    apt -y install oracle-java8-set-default
}
function install_simpl {
    apt -y install sim-pl
}
function install_uvavpn {
    apt -y install uvavpn
}
function install_uva_packages {
    apt -y install informatica-common informatica-jaar-1
}
function install_python {
    apt -y install python-scipy python-numpy python-matplotlib python3-scipy python3-numpy python3-matplotlib
}
function upgrade {
    apt -y upgrade
}

# Recommended
function install_atom {
    # Add repositories
    add-apt-repository -y ppa:webupd8team/atom &&
    # Load repositoriy
    apt -y update &&
    # Install atom
    apt -y install atom
}

# Additional
function install_chromium {
    apt -y install chromium-browser
}

mandatory=("Java;install_java"
           "SIM-PL;install_simpl"
           "UvA-VPN;install_uvavpn"
           "UvA-packages;install_uva_packages"
           "Python-packages;install_python")

recommended=("Atom;install_atom")

optional=("Chromium;install_chromium")

echo -ne "Initializing..."
initialize &> install_extras_log
echo -e "\rInstalling packages..."

total=$(( ${#mandatory[@]} + ${#recommended[@]} + ${#optional[@]} ))
for ((i=0; i < ${#mandatory[@]}; i++)) do
    install_app ${mandatory[$i]} "[$((i + 1))/$total]"
done
for ((i=0; i < ${#recommended[@]}; i++)) do
    tag=[$((i + ${#mandatory[@]} + 1))/$total]
    if check_answer "$tag Would you like to install ${recommended[$i]%;*} (recommended)?"; then
        install_app ${recommended[$i]} $tag
    fi
done
for ((i=0; i < ${#optional[@]}; i++)) do
    tag=[$((i + ${#mandatory[@]} + ${#recommended[@]} + 1))/$total]
    if check_answer "$tag Would you like to install ${optional[$i]%;*} (optional)?"; then
        install_app ${optional[$i]} $tag
    fi
done
