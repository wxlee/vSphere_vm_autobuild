#!/bin/bash
# Walker 2016 05

source $(pwd)/config.ini

#function chk_ip_format(){
#    local  ip=$1
#    local  stat=1
#
#    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
#        OIFS=$IFS
#        IFS='.'
#        ip=($ip)
#        IFS=$OIFS
#        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
#            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
#        stat=$?
#    fi
#    #echo $stat
#    #return $stat
#
#    if [ "$stat" -ne "0" ]; then
#        echo "[WARN] Check ip format fail, the input is $1"
#        exit
#    else
#        echo "[INFO] Chcek ip format ok, the input is $1"
#    fi
#}

#chk_ip_format '127.0.0.2'
#echo $aa

function chk_tarball(){
    rec=`sshpass -p "$REMOTE_PASSWD" ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_TARBALL_IP "ls $REMOTE_TARBALL_PATH/$REMOTE_TARBALL_NAME &> /dev/null  || echo notar"`

    #echo $rec

    if [ "$rec" == "notar" ]; then
        echo "[WARN] Can not find image tarball $REMOTE_TARBALL_NAME on $REMOTE_TARBALL_IP"
        exit
    else
        echo "[INFO] Find $REMOTE_TARBALL_NAME on $REMOTE_TARBALL_IP"
    fi

}


# test port 22 with 3 sec timeout
function chk_ip_ssh(){
    rc=`nc -w 3 -z $IP_ADDR 22; echo $?`
    
    if [ $rc -eq '0' ]; then
        # test ok
        echo ok
    else
        # test fail
        echo fail
    fi
}


# convert disk space to GB
function convert_format(){
    num=`echo $1 | awk -F '[MGT]' '{print $1}'`
    
    case $1 in
    *G)
        echo $num
        ;;

    *T)
        # TB to GB
        echo `echo $num*1024 | bc`
        ;;

    *M)
        # MB 
        echo 0
        ;;

    *)
        # others
        echo 0
        ;;

    esac
}



function chk_vsphere_datastore(){
    free_disk=`sshpass -p "$VSPHERE_PSW" ssh -o StrictHostKeyChecking=no $VSPHERE_USER@$VSPHERE_IP df -h | grep $VMFS_PATH | awk '{print $4}'`
    #echo $free_disk
    
    c_free_disk=$(convert_format $free_disk)

    #echo $c_free_disk

    if (( $(echo "$SIZE > $c_free_disk" | bc -l ) )); then
        echo "[WARN] vSphere $VSPHERE_IP $VMFS_PATH free disk space ${c_free_disk}G less than you want ${SIZE}G"
        exit
    fi
}

#chk_vsphere_datastore


# check iso on vSphere
function chk_iso(){
    re=`sshpass -p "$VSPHERE_PSW" ssh -o StrictHostKeyChecking=no $VSPHERE_USER@$VSPHERE_IP "ls $ISO_PATH/$ISO_NAME &> /dev/null || echo noiso"`            
    
    #echo $re

    if [ "$re" == "noiso" ]; then
        echo "[WARN] Can not find upload iso $ISO_NAME on vSphere"
        exit
    else
        echo "[INFO] Find $ISO_PATH/$ISO_NAME on $VSPHERE_IP"
    fi
}


#return_val=$(chk_ip_used)
#echo $return_val

#chk_iso
#chk_tarball
