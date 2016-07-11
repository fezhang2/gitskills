#!/bin/sh
#set -x

l_dir=$0
echo 'start redis_check'
python ${l_dir}/standalone_redis_monitor.py  "$1" "$2"
result=$?
if [${result} -ne 0]
then
	exit 2
else
	exit 0
fi

