#!/bin/bash

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_FILE="$(basename "${BASH_SOURCE[0]}")"

next_line(){
	echo "while [ true ]; do" > /root/next_line.sh
	echo 'printf "\\n"' >> /root/next_line.sh
	echo "done" >> /root/next_line.sh
	chmod +x /root/next_line.sh
}
basic_config(){
	# setting mirror
	sed -e 10a\ 'Server = https://archlinux.cs.nycu.edu.tw/$repo/os/$arch' /etc/pacman.d/mirrorlist > /tmp/mirrorlist
	cat /tmp/mirrorlist > /etc/pacman.d/mirrorlist
	rm /tmp/mirrorlist
	# other enssential packages
	yes | pacman -S  vim man-db net-tools git wget tmux ntfs-3g iperf3 intel-ucode p7zip
	# timeZone
	ln -sf /usr/share/zoneinfo/Asia/Taipei /etc/localtime
	hwclock --systohc
	systemctl enable systemd-timesyncd.service
	# locale
	sed -e 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' < /etc/locale.gen > /tmp/locale.gen
	cat /tmp/locale.gen > /etc/locale.gen
	rm /tmp/locale.gen

	sed -e 's/^#zh_TW.UTF-8 UTF-8/zh_TW.UTF-8 UTF-8/' < /etc/locale.gen > /tmp/locale.gen
	cat /tmp/locale.gen > /etc/locale.gen
	rm /tmp/locale.gen
	locale-gen
	echo "LANG=en_US.UTF-8" > /etc/locale.conf
	# hostname
	echo "sa2024-$id" > /etc/hostname
	# sudo	
	echo "%wheel ALL=(ALL:ALL)  ALL" > /etc/sudoers.d/settings
	# enable NetworkManager
	systemctl enable NetworkManager.service
	# root passwd
	echo "root:$encrypted_root_passwd" | chpasswd -e
	# add user
	useradd -mNG wheel "$user_name"
	echo "$user_name:$encrypted_user_passwd" | chpasswd -e
}
grub(){
	yes | pacman -S grub os-prober efibootmgr
	grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub --removable
	mkdir /etc/default/grub.d
	echo "GRUB_DISABLE_OS_PROBER=false" > /etc/default/grub.d/os-prob.cfg
	grub-mkconfig -o /boot/grub/grub.cfg
}
ssh_config(){
	yes | pacman -S openssh
	echo "HostKey /etc/ssh/ssh_host_rsa_key" > /etc/ssh/sshd_config.d/settings.conf
	echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config.d/settings.conf
		
	yes | pacman -S fail2ban
	echo "[sshd]" >> /etc/fail2ban/jail.d/sshd.local
	echo "enabled = true" >> /etc/fail2ban/jail.d/sshd.local
	echo "filter = sshd" >> /etc/fail2ban/jail.d/sshd.local
	echo "banaction = iptables" >> /etc/fail2ban/jail.d/sshd.local
	echo "backend = systemd" >> /etc/fail2ban/jail.d/sshd.local
	echo "maxretry = 5" >> /etc/fail2ban/jail.d/sshd.local
	echo "findtime = 1d" >> /etc/fail2ban/jail.d/sshd.local
	echo "bantime = 30" >> /etc/fail2ban/jail.d/sshd.local

	systemctl enable sshd.service
	systemctl enable fail2ban.service
}
Desktop_env(){
	/root/next_line.sh | pacman -S plasma sddm noto-fonts-cjk
	yes | pacman -S konsole dolphin firefox gwenview vlc gedit yakuake speech-dispatcher
	mkdir /etc/sddm.conf.d/
	echo "[Theme]" > /etc/sddm.conf.d/theme.conf
	echo "DisplayServer=wayland" >> /etc/sddm.conf.d/theme.conf
	echo "Current=breeze" >> /etc/sddm.conf.d/theme.conf
	/root/next_line.sh | pacman -S fcitx5 fcitx5-chewing fcitx5-breeze fcitx5-configtool
 	
 	systemctl enable sddm
}
vscode(){
	wget -P /tmp/ "$(curl 'https://code.visualstudio.com/sha/download?build=stable&os=linux-x64' | sed 's/http/\nhttp/g' | grep http)"
	tar -zxf /tmp/code-stable*.tar.gz -C /usr/lib
	ln -s /usr/lib/VSCode-linux-x64/code /usr/bin/code
}
others(){
	yes | pacman -S sl cmatrix cowsay figlet neofetch
	yes | pacman -S shellcheck
}
sa_setup(){
	# add judge user
	useradd -mNG wheel -s /bin/sh judge
	groupadd nycusa -U judge
	echo "%nycusa ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers.d/settings
	# motd
	echo "NYCU-SA-2024-$id" >> /etc/motd
	# WireGuard
	yes | pacman -S wireguard-tools
	if [ -e "/root/wg0.conf" ];then
		mv /root/wg0.conf /etc/wireguard/
	fi
	# ssh
	mkdir /home/judge/.ssh
	curl 'https://nasa.cs.nycu.edu.tw/sa/2024/nasakey.pub' >> /home/judge/.ssh/authorized_keys
}
STATE="$1"

if [ -z "$STATE" ]; then
	STATE="base"
fi

case "$STATE" in
	base)
 		timedatectl
		pacstrap -K /mnt base linux linux-firmware base-devel networkmanager
		genfstab -U /mnt >> /mnt/etc/fstab

		cp -p "$SCRIPT_PATH/$SCRIPT_FILE" /mnt/root
		cp "$SCRIPT_PATH/setup.conf" /mnt/root
		if [ -e "$SCRIPT_PATH/wg0.conf" ];then
			cp "$SCRIPT_PATH/wg0.conf" /mnt/root
		fi
		
		arch-chroot /mnt "/root/$SCRIPT_FILE" "chroot"
		
		rm "/mnt/root/$SCRIPT_FILE"
		rm "/mnt/root/setup.conf"
		exit 0
		;;
	chroot)
		next_line
		source /root/setup.conf
		basic_config
		grub
		ssh_config
		Desktop_env
		vscode
		others
		sa_setup
		rm /root/next_line.sh
		exit 0
		;;
esac
