# asahi-post-install.sh

`asahi-post-install.sh` is a script with many options to configure post installation of Asahi Linux on Apple Silicon.

## Script functions:

``` bash
This script helps users post Asahi Linux installation, installing standard applications and repos,
  importing and exporting user settings and data, and backing up the user's home directory, etc.
Syntax: asahi-post-install [command]
Commands:
--add-repos                        Add repos: rpmfusion, vscode, brave-browser
--export-apps [filename]           Export user-installed to text file [filename].txt
--import-apps [filename]           Import apps and istall from text file [filename].txt
--install-warp                     Install the warp terminal
--backup-user-home                 Backup user home directory as a compressed file
--restore-user-home [filename]     Restore user home directory from a compressed file
--save-kde-settings [filename]     Use konsave to backup KDE system settings
--restore-kde-settings [filename]  Restore KDE system settings from a konsave file
--set-swappiness                   Change system swappiness
--install-codecs                   Install codecs for multimedia
--license                          Display script license
--version                          Display script version
--help                             Display this Help
```
