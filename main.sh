#!/bin/bash
# Walker 2016 05
#

PWD=`pwd`


# change value of key
function change_cfg_var(){
    # change config.ini
    # change_cfg_var KEY VALUE
    sed -i "/$1=/ s#[\x22|\x27].*[\x22|\x27]#\"$2\"#" $PWD/config.ini
    echo "[INFO] Change config: $1=\"$2\""
}

function chk_ip_format(){
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    #echo $stat
    #return $stat

    if [ "$stat" -ne "0" ]; then
        echo "[WARN] Check ip format fail, the input is $1"
        exit
    else
        echo "[INFO] Chcek ip format ok, the input is $1"
    fi
}


# read opts from command and set parameter
while getopts ":s:v:n:h" opt; do
    case $opt in
        s)
            # VSPHERE_IP
            chk_ip_format $OPTARG
            change_cfg_var VSPHERE_IP $OPTARG
            echo "Get vSphere ip: $OPTARG" >&2
            #exit
            ;;

        v)
            # IP_ADDR
            chk_ip_format $OPTARG
            change_cfg_var IP_ADDR $OPTARG
            echo "Get virtual machine ip: $OPTARG" >&2
            #exit
            ;;

        n)
            # PRE_HOST
            change_cfg_var PRE_HOST $OPTARG
            echo "Set vm name: $HOST_NAME" >&2
            ;;
        h)
            echo "Use $0" >&2
            echo "-s: vSphere ip" >&2
            echo "-v: virtual machine ip" >&2
            echo "-n: vm name" >&2
            exit
            ;;

        \?)
            echo "Invalid option: -$OPTARG" >&2
            $0 -h
            exit
            ;;
    esac
done

# load confing and functions
source $PWD/config.ini
source $PWD/create_vm.sh
source $PWD/debian_iso_build.sh
source $PWD/sock_svr.sh
source $PWD/chk_resource.sh

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
