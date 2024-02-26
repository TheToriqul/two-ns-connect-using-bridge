#!/bin/bash

# Check basic network status on the host machine/root namespace
sudo ip link                                     # List all network interfaces
sudo ip route                                    # Show the routing table
sudo route -n                                    # Show the routing table in a numeric format
sudo lsns                                        # List all network namespaces
sudo ip netns list                              # List all network namespaces

# Create a bridge network and attach IP to that interface
sudo ip link add br0 type bridge                # Create a bridge interface named br0
sudo ip link set br0 up                         # Activate the bridge interface br0
sudo ip addr add 192.168.1.1/24 dev br0         # Assign an IP address to the bridge interface br0
sudo ip addr                                    # Display IP addresses assigned to all interfaces

# Create two network namespaces
sudo ip netns add red                           # Create a network namespace named red
sudo ip netns add green                         # Create a network namespace named green
sudo ip netns list                              # List all network namespaces
sudo ls /var/run/netns/                         # List the network namespace files in the /var/run/netns/ directory

# Set up loopback interfaces in namespaces
sudo ip netns exec red ip link set lo up        # Set up the loopback interface in the red namespace
sudo ip netns exec red ip link                  # Display the interfaces in the red namespace
sudo ip netns exec green ip link set lo up      # Set up the loopback interface in the green namespace
sudo ip netns exec green ip link                # Display the interfaces in the green namespace

# Create two veth interfaces for two network namespaces
# For red namespace
sudo ip link add veth_red type veth peer name ceth_red  # Create a veth pair with one end in the root namespace and the other end in the red namespace
sudo ip link set veth_red master br0                     # Attach one end of the veth pair to the bridge br0
sudo ip link set veth_red up                              # Activate the veth_red interface
sudo ip link                                               # List all network interfaces
sudo ip link set ceth_red netns red                      # Move the other end of the veth pair to the red namespace
sudo ip netns exec red ip link set ceth_red up           # Activate the ceth_red interface in the red namespace
sudo ip netns exec red ip addr add 192.168.1.10/24 dev ceth_red  # Assign an IP address to the ceth_red interface in the red namespace

# For green namespace
sudo ip link add veth_green type veth peer name ceth_green  # Create a veth pair with one end in the root namespace and the other end in the green namespace
sudo ip link set veth_green master br0                       # Attach one end of the veth pair to the bridge br0
sudo ip link set veth_green up                                # Activate the veth_green interface
sudo ip link                                                 # List all network interfaces
sudo ip link set ceth_green netns green                      # Move the other end of the veth pair to the green namespace
sudo ip netns exec green ip link set ceth_green up           # Activate the ceth_green interface in the green namespace
sudo ip netns exec green ip addr add 192.168.1.11/24 dev ceth_green  # Assign an IP address to the ceth_green interface in the green namespace

# Test network connectivity between namespaces
sudo ip netns exec red ping -c 2 192.168.1.1     # Ping the bridge IP address from the red namespace
sudo ip netns exec red ping -c 2 192.168.1.11    # Ping the IP address assigned to the ceth_green interface from the red namespace
sudo ip netns exec green ping -c 2 192.168.1.1   # Ping the bridge IP address from the green namespace
sudo ip netns exec green ping -c 2 192.168.1.10  # Ping the IP address assigned to the ceth_red interface from the green namespace
