#!/usr/bin/sh
set -e

if [ "$(whoami)" != "root" ]; then
    echo "Script must be run as root" >&2
    exit 1
fi

if [ "$1" == "help" ]; then
    echo "essential         Update system and install essential CLI apps"
    echo "clean             Update and cleanup the system"
    echo "swappiness        Pass a number (0-100) to increase (hi=100) or decrease (lo=0) swappiness"
    echo "swap              Pass a number to change swap size"
    echo "widevine          Install widevine"
    echo "codecs            Install RPMFusion with standard plugins and codecs"
    echo "vscode            Install Microsoft's Visual Studio Code repo and vs code app"
    echo "brave             Install Brave Browser repo and Brave Browser app"
    echo "konsave           Install konsave and save current kde settings/configuration"
    exit 0
fi

if [ "$1" == "essential" ]; then
    dnf update && dnf upgrade
    dnf install dnf-plugins-core
    dnf install inxi gpg nano bpytop glances htop yt-dlp curl chromium neofetch python pip git
    exit 0
fi

if [ "$1" == "clean" ]; then
    dnf update && dnf upgrade
    dnf clean all && dnf autoremove
    exit 0
fi

if [ "$1" == "swappiness" ]; then
    echo "Current swappiness:"
    cat /proc/sys/vm/swappiness # get and display current swappiness
    sysctl vm.swappiness=90 # Change current val (0-low swapping, 100-high swapping) resets after reboot
    nano /etc/sysctl.conf # edit/append line (90 works well with MacBook Air 8GB/16GB Swap): vm.swappiness=90
    echo "vm.swappiness=90" >> /etc/sysctl.conf
    exit 0
fi

if [ "$1" == "swap" ]; then
    cat /proc/swaps #verify current swaps
    dnf update --refresh
    sudo /usr/libexec/fedora-asahi-remix-scripts/setup-swap.sh --recreate 16G
    cat /proc/swaps #verify change
    exit 0
fi

if [ "$1" == "widevine" ]; then
    dnf install widevine-installer
    sudo widevine-installer
    exit 0
fi

if [ "$1" == "codecs" ]; then
    # Multimedia codec installation
    dnf install   https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
    dnf install   https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    dnf group update core
    dnf config-manager --enable fedora-cisco-openh264
    dnf update && dnf upgrade
    dnf clean all && dnf autoremove
    dnf install vlc
    dnf install gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel
    dnf install lame\* --exclude=lame-devel
    dnf group upgrade --with-optional Multimedia
    dnf install libavcodec-freeworld
    dnf install dnf-plugins-core
    dnf update && dnf upgrade
    exit 0
fi

if [ "$1" == "vscode" ]; then
    # Install VS Code repos and app
    rpm --import https://packages.microsoft.com/keys/microsoft.asc
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
    dnf check-update
    dnf install code # or code-insiders
    exit 0
fi

if [ "$1" == "brave" ]; then
    # Install Brave Browser
    dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
    rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
    dnf install brave-browser
    exit 0
fi 

if [ "$1" == "konsave" ]; then
    # konsave commands for saving or restoring Plasma desktop settings
    python -m pip install konsave
    konsave -h
fi

if [ $# -eq 0 ]; then
    echo "No command supplied. Use help to see commands."
    exit 1
else
    echo "$1 is not a command. Use help to see commands."
    exit 1
fi

# Git and Github tips if user/author unknown
# git config --local -e
# git config --global --edit
# git config --global user.name "davidprush"
# git config --global user.email "davidprush@gmail.com"
# git init
# git config user.name "someone"
# git config user.email "someone@someplace.com"
# git add *
# git commit -m "some init msg"