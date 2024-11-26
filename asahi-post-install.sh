
# Upgrade everything
sudo dnf update && sudo dnf upgrade
sudo dnf install dnf-plugins-core
sudo dnf install inxi gpg nano bpytop glances htop yt-dlp curl chromium neofetch python pip git

# Update and clean up
sudo dnf update && sudo dnf upgrade
sudo dnf clean all && sudo dnf autoremove

# Set swap file size
cat /proc/swaps #verify current swaps
sudo dnf update --refresh
sudo /usr/libexec/fedora-asahi-remix-scripts/setup-swap.sh --recreate 16G
cat /proc/swaps #verify change

# Adjust Swappiness 
cat /proc/sys/vm/swappiness # get and display current swappiness
sudo sysctl vm.swappiness=90 # Change current val (0-low swapping, 100-high swapping) resets after reboot
sudo nano /etc/sysctl.conf # edit/append line (90 works well with MacBook Air 8GB/16GB Swap): vm.swappiness=90

# Install widevine
sudo dnf install widevine-installer
sudo widevine-installer

# Multimedia codec installation
sudo dnf install   https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install   https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf group update core
sudo dnf config-manager --enable fedora-cisco-openh264
sudo dnf update && sudo dnf upgrade
sudo dnf clean all && sudo dnf autoremove
sudo dnf install vlc
sudo dnf install gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel
sudo dnf install lame\* --exclude=lame-devel
sudo dnf group upgrade --with-optional Multimedia
sudo dnf install libavcodec-freeworld
sudo dnf install dnf-plugins-core
sudo dnf update && sudo dnf upgrade

# Install VS Code repos and app
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
dnf check-update
sudo dnf install code # or code-insiders

# Install Brave Browser
sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
sudo dnf install brave-browser 

# Optional remove Brave repos
ls /etc/yum.repos.d/
sudo rm /etc/yum.repos.d/brave-browser-beta.repo
sudo rm /etc/yum.repos.d/brave-browser.repo

# konsave commands for saving or restoring Plasma desktop settings
python -m pip install konsave
konsave -h

# Misc Stuff
cat /proc/sys/kernel/core_pattern
sudo nano /etc/dnf/dnf.conf
sudo dnf update && sudo dnf upgrade

# USB mounts
cd /run/media/david/
lsblk
