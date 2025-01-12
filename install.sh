#!/bin/bash

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_FILE="$(basename "${BASH_SOURCE[0]}")"

user_name="cubeman"
# $ openssl passwd -6
encrypted_user_passwd='$6$NYdoX5w2VEXwm513$es..D5KH3KxRuLOPNBYKZ4h134gh6PWUydTQb8vNMQbX1lXzZjYyfrqbO5DVtQ0dCaCdS9I4jMjI66hIcqEwQ.'
encrypted_root_passwd='$6$g8H6iVT5hfkgJsYs$ScbjzJQkcHXcmDMerQzq5lO2/jPu.C1VLVewY/FnjmQ92Ul4LFYCxXW8YtGhQQ946MbgdJS8zaCU.8IN3MAGT/'

host_name="CubicSilicon"

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
	# enable ParallelDownloads
	sed -e 's/^#ParallelDownloads.*/ParallelDownloads = 5/' < /etc/pacman.conf > /tmp/pacman.conf
	cat /tmp/pacman.conf > /etc/pacman.conf
	# enable multilib
	sed -i '/^#\[multilib\]/ s/^#//' /etc/pacman.conf
	sed -i '/^\[multilib\]/,/^$/ {/^#Include.*/ s/^#//}' /etc/pacman.conf
	pacman -Sy
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
	echo "$host_name" > /etc/hostname
	# sudo	
	echo "%wheel ALL=(ALL:ALL)  ALL" > /etc/sudoers.d/settings
	# enable NetworkManager
	systemctl enable NetworkManager.service
	# root passwd
	echo "root:$encrypted_root_passwd" | chpasswd -e
	# add user
	useradd -mG wheel "$user_name"
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
nvidia_driver(){
	if [ -z "$(lspci | grep 'VGA' | grep 'NVIDIA')" ]; then
		echo "no NVIDIA GPU detected"
	else
		yes | pacman -S nvidia nvidia-utils nvidia-settings opencl-nvidia
		echo "options nouveau modeset=0" > /etc/modprobe.d/nvidia.conf
		echo "options nvidia_drm modeset=1 fbdev=1" >> /etc/modprobe.d/nvidia.conf
	fi
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
	yes | pacman -S jdk-openjdk bluez
	systemctl enable bluetooth.service
	yes | pacman -S sl cmatrix cowsay figlet neofetch
	printf "2\n\n" | pacman -S virtualbox
	yes | pacman -S shellcheck
}
hotspot(){
	yes | pacman -S iw hostapd dnsmasq
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

		cp -p "$SCRIPT_PATH/$SCRIPT_FILE" "/mnt/root"
		arch-chroot /mnt "/root/$SCRIPT_FILE" "chroot"
		
		rm "/mnt/root/$SCRIPT_FILE"
		exit 0
		;;
	chroot)
		next_line
		basic_config
		grub
		ssh_config
		nvidia_driver
		Desktop_env
		vscode
		hotspot
		others
		rm /root/next_line.sh
		exit 0
		;;
esac
