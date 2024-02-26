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

# Create two network namespaces
sudo ip netns add red
sudo ip netns add green
sudo ip netns list
sudo ls /var/run/netns/

# Set up loopback interfaces in namespaces
sudo ip netns exec red ip link set lo up
sudo ip netns exec red ip link
sudo ip netns exec green ip link set lo up
sudo ip netns exec green ip link

# Create two veth interfaces for two network namespaces
# For red namespace
sudo ip link add veth_red type veth peer name ceth_red
sudo ip link set veth_red master br0
sudo ip link set veth_red up
sudo ip link 
sudo ip link set ceth_red netns red
sudo ip netns exec red ip link set ceth_red up
sudo ip netns exec red ip addr add 192.168.1.10/24 dev ceth_red

# For green namespace
sudo ip link add veth_green type veth peer name ceth_green
sudo ip link set veth_green master br0
sudo ip link set veth_green up
sudo ip link 
sudo ip link set ceth_green netns green
sudo ip netns exec green ip link set ceth_green up
sudo ip netns exec green ip addr add 192.168.1.11/24 dev ceth_green

# Test network connectivity between namespaces
sudo ip netns exec red ping -c 2 192.168.1.1
sudo ip netns exec red ping -c 2 192.168.1.11
sudo ip netns exec green ping -c 2 192.168.1.1
sudo ip netns exec green ping -c 2 192.168.1.10

# Connect to the internet
sudo iptables -t nat -A POSTROUTING -s 192.168.1.0/24 ! -o br0 -j MASQUERADE

# Test internet connectivity from namespaces
sudo ip netns exec red ping -c 2 8.8.8.8
sudo ip netns exec green ping -c 2 8.8.8.8

# Listen for requests
sudo ip netns exec red python3 -m http.server --bind 192.168.1.10 5000

# Forward requests to the server
sudo iptables -t nat -A PREROUTING -d 172.31.13.55 -p tcp -m tcp --dport 5000 -j DNAT --to-destination 192.168.1.10:5000

# Run telnet from another source
telnet 65.2.35.192 5000
