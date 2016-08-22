#!/bin/bash
# Walker 2016 05
#
# Run this script on vmware esxi 5.0.0

# read config

PWD=`pwd`
source $PWD/config.ini


function echo_msg(){
    echo -e "$*"
}


function chk_status(){
    if [ $? -ne '0' ];then
        echo_msg "[WARN] something wrong !!"
        exit
    fi
}


function gen_create_vm_shell(){

cat << EEE > $PWD/g_create_vm.sh
#!/bin/sh
# run on vSphere ESXi 5.0.0

# create vm folder
cd ${VMFS_PATH}
mkdir ${VM_NAME}

# create vm file
vmkfstools -c ${SIZE}G -d thin -a lsilogic $VM_NAME/$VM_NAME.vmdk

# creating the config file
touch $NAME/$VM_NAME.vmx

# writing information into the configuration file
cat << EOF > $VM_NAME/$VM_NAME.vmx

config.version = "8"
virtualHW.version = "8"
vmci0.present = "TRUE"
displayName = "${VM_NAME}"
floppy0.present = "FALSE"
numvcpus = "${CPU}"
scsi0.present = "TRUE"
scsi0.sharedBus = "none"
scsi0.virtualDev = "lsilogic"
memsize = "${RAM}"
scsi0:0.present = "TRUE"
scsi0:0.fileName = "${VM_NAME}.vmdk"
scsi0:0.deviceType = "scsi-hardDisk"
ide1:0.present = "TRUE"
ide1:0.fileName = "${ISO_PATH}/${ISO_NAME}"
ide1:0.deviceType = "cdrom-image"
ethernet0.present = "TRUE"
ethernet0.networkName = "${NETWORK_LABEL}"
pciBridge0.present = "TRUE"
pciBridge4.present = "TRUE"
pciBridge4.virtualDev = "pcieRootPort"
pciBridge4.functions = "8"
pciBridge5.present = "TRUE"
pciBridge5.virtualDev = "pcieRootPort"
pciBridge5.functions = "8"
pciBridge6.present = "TRUE"
pciBridge6.virtualDev = "pcieRootPort"
pciBridge6.functions = "8"
pciBridge7.present = "TRUE"
pciBridge7.virtualDev = "pcieRootPort"
pciBridge7.functions = "8"
ethernet0.pciSlotNumber = "32"
ethernet0.virtualDev = "e1000"
ethernet0.generatedAddressOffset = "0"
guestOS = "${OS_TYPE}"
EOF

# adding VM register
NEW_VM=\`vim-cmd solo/registervm ${VMFS_PATH}/${VM_NAME}/${VM_NAME}.vmx\`

# power on vm:
vim-cmd vmsvc/power.on \${NEW_VM}

echo "finish"

EEE

}


function send_to_vsphere(){
    echo_msg "[INFO] send_to_vsphere: try to upload $PWD/g_create_vm.sh to $VSPHERE_IP path: /tmp"
    sshpass -p "$VSPHERE_PSW" scp -o StrictHostKeyChecking=no $PWD/g_create_vm.sh $VSPHERE_USER@$VSPHERE_IP:/tmp/.
    chk_status 

    echo_msg "[INFO] send_to_vsphere: add execute permission"
    sshpass -p "$VSPHERE_PSW" ssh -o StrictHostKeyChecking=no $VSPHERE_USER@$VSPHERE_IP chmod +x /tmp/g_create_vm.sh    
    chk_status

}


function run_on_vsphere(){
    sshpass -p "$VSPHERE_PSW" ssh -o StrictHostKeyChecking=no $VSPHERE_USER@$VSPHERE_IP /tmp/g_create_vm.sh
    chk_status
    echo_msg "[INFO] run_on_vsphere"
}


function power_on_vm(){
    vmid=`sshpass -p "$VSPHERE_PSW" ssh -o StrictHostKeyChecking=no $VSPHERE_USER@$VSPHERE_IP vim-cmd vmsvc/getallvms |grep $VM_NAME| awk '{print $1}'`
    chk_status

    # power on
    sshpass -p "$VSPHERE_PSW" ssh -o StrictHostKeyChecking=no $VSPHERE_USER@$VSPHERE_IP vim-cmd vmsvc/power.on $vmid
    
    echo_msg "[INFO] power_on_vm"
}

#power_on_vm

# modify vmx file to remove cd rom, need poweroff first
function remove_vcdrom(){
    sshpass -p "$VSPHERE_PSW" ssh -o StrictHostKeyChecking=no $VSPHERE_USER@$VSPHERE_IP "sed -i '/ide1/s/^/#/' ${VMFS_PATH}/${VM_NAME}/${VM_NAME}.vmx"
    chk_status

    echo_msg "[INFO] remove_vcdrom"
}

#remove_vcdrom

