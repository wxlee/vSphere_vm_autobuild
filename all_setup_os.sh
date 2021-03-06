#!/bin/bash
# Walker 2016 05
#
# Debian basic OS deploy script
#  This script will run on debian live system boot from ISO

source /etc/profile
source /root/config.ini


function echo_msg(){
    echo -e "\n$*\n"
}

function chk_status(){
    if [ $? -ne '0' ];then
        echo_msg "[WARN] Something wrong !!"
        exit
    fi
}

function start_sock_client(){
    echo_msg "[INFO] Start socket server at port $SOC_PORT to $SOC_SVR_IP"
    exec 3<>/dev/tcp/$SOC_SVR_IP/$SOC_PORT
}


function snd_sock_msg(){
    echo_msg "[INFO] Send msg to socket svr: $1"
    echo -e "$1" >&3
}


function close_sock_client(){
    echo_msg "[INFO] Now close socket client"
    exec 3<&-
    exec 3>&-
}


# create chroot_cmd.sh
cat << EEE > /tmp/chroot_cmd.sh
#!/bin/bash
# Walker 2016 05 03

function echo_msg(){
    echo -e "$*"
}

function snd_sock_msg(){
    echo_msg "[INFO] Send msg to socket svr: $1"
    echo -e "$1" >&3
}



function set_hostname(){
    snd_sock_msg "[INFO] Start set_hostname"
    echo "$HOST_NAME" > /etc/hostname
    echo "set hostname"
}


function set_grub(){
    snd_sock_msg "[INFO] Start set_grub"
    grub-install /dev/sda
    update-grub
    echo "set grub"
}

function network_post(){
    snd_sock_msg "[INFO] Start network_post"

    # backup
    mv /etc/network/interfaces /etc/network/interfaces.1

# set new network interface
cat << EOF > /etc/network/interfaces

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet static
    address $IP_ADDR
    netmask 255.255.255.0
    gateway $IP_GW
    dns-nameservers $IP_DNS

EOF
}

function set_root_pwd(){
    echo "root:$TEMP_PW" | chpasswd
    echo -e "\n\n==== Auto OS setup script (2016 05, Walker)  ====" >> /etc/motd
#    echo -e "====  Please change the default password: $TEMP_PW  ====\n\n\n" >> /etc/motd
    echo "[INFO] Set default passwd"
}


set_hostname
set_grub
network_post
set_root_pwd

rm /chroot_cmd.sh

EEE


# create partition table (200G)
cat << EOF > /tmp/partition_200G.txt
# partition table of /dev/sda
unit: sectors

/dev/sda1 : start=     2048, size=   409600, Id=83, bootable
/dev/sda2 : start=   411648, size=  8388608, Id=82
/dev/sda3 : start=  8800256, size=410630144, Id=83
/dev/sda4 : start=        0, size=        0, Id= 0

EOF


function pause(){
    read -p "$*"
}


# fdisk noninteractive
function do_partition(){
    partition1=$1
    partition2=$2

    echo "[INFO] Create partition 1 size: $1"
    echo "[INFO] Create swap size: $2"
    echo "[INFO] Create other size to partition 3"

(echo n; echo p; echo 1; echo ""; echo +$partition1; \
echo n; echo p; echo 2; echo ""; echo +$partition2; \
echo n; echo p; echo 3; echo ""; echo ""; \
echo a; echo 1; \
echo t; echo 2; echo 82; \
echo p; \
echo w; ) | fdisk /dev/sda 

}




function formate_d(){
    snd_sock_msg "[INFO] Start formate_d"

    # set partition
    #sfdisk /dev/sda < /tmp/partition_200G.txt

    # new partition
    do_partition $PARTITION_1 $PARTITION_SWAP

    # format
    mkfs.ext4 /dev/sda1
    mkfs.ext4 /dev/sda3
    mkswap /dev/sda2
    
    echo "[INFO] Finish format disk"
}


function mount_d(){
    snd_sock_msg "[INFO] Start mount_d"
    
    # create temp dir
    mkdir /mnt/debian

    mount /dev/sda3 /mnt/debian
    mkdir /mnt/debian/boot
    mount /dev/sda1 /mnt/debian/boot
    echo "[INFO] mount_d"
}


function network_pre(){
    # marked
    sed -i '/allow-hotplug/ s/^/#/' /etc/network/interfaces
    sed -i '/eth0/ s/^/#/'          /etc/network/interfaces
    sed -i '/address/ s/^/#/'       /etc/network/interfaces
    sed -i '/netmask/ s/^/#/'       /etc/network/interfaces
    sed -i '/gateway/ s/^/#/'       /etc/network/interfaces
    echo "marked default interface"

# add interface
cat << EOF >> /etc/network/interfaces

auto eth0
iface eth0 inet static
    address $IP_ADDR
    netmask 255.255.255.0
    gateway $IP_GW
    dns-nameservers $IP_DNS

EOF

echo "[INFO] Set interface"

/etc/init.d/networking restart
ping -c 3 $IP_GW 

/etc/init.d/ssh restart

echo "[INFO] Restart network"
}

function network_post(){
    # backup
    mv /etc/network/interfaces /etc/network/interface.1

# set new
cat << EOF > /etc/network/interfaces

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet static
    address $IP_ADDR
    netmask 255.255.255.0
    gateway $IP_GW
    dns-nameservers $IP_DNS

EOF
}


function set_root_pwd(){
    snd_sock_msg "[INFO] Start set_root_pwd"

    echo "root:$TEMP_PW" | chpasswd
    echo "[INFO] Set default passwd"
}


function get_tarball(){
    snd_sock_msg "[INFO] Start get_tarball"

    sshpass -p "$REMOTE_PASSWD" scp -o StrictHostKeyChecking=no root@$REMOTE_TARBALL_IP:$REMOTE_TARBALL_PATH/$REMOTE_TARBALL_NAME /mnt/debian/
    chk_status
    echo "[INFO] Get tarball"
}


function set_tarball(){
    snd_sock_msg "[INFO] Start set_tarball"

    cd /mnt/debian/
    tar zxf *.tgz
    rm *.tgz
    mount -o bind /dev/ /mnt/debian/dev/
    mount -o bind /proc/ /mnt/debian/proc/
    #chroot /mnt/debian/ /bin/bash
    chmod +x /tmp/chroot_cmd.sh
    cp /tmp/chroot_cmd.sh /mnt/debian/
    chroot /mnt/debian/ /chroot_cmd.sh
    echo "[INFO] Set tarball"
}


function finish_msg(){
    echo "[INFO] Please set /etc/hosts after reboot"
    sleep 5
}


function power_off(){
    snd_sock_msg "[INFO] Start power_off"    

    echo "[INFO] Now poweroff"
    rm -f /$REMOTE_TARBALL_NAME
    poweroff
}

function do_reboot(){
    echo "[INFO] Ready to reboot"
    rm -f /$REMOTE_TARBALL_NAME
    reboot
}


network_pre
start_sock_client
formate_d
mount_d
set_root_pwd
get_tarball
set_tarball
finish_msg
power_off
#do_reboot




