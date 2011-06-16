#!/bin/bash

btisoname=bt4-pre-final.iso

clear
echo "##############################################################"
echo "[*] BackTrack 4 Final customisation script"
echo "[*] Setting up the build environment..."

services="inetutils-inetd tinyproxy iodined knockd openvpn atftpd ntop nstxd nstxcd apache2 sendmail atd dhcp3-server winbind miredo miredo-server pcscd wicd wacom cups bluetooth binfmt-support mysql"

mkdir -p mnt
mount -o loop $btisoname mnt/
mkdir -p extract-cd
rsync --exclude=/casper/filesystem.squashfs -a mnt/ extract-cd
mkdir -p squashfs
mount -t squashfs -o loop mnt/casper/filesystem.squashfs squashfs
mkdir -p edit
echo "[*] Copying over files, please wait ... "

cp -a squashfs/* edit/

cp /etc/resolv.conf edit/etc/
cp /etc/hosts edit/etc/
cp /etc/fstab edit/etc/
cp /etc/mtab edit/etc/

mount --bind /dev/ edit/dev
mount -t proc /proc edit/proc

echo "##############################################################"
echo "[*] Entering livecd. "
echo "##############################################################"
echo "[*] Now you can modify the LiveCD. At minimum, we recommend :"
echo "[*] apt-get update && apt-get upgrade & apt-get clean"
echo "##############################################################"
echo "[*] If you are running a large update, you might need to stop"
echo "[*] services like crond, udev, cups, etc in the chroot"
echo "[*] before exiting your chroot environment."
echo "##############################################################"
echo "[*] Once you have finished your modifications, type \"exit\""
echo "##############################################################"

chroot edit

echo "[*] Exited the build environemnt, unmounting images."

rm -rf edit/etc/mtab
rm -rf edit/etc/fstab

umount edit/dev
umount edit/proc
umount squashfs
umount mnt

chmod +w extract-cd/casper/filesystem.manifest

echo "[*] Building manifest"
chroot edit dpkg-query -W --showformat='${Package} ${Version}\n' > extract-cd/casper/filesystem.manifest

for service in $services;do
chroot edit update-rc.d -f $service remove
done

REMOVE='ubiquity casper live-initramfs user-setup discover xresprobe os-prober libdebian-installer4'
for i in $REMOVE
do
sed -i "/${i}/d" extract-cd/casper/filesystem.manifest-desktop
done

cp extract-cd/casper/filesystem.manifest extract-cd/casper/filesystem.manifest-desktop

sed -i '/ubiquity/d' extract-cd/casper/filesystem.manifest-desktop

rm -rf extract-cd/casper/filesystem.squashfs
echo "[*] Building squashfs image..."

mksquashfs edit extract-cd/casper/filesystem.squashfs

rm extract-cd/md5sum.txt

(cd extract-cd && find . -type f -print0 | xargs -0 md5sum > md5sum.txt)

cd extract-cd

echo "[*] Creating iso ..."

mkisofs -b boot/grub/stage2_eltorito -no-emul-boot -boot-load-size 4 -boot-info-table -V "BT4" -cache-inodes -r -J -l -o ../bt4-mod.iso .

cd ..

echo "[*] Your modified BT4 is in $(pwd)/bt4-mod.iso"
echo "##############################################################"


