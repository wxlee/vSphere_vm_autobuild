#!/bin/bash
# Walker 2016 05
#

PWD=`pwd`

source $PWD/config.ini
source $PWD/create_vm.sh
source $PWD/debian_iso_build.sh
source $PWD/chk_resource.sh
source $PWD/sock_svr.sh

# resource check
chk_tarball
chk_iso
chk_vsphere_datastore

ch_ip=$(chk_ip_ssh)

if [ "$ch_ip" == "ok" ]; then
    echo "[WARN] New vm $IP_ADDR is already used, abort!!"
    exit
elif [ "$ch_ip" == "fail" ]; then
    echo "[INFO] New vm $IP_ADDR can be assigned, go on."
fi


# build debian iso
if [ "$REBUILD_ISO" == "no" ]; then
    echo "[INFO] Rebuild (no), pack iso"
    
    # just repack
    add_script_to_iso
    upload_to_nas

elif [ "$REBUILD_ISO" == "yes" ]; then
    echo "[INFO] Rebuild (yes), generate entire iso"

    # generate new debian iso
    gen_debian_iso

else
    echo "[WARN] REBUILD_ISO just allow yes or no"
    exit
fi

# generate vm shell according to config.ini
gen_create_vm_shell

# send to vphere
send_to_vsphere

# run generate vm shell on vsphere
run_on_vsphere

# check vm status: poweroff > umount cd rom > poweron

up_sock_svr

# use busy waiting for vm config and poweroff
read_sock_msg

sleep 10
echo "[INFO] Detect vm poweroff, remove cd rom"
remove_vcdrom

sleep 5
echo "[INFO] Power on the new vm $IP_ADDR"
power_on_vm
