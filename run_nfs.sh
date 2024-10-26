#!/bin/bash

# Copyright 2015 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function start()
{
    unset gid
    # accept "-G gid" option
    while getopts "G:" opt; do
        case ${opt} in
            G) gid=${OPTARG};;
        esac
    done
    shift $(($OPTIND - 1))

    # prepare /etc/exports
    for i in "$@"; do
        # fsid=0: needed for NFSv4
        echo "$i *(rw,no_subtree_check,no_root_squash,no_all_squash)" >> /etc/exports
        if [ -v gid ] ; then
            chmod 070 $i
            chgrp $gid $i
        fi
        echo "Serving $i"
    done
  
    # start rpcbind if it is not started yet
    /usr/sbin/rpcinfo 127.0.0.1 > /dev/null; s=$?
    if [ $s -ne 0 ]; then
       echo "Starting rpcbind"
       /usr/sbin/rpcbind -w -f
    fi

    mount -t nfsd nfsd /proc/fs/nfsd

    # enable NFSv3, NFSv4
    rpc.mountd

    exportfs -r
    # -G 10 to reduce grace time to 10 seconds (the lowest allowed)
    rpc.nfsd
    rpc.statd --no-notify
    echo "NFS started"
}

function stop()
{
    echo "Stopping NFS"

    rpc.nfsd 0
    exportfs -au
    exportfs -f

    kill $(pidof rpc.mountd)
    umount /proc/fs/nfsd
    echo > /etc/exports
    exit 0
}

trap stop TERM

start "$@"

# Ugly hack to do nothing and wait for SIGTERM
while true; do
    sleep 5
done
