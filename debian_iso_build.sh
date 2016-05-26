#!/bin/bash
#
# Walker 2016 05
#
# Build a customized Debian Live ISO for Auto VM build
# OS: Debian 7 wheezy
#
source /etc/profile
source $(pwd)/config.ini

function echo_msg(){
    echo -e "\n$*\n"
}

function chk_status(){
    if [ $? -ne '0' ];then
        echo_msg something wrong !!
        exit
    fi
}

function add_script_to_iso(){
if [ -d /tmp/live_boot  ]; then
    cd /tmp/live_boot
    echo_msg "copy script and config"
    cp $SETUP_SH_PATH/$SETUP_SH_NAME chroot/root/.
    cp $SETUP_SH_PATH/$SETUP_SH_CONF chroot/root/.

    # remove
    rm -f image/live/filesystem.squashfs
else
    echo "workspace not exist"
    exit
fi


mount -o bind /dev chroot/dev

cp /etc/resolv.conf chroot/etc/resolv.conf

# create script for chroot
echo_msg create runin_chroot.sh
cat << EEE > /tmp/runin_chroot.sh
#!/bin/bash
function echo_msg(){
    echo -e "\n$*\n"
}

mount none -t proc /proc && \
mount none -t sysfs /sys && \
mount none -t devpts /dev/pts && \
export HOME=/root && \
export LC_ALL=C && \
apt-get update && \
apt-get install dialog dbus --yes --force-yes && \
dbus-uuidgen > /var/lib/dbus/machine-id


echo "debian-liveCD" > /etc/hostname

#apt-cache search linux-image

echo_msg install packages

apt-get install --no-install-recommends --yes \
linux-image-3.2.0-4-amd64 live-boot \
wget openssh-client vim \
rsync syslinux sshpass ssh


#passwd root

echo "root:123456" | chpasswd


rm -f /var/lib/dbus/machine-id && \
apt-get clean && \
rm -rf /tmp/* && \
rm -rf /var/lib/apt/lists/* && \
umount -lf /proc && \
umount -lf /sys && \
umount -lf /dev/pts


#==================================================
# do something before exit

chmod +x /root/*.sh

sed -i '/exit/ s/^/#/' /etc/rc.local

# run setup when os boot
echo "/root/$SETUP_SH_NAME"  >> /etc/rc.local
echo "exit 0"               >> /etc/rc.local
#==================================================

echo "exit from chroot"
EEE

chmod +x /tmp/runin_chroot.sh

cp /tmp/runin_chroot.sh chroot/.

echo_msg enter chroot area
chroot chroot /runin_chroot.sh

umount -lf chroot/dev && mkdir -p image/{live,isolinux}

echo_msg "do mksquashfs"

mksquashfs chroot image/live/filesystem.squashfs -e boot

cp chroot/boot/vmlinuz-3.2.0-4-amd64 image/live/vmlinuz1

cp chroot/boot/initrd.img-3.2.0-4-amd64 image/live/initrd1

# create boot menu
cat << EOF > image/isolinux/isolinux.cfg
UI menu.c32

prompt 0
menu title Debian Live

timeout 3

label Debian Live 3.2.0-4-amd64
menu label ^Debian Live 3.2.0-4-amd64
menu default
kernel /live/vmlinuz1
append initrd=/live/initrd1 boot=live

label hdt
menu label ^Hardware Detection Tool (HDT)
kernel hdt.c32
text help
HDT displays low-level information about the systems hardware.
endtext

label memtest86+
menu label ^Memory Failure Detection (memtest86+)
kernel /live/memtest

EOF


cp /usr/lib/syslinux/isolinux.bin image/isolinux/ && \
cp /usr/lib/syslinux/menu.c32 image/isolinux/ && \
cp /usr/lib/syslinux/hdt.c32 image/isolinux/ && \
cp /usr/share/misc/pci.ids image/isolinux/ && \
cp /boot/memtest86+.bin image/live/memtest


cd image

echo_msg 'do genisoimage'
genisoimage -rational-rock -volid "Debian Live" -cache-inodes -joliet -full-iso9660-filenames -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -output ../$ISO_NAME .
}



function upload_to_nas(){
cd /tmp/live_boot

# upload to NAS
echo_msg upload iso to NAS
sshpass -p "$NAS_PASSWD" scp -o StrictHostKeyChecking=no ./$ISO_NAME $NAS_USER@$NAS_IP:$NAS_PATH/.
chk_status

}



function gen_debian_iso(){

cd /tmp

if [ -d live_boot  ];then
    rm -r live_boot
    echo_msg "workspace found, remove it."
fi


mkdir live_boot && cd live_boot

echo_msg get base os

debootstrap --arch=amd64 wheezy chroot http://ftp.tw.debian.org/debian/

#Taiwan mirror
#http://ftp.tw.debian.org/debian/

add_script_to_iso

upload_to_nas

cd ..
echo "Done..."

}


