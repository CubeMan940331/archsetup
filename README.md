# archsetup

## Procedure
**manual**
you need to do this part manually
- partition the disk
- format and mount the disk
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
- boot loader
    - grub
- system-tweaks
    - enable NetworkManager
    - enable paccache.timer
    - enable systemd-timesyncd
    - limit journal size
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
