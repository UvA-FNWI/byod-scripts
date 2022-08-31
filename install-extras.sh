#!/usr/bin/env bash
TITLE="
Installation script
University of Amsterdam

Made by:
 - E.M. Kooistra
 - S.J.R. van Schaik
 - R. de Vries
 - B. Terwijn
 - L.A. van Hijfte
 - S.J.N. van den Broek
 - S.R.W. van Kampen
 - R.K. Slot

Source: https://github.com/UvA-FNWI/byod-scripts
Contact: laptops-fnwi@uva.nl
"
LOGFILE="install_extras.log"

function check_answer {
    while true; do
        read -p "$1 (Y/n) " answer
        case $answer in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes (y) or no (n)";;
        esac
    done
}

if [[ $EUID -ne 0 ]]; then
    sudo $0
    exit $?
fi

if [[ -z $SUDO_USER ]]; then
    echo "This program must be run using sudo." 1>&2
    exit 1
fi

if [[ $SUDO_UID -eq 0 ]]; then
   echo "Please execute this script as a normal user using sudo." 1>&2
   exit 1
fi

if ! `lsb_release -c | grep -q jammy`; then
    echo "This script is recommended to be executed on a machine running Ubuntu 22.04 LTS"
    if ! check_answer "Do you wish to continue?"; then exit 1; fi
fi

# Sets colors if supported else they are empty.
if [ $(bc <<< "`(tput colors) 2>/dev/null || echo 0` >= 8") -eq 1 ]; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 11)
    BLUE=$(tput setaf 4)
    BOLD=$(tput bold)
    RESET=$(tput sgr0)
fi

tput reset
echo -e "${TITLE}"
echo "Starting installation" > ${LOGFILE}

function run_step {
    step=$1
    index=$2
    total=$3
    echo -ne "${YELLOW}[$index/$total]${RESET} Running: ${step%;*}..."
    echo -e "\n\n\n#############################################
#############################################
RUNNING STEP: ${step%;*}
#############################################
#############################################\n" &>> ${LOGFILE}
    ${step#*;} &>> ${LOGFILE}
    if [[ $? -ne 0 ]]; then
        echo -e "\r[$index/$total] ${RED}Something went wrong when running '${step%;*}'.${RESET}"
        if check_answer "Would you like to read the log file?"; then
            less ${LOGFILE}
        fi
    else
        # Spaces are required to fully overwrite the previous line
        echo -e "\r${YELLOW}[$index/$total] ${GREEN}Done: ${step%;*}${RESET}               "
    fi
}

function add_universe_repository {
    add-apt-repository -y universe
}

function install_uvavpn {
    if [ -z "$(nmcli con | grep 'UvA')" ];
    then
        # Gnome settings adds "VPN" to the name, so while it is
        # called just "UvA" here it will show up as "UvA VPN"
        apt-get -y install network-manager-openconnect-gnome
        nmcli con add type vpn \
                con-name "UvA" \
                ifname "*" \
                vpn-type openconnect \
                -- \
                vpn.data "gateway=uvavpn.uva.nl,protocol=nc"
    else
        echo "UvA VPN already configured"
    fi
}

function install_ai_bashrc {
    su "$SUDO_USER" -c ' mkdir -p ~/bin;
if [ -z "`grep \"BscKI\" ~/.bashrc`" ]; then
    echo "" >> ~/.bashrc;
    echo "# byod BscKI settings" >> ~/.bashrc;
    echo "export PATH=\$PATH:~/bin" >> ~/.bashrc;
    echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/lib" >> ~/.bashrc;
    echo "export EDITOR=/usr/bin/emacs" >> ~/.bashrc;
    echo "alias o=gnome-open" >> ~/.bashrc;
    echo "alias e=emacs" >> ~/.bashrc;
fi'
}

# Install functions
function install_prolog {
    apt-get -y install swi-prolog emacs emacs-goodies-extra-el

    su "$SUDO_USER" -c ' echo "(setq auto-mode-alist (cons (cons \"\\\\.pl\" '\''prolog-mode) auto-mode-alist))" >> ~/.emacs '
    su "$SUDO_USER" -c ' echo "(require '\''color-theme)" >> ~/.emacs '
    su "$SUDO_USER" -c ' echo "(eval-after-load \"color-theme\" '\''(progn (color-theme-initialize) (color-theme-dark-laptop)))" >> ~/.emacs '
    su "$SUDO_USER" -c ' echo "(show-paren-mode 1)" >> ~/.emacs '
}

function install_java {
    apt-get -y install openjdk-11-jre openjdk-11-jdk
    sudo sed -i "s/^assistive_technologies=/#&/" /etc/java-11-openjdk/accessibility.properties
}

function install_code {
    if dpkg -l code; then
        echo "Skipping, Visual Studio Code already installed"
    else
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
        mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
        sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
        apt-get -y install apt-transport-https
        apt-get -y update
        apt-get -y install code # or code-insiders
    fi
}

function install_python {
    apt-get -y install \
            python3 \
            python3-pip \
            python3-virtualenv \
            python3-numpy \
            python3-scipy \
            python3-matplotlib \
            python3-willow \
            python3-nltk \
            jupyter
}

function install_sql {
    sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password your_password'
    sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password your_password'
    sudo apt-get -y install mysql-server
    mysql -u root -e "DROP USER 'root'@'localhost';
                      CREATE USER 'root'@'localhost' IDENTIFIED BY '';
                      GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost';
                      FLUSH PRIVILEGES;"
    apt-get -y install sqlite libsqlite-dev mysql-client
}

function install_atom {
    wget -qO- https://packagecloud.io/AtomEditor/atom/gpgkey | gpg --dearmor > atom.gpg
    mv atom.gpg /etc/apt/trusted.gpg.d/atom.gpg
    sudo sh -c 'echo "deb [arch=amd64] https://packagecloud.io/AtomEditor/atom/any/ any main" > /etc/apt/sources.list.d/atom.list'
    apt-get -y update
    apt-get -y install atom
}

function install_r {
    apt-get -y install r-base
}

function install_flatpak {
    apt-get install -y flatpak gnome-software-plugin-flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

function install_zoom {
    flatpak install -y us.zoom.Zoom
}

function install_teams {
    flatpak install -y com.microsoft.Teams
}

function install_wfh {
    install_zoom
    install_teams
}

function install_protege {
    su "$SUDO_USER" -c "mkdir -p ~/programs;
                        cd ~/programs;
                        rm -rf ./Protege-5.2.0*;
                        wget http://sbt.science.uva.nl/boydki_software/Protege-5.2.0-linux.tar.gz;
                        tar -xf Protege-5.2.0-linux.tar.gz;
                        mkdir -p ~/bin
                        cd ~/bin;
                        echo \#\!/bin/bash > protege;
                        echo \"cd ~/programs/Protege-5.2.0\" >> protege;
                        echo \"./run.sh\" >> protege;
                        chmod +x protege;"
}

# function install_latex {
#     # A selection of TeX Live packages
#     # (texlive-fonts-recommended, texlive-latex-base, texlive-latex-recommended)
#     # Maybe also install the docs but we are somewhat time-constrained
#     #apt-get -y install texlive-latex-extra-doc
#     apt-get -y install texlive-latex-extra
# }

function install_sim_pl {
    # it's fine if this runs twice, add-apt-repository checks if already present in sources
    add-apt-repository -y ppa:uva-informatica/sim-pl
    apt-get -y install sim-pl
}

function install_vivado {
    add-apt-repository -y ppa:uva-informatica/meta-packages
    apt-get -y install 5062arco6y
}

function install_c_tools {
    apt-get -y install build-essential clang lldb expect clang-tools valgrind gcc
}

function install_git {
    apt-get -y install git
}

function install_chromium {
    sudo snap install chromium
}

function install_firefox_deb {
    # At least for now, the Firefox snap starts very slowly, even on powerful machines. On slower
    # laptops, with SSD, it can take nearly a minute. In addition, there are issues with browser
    # extensions that use native communication, like password managers.

    # Receiving timely security updates for a browser is extremely important, so we don't want to use
    # an unofficial distribution or manually download a package that won't be updated by students. This
    # PPA seems to be official and provides immediate updates for all supported Ubuntu releases.
    if snap info firefox | grep -q "installed"; then
        cat << EOF > /etc/apt/preferences.d/firefox-no-snap
Package: firefox*
Pin: release o=Ubuntu*
Pin-Priority: -1
EOF
        apt-get remove -y firefox
        snap remove firefox
        add-apt-repository -y ppa:mozillateam/ppa
        apt-get install -y firefox
        # Add back to GNOME panel favorites
        gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed s/.$//), 'firefox.desktop']"
    else
        echo "Skipping, firefox snap not installed"
    fi
}

function apt_upgrade {
    DEBIAN_FRONTEND=noninteractive apt-get -yq upgrade &>> ${LOGFILE}
}

function apt_autoremove {
    DEBIAN_FRONTEND=noninteractive apt-get -yq autoremove &>> ${LOGFILE}
}

echo "1) Informatica
2) Artificial Intelligence"
while true; do
    read -p "Which of the above listed items fits you the best? " answer
    case $answer in
        [1] ) # Set Informatica year 1&2 variables
            mandatory=(
                "Add Universe repository;add_universe_repository"
                "Install Git;install_git"
                "Install C build tools;install_c_tools"
                "Set up UvA-VPN;install_uvavpn"
                "Install Python and extensions;install_python"
                "Visual Studio Code;install_code"
                "Install Flatpak;install_flatpak"
                "Install SIM-PL;install_sim_pl"
                "Install Vivado;install_vivado"
                "Upgrade packages;apt_upgrade"
                "Remove unneeded packages;apt_autoremove"
                "replace Firefox snap with deb from Mozilla;install_firefox_deb"
            )
            optional=(
                "install Chromium browser (open source base for Google Chrome);install_chromium"
                "install Zoom and Microsoft Teams (flatpak);install_wfh"
            ); break;;
        [2] ) # Set Artificial Intelligence year 1 variables
            mandatory=(
                "Add Universe repository;add_universe_repository"
                "Install Git;install_git"
                "Install C build tools;install_c_tools"
                "Set up UvA-VPN;install_uvavpn"
                "Install Python and extensions;install_python"
                "Install curl;apt-get -y install curl"
                "Add .bashrc configuration;install_ai_bashrc"
                "Install Prolog;install_prolog"
                "Install SQL tools;install_sql"
                "Install Protege;install_protege"
                "Install R;install_r"
                "Install Weka;apt-get -y install weka"
                "Install Visual Studio Code;install_code"
                "Install Flatpak;install_flatpak"
                "Upgrade packages;apt_upgrade"
                "Remove unneeded packages;apt_autoremove"
                "replace Firefox snap with deb from Mozilla;install_firefox_deb"
            )
            optional=(
                "install Chromium browser (open source base for Google Chrome);install_chromium"
                "install Zoom and Microsoft Teams (flatpak);install_wfh"
            ); break;;
        * ) echo "Please answer with 1 or 2";;
    esac
done
tput reset
echo -e "${TITLE}"

echo -e "\rStarting installation..."
echo

# Total number of steps
mandatory_steps=${#mandatory[@]}
optional_steps=${#optional[@]}
total_steps=$(( mandatory_steps + optional_steps ))

# Run mandatory steps
for i in "${!mandatory[@]}"; do
    step=${mandatory[$i]}
    current_step_number=$(( 1 + i ))
    run_step "$step" $current_step_number $total_steps
done

# Run optional steps
for i in "${!optional[@]}"; do
    step=${optional[$i]}
    description=${step%;*} # extract part before semicolon
    current_step_number=$(( 1 + mandatory_steps + i ))
    if check_answer "${YELLOW}[$current_step_number/$total_steps]${RESET} Optional: Would you like to $description?"; then
        run_step "$step" $current_step_number $total_steps
    fi
done

echo
echo "${GREEN}${BOLD}Finished!${RESET} If nothing went wrong, you can shut down your computer or start using it."
