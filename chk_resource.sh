#!/bin/bash
# Walker 2016 05

source $(pwd)/config.ini


function chk_tarball(){
    rec=`sshpass -p "$REMOTE_PASSWD" ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_TARBALL_IP "ls $REMOTE_TARBALL_PATH/$REMOTE_TARBALL_NAME &> /dev/null  || echo notar"`

    #echo $rec

    if [ "$rec" == "notar" ]; then
        echo "Can not find image tarball $REMOTE_TARBALL_NAME on $REMOTE_TARBALL_IP"
        exit
    else
        echo "Find $REMOTE_TARBALL_NAME on $REMOTE_TARBALL_IP"
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


function chk_vsphere(){
    :
}

# check iso on vSphere
function chk_iso(){
    re=`sshpass -p "$VSPHERE_PSW" ssh -o StrictHostKeyChecking=no $VSPHERE_USER@$VSPHERE_IP "ls $ISO_PATH/$ISO_NAME &> /dev/null || echo noiso"`            
    
    #echo $re

    if [ "$re" == "noiso" ]; then
        echo "Can not find upload iso $ISO_NAME on vSphere"
        exit
    else
        echo "Find $ISO_PATH/$ISO_NAME on $VSPHERE_IP"
    fi
}


#return_val=$(chk_ip_used)
#echo $return_val

#chk_iso
#chk_tarball
