#!/bin/bash
set -x
mount -o remount,exec /run
R=/run/root
IPADDR="$(ip addr list eno1 | grep -oP '(?<=inet )([0-9]+.){3}[0-9]+/[0-9]+' | tail -n1)"
DEFROUTE="$(ip route | grep -oP '(?<=default via )([0-9]+.){3}[0-9]+')"
mkdir -p "$R/proc"
cp -r /bin /lib "$R"
mount -t proc none "$R/proc"
cat > "$R/script" <<EOF
echo brctl addbr br0
brctl addbr br0
sleep 2
echo brctl addif br0 eno1
brctl addif br0 eno1
sleep 2
echo ip link set br0 up
ip link set br0 up
sleep 2
echo ip addr flush eno1
ip addr flush eno1
sleep 2
echo ip addr add "$IPADDR" dev br0
ip addr add "$IPADDR" dev br0
sleep 2
echo ip route add "$DEFROUTE"
ip route add default via "$DEFROUTE" dev br0
EOF
chroot "$R" busybox sh script
umount "$R/proc"
rm -rf "$R"
