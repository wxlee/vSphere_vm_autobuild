#!/bin/bash
# Walker 2016 05

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



function up_sock_svr(){
    # start socket server at port 5000
    #  get msg from remote
    #  note the pid to sock_svr.pid
    #  capture the client input command to sock_svr.log
    nohup nc -k -l -p $SOC_PORT &>$(pwd)/sock_svr.log & echo $! > $(pwd)/sock_svr.pid &
    chk_status
    echo_msg "Start socket server"
}

function stop_sock_svr(){
    kill `cat $(pwd)/sock_svr.pid`
    echo_msg "Stop socket server"
}

#up_sock_svr

function read_sock_msg(){
    while true
    do
        cat $(pwd)/sock_svr.log | grep 'power_off'

        if [ $? -eq "0" ]; then
            # got power off msg from socket
            echo_msg "Got power off msg"
            return
        else
            # still in progress
            echo_msg "Not receive poweroff msg, now waiting 10 sec"
            sleep 10
        fi
    
    done
}

#up_sock_svr
#read_sock_msg
