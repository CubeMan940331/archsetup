#!/bin/bash

user_name="cubeman"
# $ openssl passwd -6
user_passwd='passwd'
root_passwd='root'

host_name="CubicSilicon"

mirror_list='
	https://archlinux.cs.nycu.edu.tw/$repo/os/$arch
'

mirror_locations="TW,"

# non-gui packages to install without configuring
simple_package_list='
	htop
	bash-completion
	amd-ucode
	cmatrix
	cowsay
	fastfetch
	figlet
	git
	iperf3
	intel-ucode
	man-db
	net-tools
	ntfs-3g
	sl
	sysbench
	tmux
	vim
	wget
	zip
'

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_FILE="$(basename "${BASH_SOURCE[0]}")"

setting_mirror(){
	# setting mirror
	if [ ! -e reflector-result.txt ]; then
		reflector --country $mirror_locations --latest 8 --sort rate -p https --save reflector-result.txt
	fi
	echo "# manual mirrorlist" > mirrorlist_new.txt
	for item in $mirror_list; do
		echo "Server =  $item" >> mirrorlist_new.txt
	done
	echo "" >> mirrorlist_new.txt

	cat reflector-result.txt >> mirrorlist_new.txt
	
	if [ ! -e mirrorlist_bak.txt ]; then
		cp /etc/pacman.d/mirrorlist mirrorlist_bak.txt
	fi
	cp mirrorlist_new.txt /etc/pacman.d/mirrorlist
}
basic_config(){
	# TimeZone
	ln -sf /usr/share/zoneinfo/Asia/Taipei /etc/localtime
	hwclock --systohc

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
	
	# root passwd
	echo $root_passwd | passwd -s root
	
	# add user
	useradd -mG wheel "$user_name"
	echo $user_passwd | passwd -s $user_name

	# sudo
	echo "%wheel ALL=(ALL:ALL)  ALL" > /etc/sudoers.d/settings
}
system_tweaks(){
	# enable multilib
	sed -i '/^#\[multilib\]/ s/^#//' /etc/pacman.conf
	sed -i '/^\[multilib\]/,/^$/ {/^#Include.*/ s/^#//}' /etc/pacman.conf
	pacman -Sy

	# enable services
	pacman -S --noconfirm pacman-contrib
	systemctl enable NetworkManager
	systemctl enable paccache.timer # https://wiki.archlinux.org/title/Pacman#Cleaning_the_package_cache
	systemctl enable systemd-timesyncd # https://wiki.archlinux.org/title/Systemd-timesyncd#Usage
	systemctl enable fstrim.timer # https://wiki.archlinux.org/title/Solid_state_drive#TRIM

	# limit journal size
	mkdir /etc/systemd/journald.conf.d
	echo "[Journal]" > /etc/systemd/journald.conf.d/settings.conf
	echo "SystemMaxUse=500M" >> /etc/systemd/journald.conf.d/settings.conf
}
grub(){
	pacman -S --noconfirm grub os-prober efibootmgr
	grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub
	grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub --removable
	mkdir /etc/default/grub.d
	echo "GRUB_DISABLE_OS_PROBER=false" > /etc/default/grub.d/os-prob.cfg
	grub-mkconfig -o /boot/grub/grub.cfg
}
ssh_config(){
	pacman -S --noconfirm openssh
		
	pacman -S --noconfirm fail2ban
	echo "[sshd]" >> /etc/fail2ban/jail.d/sshd.local
	echo "enabled = true" >> /etc/fail2ban/jail.d/sshd.local
	echo "filter = sshd" >> /etc/fail2ban/jail.d/sshd.local
	echo "banaction = iptables" >> /etc/fail2ban/jail.d/sshd.local
	echo "backend = systemd" >> /etc/fail2ban/jail.d/sshd.local
	echo "maxretry = 5" >> /etc/fail2ban/jail.d/sshd.local
	echo "findtime = 1h" >> /etc/fail2ban/jail.d/sshd.local
	echo "bantime = 5h" >> /etc/fail2ban/jail.d/sshd.local

	systemctl enable sshd
	systemctl enable fail2ban
}
nvidia_driver(){
	# TODO
	# detecting which GPU is in the computer
	if [ -z "$(lspci | grep 'VGA' | grep 'NVIDIA')" ]; then
		echo "no NVIDIA GPU detected"
	else
		pacman -S --noconfirm nvidia nvidia-utils nvidia-settings opencl-nvidia
		# echo "options nouveau modeset=0" > /etc/modprobe.d/nvidia.conf
		# echo "options nvidia_drm modeset=1 fbdev=1" >> /etc/modprobe.d/nvidia.conf
	fi
}
Desktop_env(){
	pacman -S --noconfirm pipewire-jack qt6-multimedia-ffmpeg noto-fonts noto-fonts-cjk
	pacman -S --noconfirm plasma sddm
	pacman -S --noconfirm konsole dolphin firefox gwenview vlc gedit speech-dispatcher
	mkdir /etc/sddm.conf.d/
	echo "[Theme]" > /etc/sddm.conf.d/theme.conf
	echo "DisplayServer=wayland" >> /etc/sddm.conf.d/theme.conf
	echo "Current=breeze" >> /etc/sddm.conf.d/theme.conf
 	systemctl enable sddm
	
	pacman -S --noconfirm fcitx5 fcitx5-chewing fcitx5-breeze fcitx5-configtool
	# TODO
	# config input method for chewing
}
vscode(){
	pacman -S --noconfirm wget
	url='https://code.visualstudio.com/sha/download?build=stable&os=linux-x64'

	echo '#!/bin/bash' > /usr/bin/update-vscode
	echo "wget -P /tmp/ \$(curl '$url' | sed 's/http/\nhttp/g' | grep http)" >> /usr/bin/update-vscode
	echo 'tar -zxf /tmp/code-stable*.tar.gz -C /usr/share' >> /usr/bin/update-vscode
	chmod 755 /usr/bin/update-vscode
	
	/usr/bin/update-vscode
	ln -s /usr/share/VSCode-linux-x64/code /usr/bin/code
}
others(){
	pacman -S --noconfirm $simple_package_list
}
STATE="$1"

if [ -z "$STATE" ]; then
	STATE="base"
fi

case "$STATE" in
	base)
 		timedatectl
		setting_mirror
		pacstrap -K /mnt base linux linux-firmware base-devel networkmanager
		genfstab -U /mnt >> /mnt/etc/fstab

		cp -p "$SCRIPT_PATH/$SCRIPT_FILE" "/mnt/root"
		arch-chroot /mnt "/root/$SCRIPT_FILE" chroot
		
		rm "/mnt/root/$SCRIPT_FILE"
		exit 0
		;;
	chroot)
		basic_config
		system_tweaks
		grub
		ssh_config
		Desktop_env
		vscode
		others
		exit 0
		;;
esac
