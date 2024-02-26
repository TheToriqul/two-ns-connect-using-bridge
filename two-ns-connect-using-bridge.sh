#!/bin/bash

# Check basic network status on the host machine/root namespace
sudo ip link
sudo ip route
sudo route -n
sudo lsns
sudo ip netns list

# Create a bridge network and attach IP to that interface
sudo ip link add br0 type bridge
sudo ip link set br0 up
sudo ip addr add 192.168.1.1/24 dev br0
sudo ip addr

# Create network namespaces
sudo ip netns add red
sudo ip netns add green
sudo ip netns list
sudo ls /var/run/netns/

# Set up loopback interfaces in namespaces
sudo ip netns exec red ip link set lo up
sudo ip netns exec red ip link
sudo ip netns exec green ip link set lo up
sudo ip netns exec green ip link

# Create veth interfaces for the namespaces
# For red namespace
sudo ip link add veth_red type veth peer name veth_br
sudo ip link set veth_red netns red
sudo ip link set veth_br master br0
sudo ip link set veth_br up
sudo ip link set veth_red up
sudo ip netns exec red ip addr add 192.168.1.10/24 dev veth_red

# For green namespace
sudo ip link add veth_green type veth peer name veth_br
sudo ip link set veth_green netns green
sudo ip link set veth_green up
sudo ip netns exec green ip addr add 192.168.1.11/24 dev veth_green

# Test network connectivity between namespaces
sudo ip netns exec red ping -c 2 192.168.1.1
sudo ip netns exec red ping -c 2 192.168.1.11
sudo ip netns exec green ping -c 2 192.168.1.1
sudo ip netns exec green ping -c 2 192.168.1.10
