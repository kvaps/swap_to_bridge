#!/bin/bash
#
# Usage:
# swap_to_bridge.sh eno1 br0
#
set -x
mount -o remount,exec /run
R=/run/root

INTERFACE="$1"
BRIDGE="$2"

# Wait for IP
while [ -z "$IPADDR" ]; do
  IPADDR="$(ip addr list $INTERFACE | grep -oP '(?<=inet )([0-9]+.){3}[0-9]+/[0-9]+' | tail -n1)"
  sleep 1
done
DEFROUTE="$(ip route | grep -oP '(?<=default via )([0-9]+.){3}[0-9]+')"

mkdir -p "$R/proc"
cp -r /bin /lib "$R"
mount -t proc none "$R/proc"
cat > "$R/script" <<EOF
echo brctl addbr "$BRIDGE"
brctl addbr "$BRIDGE"
echo brctl addif "$BRIDGE" "$INTERFACE"
brctl addif "$BRIDGE" "$INTERFACE"
echo ip link set "$BRIDGE" up
ip link set "$BRIDGE" up
echo ip addr flush "$INTERFACE"
ip addr flush "$INTERFACE"
echo ip addr add "$IPADDR" dev "$BRIDGE"
ip addr add "$IPADDR" dev "$BRIDGE"
echo ip route add "$DEFROUTE"
ip route add default via "$DEFROUTE" dev "$BRIDGE"
EOF
chroot "$R" busybox sh script
umount "$R/proc"
rm -rf "$R"
