#!/usr/bin/sh
set -e

readonly SCRIPT_VERSION="version 0.0.1-12.1.2024
"
check_sudo() {
    if [[ $EUID -ne 0 ]]; then
        echo "Verified not root or sudo..."
    else
        echo "WARNING: Do not run this script as root or with sudo."
        exit 1
    fi
}

add_repos() {
    sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf group update core
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo >/dev/null
    sudo dnf check-update
    sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
    sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
    sudo dnf update -y
    sudo dnf install -y code brave-browser vlc
}

install_apps() {
    if [ "$1" == "essential" ]; then
        sudo dnf update && dnf upgrade
        sudo dnf install dnf-plugins-core
        sudo dnf install inxi gpg nano bpytop glances htop yt-dlp curl chromium neofetch python pip git
        exit 0
    fi
}

save_app_file() {
    sudo dnf update -y && sudo dnf upgrade -y
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
        sudo dnf update -y && sudo dnf upgrade -y
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
    # Assign the filename to a variable
    backup_file="$1"

    # Check if the backup file exists
    if [ ! -f "$backup_file" ]; then
        echo "Error: Backup file $backup_file does not exist."
        return 1
    fi

    # Determine the file extension to handle different compression formats
    case "$backup_file" in
        *.tar.gz|*.tgz)
            decompress_cmd="tar xzf"
            ;;
        *.tar.bz2)
            decompress_cmd="tar xjf"
            ;;
        *.tar.xz)
            decompress_cmd="tar xJf"
            ;;
        *)
            echo "Unsupported file format. This function only supports .tar.gz, .tgz, .tar.bz2, and .tar.xz."
            return 1
            ;;
    esac

    # Prompt for confirmation to prevent accidental data loss
    read -p "This will restore your home directory. Are you sure? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        # Move current home directory contents to a temporary location
        mv ~ ~/backup_temp_$RANDOM

        # Extract the backup
        $decompress_cmd "$backup_file" -C ~

        # Check if extraction was successful
        if [ $? -eq 0 ]; then
            echo "Restore completed. Your old home directory is temporarily at ~/backup_temp_$RANDOM"
        else
            echo "Restore failed."
            # Attempt to move the backup back if restore failed
            mv ~/backup_temp_$RANDOM ~ || echo "Failed to restore the original home directory."
        fi
    else
        echo "Restore operation cancelled."
    fi
}

set_swappiness() {
    if [ "$1" == "swappiness" ]; then
        echo "Current swappiness:"
        cat /proc/sys/vm/swappiness # get and display current swappiness
        echo -n "Enter new swappiness (0-100; 0-none, 100-high):"
        read swappiness 
        ssudo ysctl vm.swappiness="$swappiness"     # Change current val (0-low swapping, 100-high swapping) resets after reboot
        nano /etc/sysctl.conf       # edit/append line (90 works well with MacBook Air 8GB/16GB Swap): vm.swappiness=90
        sudo echo "vm.swappiness=$swappiness" >>/etc/sysctl.conf
        exit 0
    fi
}

recreate_swap() {
    if [ -n "$1" ]; then
        echo -n "Enter new swap size (8-32):"
        read swap 
        cat /proc/swaps #verify current swaps
        sudo dnf update --refresh
        sudo /usr/libexec/fedora-asahi-remix-scripts/setup-swap.sh --recreate 16G
        sudo cat /proc/swaps #verify change
        exit 0
    fi
}

install_codecs() {
    if [ "$1" == "codecs" ]; then
        # Multimedia codec installation
        add_repos
        sudo dnf install widevine-installer
        sudo widevine-installer
        sudo dnf config-manager --enable fedora-cisco-openh264
        sudo dnf install gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel
        sudo dnf install lame\* --exclude=lame-devel
        sudo dnf group upgrade --with-optional Multimedia
        sudo dnf install libavcodec-freeworld
        sudo dnf install dnf-plugins-core
        sudo dnf update -y && dnf upgrade -y
        sudo dnf clean all && dnf autoremove
        exit 0
    fi
}

install_konsave() {
    if [ "$1" == "konsave" ]; then
        # konsave commands for saving or restoring Plasma desktop settings
        python -m pip install konsave
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
    echo "This script helps users post Asahi Linux installation, installing standard applications and repos,"
    echo "  importing and exporting user settings and data, and backing up the user's home directory, etc."
    echo "Syntax: asahi-post-install [command]"
    echo "Commands:"
    echo "--add-repos                        Add repos: rpmfusion, vscod, brave-browser"
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
    check_sudo

    command="$1"
    filename="$2"

    case $command in


    --add-repos)
        add_repos
        ;;

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
