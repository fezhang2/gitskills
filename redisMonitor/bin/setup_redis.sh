#!/bin/bash

#Author:        Jie
#CreateDate:    2012-01-10
#Environment:   Linux + Bash
#

source /etc/profile >/dev/null 2>&1
source /root/.bash_profile >/dev/null 2>&1
unalias -a
l_dir=`dirname $0`
cd ${l_dir}

#FunctionName:  Successful
#Description:   To confirm whether current action is Successful
#Result:        If true: 0  Else -1
function Successful()
{
    [ $? -eq 0 ] && return 0
    return -1
}

#FunctionName:  SetEnvironmentVar
#Description:   To set a variable
#Result:        If true: 0  Else -1
#Usage:         FileName Replace/Append VarName VarValue
function SetEnvironmentVar()
{
    local l_FileName=$1
    local l_Mode=$2
    local l_VarName=$3
    local l_VarValue=$4
    local l_KeyName=$5

    [ "${l_FileName}" == '' ] && return -1
    [ ! -f "${l_FileName}" ] && return -1
    [ "${l_VarName}" == '' -o "${l_VarValue}" == '' ] && return -1
    rm -rf ${l_FileName}.tmp >/dev/null 2>&1
    [ ! -f "${l_FileName}.org" ] && cp -pf ${l_FileName} ${l_FileName}.org >/dev/null 2>&1
    cp -pf ${l_FileName} ${l_FileName}.tmp >/dev/null 2>&1  
    if [ "${l_Mode}" == 'Replace' ]; then
        egrep -v "${l_VarName}=|export[[:space:]]{1,}${l_VarName}[[:space:]]*" ${l_FileName} >${l_FileName}.tmp 2>&1
    fi
    if [ "${l_Mode}" == 'Append' -a "${l_KeyName}" != '' ]; then
        egrep -v "${l_VarName}=.*${l_KeyName}" ${l_FileName} >${l_FileName}.tmp 2>&1 
    fi
    mv -f ${l_FileName}.tmp ${l_FileName} >/dev/null 2>&1
    echo "${l_VarName}=${l_VarValue}; export ${l_VarName}" >>${l_FileName} 2>/dev/null
    return 0
}

#FunctionName:  SetEnvironmentUlimit
#Description:   To set an ulimt
#Result:        If true: 0  Else -1
#Usage:         FileName KeyName KeyValue
function SetEnvironmentUlimit()
{
    local l_FileName=$1
    local l_KeyName=$2
    local l_KeyValue=$3

    [ "${l_FileName}" == '' ] && return -1
    [ ! -f "${l_FileName}" ] && return -1
    [ "${l_KeyName}" == '' -o "${l_KeyValue}" == '' ] && return -1
    rm -rf ${l_FileName}.tmp >/dev/null 2>&1
    [ ! -f "${l_FileName}.org" ] && cp -pf ${l_FileName} ${l_FileName}.org >/dev/null 2>&1
    cp -pf ${l_FileName} ${l_FileName}.tmp >/dev/null 2>&1
    egrep -v "ulimit[[:space:]]{1,}${l_KeyName}[[:space:]]{1,}" ${l_FileName} >${l_FileName}.tmp 2>&1
    mv -f ${l_FileName}.tmp ${l_FileName} >/dev/null 2>&1
    echo "ulimit ${l_KeyName} ${l_KeyValue} >/dev/null 2>&1" >>${l_FileName} 2>/dev/null
    return 0
}

function SetConfByKey()
{
    local l_conffile=$1
    local l_key=$2
    local l_newvalue=$3
    sed -i -r "s#$l_key(.*)#$l_key$l_newvalue#"  $l_conffile
}

l_PackageVersion=$1

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
    
if [ "$l_os_type" = "centos" ] && [[ "$l_os_ver" > "6.0" ]]; then        
    mct_default_mctuser="wbx-mct"
    finduname=`grep -E "^\<${mct_default_mctuser}\>" /etc/passwd |awk -F: '{print $1}'`
    finduid=`grep -E "^\<${mct_default_mctuser}\>" /etc/passwd |awk -F: '{print $3}'`
    findgid=`grep -E "^\<${mct_default_mctuser}\>" /etc/group |awk -F: '{print $3}'`
    if [ "${mct_default_mctuser}" != "${finduname}" ];then
        groupadd -g 5902 ${mct_default_mctuser} >/dev/null 2>/dev/null
        useradd -M -s /sbin/nologin -p '!mct@0)(!' --uid 5902 -g ${mct_default_mctuser} ${mct_default_mctuser} >/dev/null 2>/dev/null
        finduid=`grep -E "^\<${mct_default_mctuser}\>" /etc/passwd |awk -F: '{print $3}'`
        findgid=`grep -E "^\<${mct_default_mctuser}\>" /etc/group |awk -F: '{print $3}'`           
    fi

    if [ "5902" != "${finduid}" ];then
        echo "uid ${finduid} is error, set to 5902"
        usermod -u 5902 ${mct_default_mctuser}
    fi

    if [ "5902" != "${findgid}" ];then
        echo "gid ${findgid} is error, set to 5901"
        groupmod -g 5902 ${mct_default_mctuser}
        usermod -g 5902 ${mct_default_mctuser}    
    fi
		
    chown -R wbx-mct:wbx-mct ${l_dir}/../../../CI >/dev/null 2>&1
    chmod 710 ${l_dir}/../../../CI ${l_dir}/../../Identity  >/dev/null 2>&1
    chmod -R 750 ${l_dir}/../bin >/dev/null 2>&1
    chmod 710 ${l_dir}/../bin >/dev/null 2>&1
    chmod 640 ${l_dir}/../*.* >/dev/null 2>&1
fi


######################################################## added by Chao	[end] ########################################################