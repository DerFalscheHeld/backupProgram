# [backupProgram](https://github.com/DerFalscheHeld/backupProgram)

## Included Tools

- **backup**: Schedule different backups with features such as compression and archiving.
- **usbbackup**: Automatically start backup to external USB devices when they are connected. Devices are deteceted by partition UUID.
- **naslog**: Run a command and capture stdout and stderr. Both are logged to `journalctl` with correct priorities. When errors occur, an email is sent with both stdout and stderr.

There are also install scripts for each tool and an additional install script to set up email sending from Cron.

## Dependencies

- **jo**: Small utility to create JSON objects
- **jq**: Command-line JSON processor
- **rsync**: A program for synchronizing files over a network
- **pigz** (optional): Parallel implementation of gzip

### Debian install command
>Install all required dependencies with:
>
>`sudo apt install --yes jo jq rsync`
>
>When you use [program_backup_pigz.bash](https://github.com/DerFalscheHeld/backupProgram/blob/main/program_backup_pigz.bash), also run this command:
>
>`sudo apt install --yes pigz`

### Fedora install command 
>Install all required dependencies with:
>
>`sudo dnf install -y jo jq rsync`
>
>When you use [program_backup_pigz.bash](https://github.com/DerFalscheHeld/backupProgram/blob/main/program_backup_pigz.bash), also run this command: 
>
>`sudo dnf install -y pigz`

## How to install the programs

> ### [backup  > with gzip](https://github.com/DerFalscheHeld/backupProgram/blob/main/program_backup.bash)
>
> `sudo ./install_backup.bash`

> ### [backup  > with pigz](https://github.com/DerFalscheHeld/backupProgram/blob/main/program_backup_pigz.bash)
>
>`sudo ./install_backup_pigz.bash`

> ### [usbbackup](https://github.com/DerFalscheHeld/backupProgram/blob/main/program_usbbackup.bash)
>
>`sudo ./install_usbbackup.bash`

> ### [naslog](https://github.com/DerFalscheHeld/backupProgram/blob/main/program_naslog.bash)
>
>`sudo ./install_naslog.bash`

> ### [cronmail](https://github.com/DerFalscheHeld/backupProgram/blob/main/install_cronmail_service.bash)
>
>`./install_cronmail_service.bash`

