# archsetup

## Procedure
**manual**
- partition the disk
- format the disk
- mount the disk
- inspect or modify the script
- run it

**install media**
- sync time
- setting_mirror
- install package to new root
- genfstab
- copy script to new root

**after chroot**
- basic config
    - timezone
    - locale
    - hostname
    - root passwd
    - add user
    - sudo
- system-tweaks
    - enable multilib
    - enable NetworkManager
    - enable paccache.timer
    - enable systemd-timesyncd
    - limit journal size
- boot loader
    - grub
- ssh (with fail2ban)
- nvidia driver (TODO)
- Desktop env (with fcitx5-chewing)
    - install kdm-plasma and gui-apps
    - config and enable sddm
    - install fcitx5-chewing
    - config input method (TODO)
- vscode
    - gen update-vscode script
    - install vscode
- others
