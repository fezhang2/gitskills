#!/bin/bash

l_os_type=`cat /etc/redhat-release | awk '{print $1}' | tr A-Z a-z `;
if [ $l_os_type = "red" ]; then
    l_os_ver=`cat /etc/redhat-release | awk '{print $5}'`;
    if [ $l_os_ver = "8.0" ]; then
        l_os_ver="8.0";
			  l_os_type="redhat";
	  elif [ $l_os_ver = "Server" ]; then
		    l_os_ver=`cat /etc/redhat-release | awk '{print $7}'`;
			  l_os_type="rhel";
    else
        l_os_ver="7.2";
			  l_os_type="redhat";
    fi;
else
    l_os_ver=`cat /etc/redhat-release | awk '{print $3}'`;
    l_os_type="centos"
fi;

echo "os:$l_os_type; version:$l_os_ver."
    
if [ "$l_os_type" = "centos" ]; then
    if [[ "$l_os_ver" > "6.0" ]]; then  
			make -f ./Makefile-redis all TOPDIR=$(pwd) version=$1 release=$2
    else
			echo "MCT redis plugin control not support centos version less than 6.0."
    fi
else
    echo "MCT redis plugin control not support non-centos linux system."
fi






