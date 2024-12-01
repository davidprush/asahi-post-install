#!/usr/bin/sh
set -e

readonly SCRIPT_VERSION="version 0.0.1-12.1.2024
"
check_sudo() {
    if [[ $EUID -ne 0 ]]; then
        echo "!!!This script must be run as root or with sudo!!!"
        exit 1
    fi
}

install_apps() {
    if [ "$1" == "essential" ]; then
        dnf update && dnf upgrade
        dnf install dnf-plugins-core
        dnf install inxi gpg nano bpytop glances htop yt-dlp curl chromium neofetch python pip git
        exit 0
    fi
}

save_app_file() {
    echo $(sudo dnf repoquery --userinstalled) >$1
}

export_apps() {
    file="$1"
    if [ -n "$file" ]; then
        if [ -z $(echo "$file" | awk /.txt/) ]; then
            file+=".txt"
        fi
        echo "  Saving user-installed apps to $filename"
        save_app_file "$filename"
    else
        echo "Missing [ filename ], use command [ --help ] to see command format."
        exit 1
    fi
    exit 0
}

import_apps() {
    file="$1"
    if [ -n "$file" ]; then
        apps=$(cat $file)
        for app in apps; do
            sudo dnf install -y $app
        done
        exit 0
    else
        echo "Missing [ filename ], use command [ --help ] to see command format."
        exit 1
    fi
}

backup_user_home() {
    user=$(whoami)
    home="/home/$user"
    echo "  Saving backup path $(pwd) for user: $user..."
    tar -zcvpf "$user-home-backup-$(date +%d-%m-%Y).tar.gz" "$home"
    exit 0
}

restore_user_home() {

}

clean_dnf() {
    if [ "$1" == "clean" ]; then
        dnf update && dnf upgrade
        dnf clean all && dnf autoremove
        exit 0
    fi
}

change_swappiness() {
    if [ "$1" == "swappiness" ]; then
        echo "Current swappiness:"
        cat /proc/sys/vm/swappiness # get and display current swappiness
        sysctl vm.swappiness=90     # Change current val (0-low swapping, 100-high swapping) resets after reboot
        nano /etc/sysctl.conf       # edit/append line (90 works well with MacBook Air 8GB/16GB Swap): vm.swappiness=90
        echo "vm.swappiness=90" >>/etc/sysctl.conf
        exit 0
    fi
}

recreate_swap() {
    if [ "$1" == "swap" ]; then
        cat /proc/swaps #verify current swaps
        dnf update --refresh
        sudo /usr/libexec/fedora-asahi-remix-scripts/setup-swap.sh --recreate 16G
        cat /proc/swaps #verify change
        exit 0
    fi
}

install_widevine() {
    if [ "$1" == "widevine" ]; then
        dnf install widevine-installer
        sudo widevine-installer
        exit 0
    fi
}

install_codecs() {
    if [ "$1" == "codecs" ]; then
        # Multimedia codec installation
        dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
        dnf install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
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
}

install_vscode() {
    if [ "$1" == "vscode" ]; then
        # Install VS Code repos and app
        rpm --import https://packages.microsoft.com/keys/microsoft.asc
        echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo >/dev/null
        dnf check-update
        dnf install code # or code-insiders
        exit 0
    fi
}

install_brave() {
    if [ "$1" == "brave" ]; then
        # Install Brave Browser
        dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
        rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
        dnf install brave-browser
        exit 0
    fi
}

konsave() {
    if [ "$1" == "konsave" ]; then
        # konsave commands for saving or restoring Plasma desktop settings
        python -m pip install konsave
        konsave -h
    fi
}

mit_license() {
    echo "MIT License

    Copyright (c) 2024 David P. Rush

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE."

}

script_version() {
    echo "$SCRIPT_VERSION"
}

help() {
    # Display Help
    echo "This script helps users post Asahi Linux installation,"
    echo "  installing standard applications and repos, "
    echo "  importing and exporting user settings and data, "
    echo "  and backing up the user's home directory, etc."
    echo
    echo "Syntax: asahi-post-install [command]"
    echo "Commands:"
    echo "--export-apps [filename]           Export user-installed to text file [filename].txt"
    echo "--import-apps [filename]           Import apps and istall from text file [filename].txt"
    echo "--backup-user-home                 Backup user home directory as a compressed file"
    echo "--restore-user-home [filename]     Restore user home directory from a compressed file"
    echo "--save-kde-settings [filename]     Use konsave to backup KDE system settings"
    echo "--restore-kde-settings [filename]  Restore KDE system settings from a konsave file"
    echo "--set-swappiness                   Change system swappiness"
    echo "--install-codecs                   Install codecs for multimedia"
    echo "--version                          Display script version"
    echo "--help                             Display this Help"
    echo
}

main() {
    #check_sudo

    command="$1"
    filename="$2"

    case $command in

    --export-apps)
        export_apps "$filename"
        ;;

    --import-apps)
        import_apps "$filename"
        ;;

    --backup-user-home)
        backup_user_home
        ;;

    --restore-user-home)
        restore_user_home "$filename"
        ;;

    --save-kde-settings)
        save_kde_settins "$filename"
        ;;

    --restore-kde-settings)
        restore_kde_settings "$filename"
        ;;

    --set-swappiness)
        set_swappiness
        ;;

    --install-codecs)
        install_codecs
        ;;

    --version)
        echo -n "$0 Version: $SCRIPT_VERSION"
        exit 0
        ;;

    --help)
        help
        ;;

    *)
        echo -n "INVALID: command [ $command ] Type [ --help ] valid commands"
        ;;
    esac
}

main "$1" "$2"
