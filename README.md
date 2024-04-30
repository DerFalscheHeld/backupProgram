# [backupProgram](https://github.com/DerFalscheHeld/backupProgram)

## Included Tools

- **backup**: Schedule different backups with features such as compression and archiving.
- **usbbackup**: Automatically start backup to external USB devices when they are connected. Devices are deteceted by partition UUID.
- **scruber**: Schedule scrub for btrfs or zpool filesystems.
- **naslog**: Run a command and capture stdout and stderr. Both are logged to `journalctl` with correct priorities. When errors occur, an email is sent with both stdout and stderr.

There are also install scripts for each tool and an additional install script to set up email sending from Cron.

## Dependencies

- **jq**: Command-line JSON processor
- **rsync**: A program for synchronizing files over a network
- **the zip Program you choose in the [backup program](https://github.com/DerFalscheHeld/backupProgram/blob/main/program_backup.sh)**

### Debian install command
>Install all required dependencies with:
>
>`sudo apt install --yes jq rsync`

### Fedora install command 
>Install all required dependencies with:
>
>`sudo dnf install -y jq rsync`

### Arch Linux install command
>Install all required dependencies with:
>
>`sudo pacman -Sy jq rsync --needed`

## How to install the programs

> ### [backup](https://github.com/DerFalscheHeld/backupProgram/blob/main/program_backup.sh)
>
> `sudo ./install_backup.sh`

> ### [usbbackup](https://github.com/DerFalscheHeld/backupProgram/blob/main/program_usbbackup.sh)
>
>`sudo ./install_usbbackup.sh`

> ### [scruber](https://github.com/DerFalscheHeld/backupProgram/blob/main/program_scruber.sh)
>
>`sudo ./install_scruber.sh`

> ### [naslog](https://github.com/DerFalscheHeld/backupProgram/blob/main/program_naslog.sh)
>
>`sudo ./install_naslog.sh`

> ### [cronmail](https://github.com/DerFalscheHeld/backupProgram/blob/main/install_cronmail_service.sh)
>
>`./install_cronmail_service.sh`

