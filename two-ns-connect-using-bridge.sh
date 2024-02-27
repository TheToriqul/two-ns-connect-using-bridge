#!/bin/bash

# Step 0: Check basic network status on host machine/root namespace
sudo ip link          # Display information about network interfaces
sudo ip route         # Show the kernel routing table
sudo route -n         # Show the kernel routing table (alternative command)
sudo ip netns list    # List all network namespaces (using recommended command)

# Step 1: Create a bridge network and attach IP to that interface
sudo ip link add br0 type bridge           # Create a bridge interface named br0
sudo ip link set br0 up                    # Activate the bridge interface
sudo ip addr add 192.168.1.1/24 dev br0    # Assign an IP address to the bridge interface
sudo ip addr                               # Display IP addresses assigned to interfaces
ping -c 2 192.168.1.1                      # Ping the bridge interface to test connectivity

# Step 2: Create two network namespaces
sudo ip netns add red                      # Create a network namespace named red
sudo ip netns add green                    # Create a network namespace named green
sudo ip netns list                         # List all network namespaces
sudo ls /var/run/netns/

# Step 3: Loopback interface set up
sudo ip netns exec red ip link set lo up          # Enable loopback interface in red namespace
sudo ip netns exec red ip link                    # Display network interfaces in red namespace
sudo ip netns exec green ip link set lo up        # Enable loopback interface in green namespace
sudo ip netns exec green ip link                  # Display network interfaces in green namespace

# Step 4: Create two veth interfaces for two network namespaces

# For red:
sudo ip link add veth0 type veth peer name ceth0                  # Create a pair of veth interfaces
sudo ip link set veth0 master br0                                 # Attach veth0 to the bridge br0 after creation
sudo ip link set veth0 up
sudo ip link                                                      # Display all network interfaces
sudo ip link set ceth0 netns red                # Move ceth0 to red namespace and activate it within the namespace
sudo ip netns exec red ip link set ceth0 up
sudo ip netns exec red ip addr add 192.168.1.10/24 dev ceth0      # Assign IP address to ceth0 after attaching it to the namespace
sudo ip netns exec red ping -c 2 192.168.1.10                     # Test connectivity within the red namespace and add default route
sudo ip netns exec red ip route add default via 192.168.1.1
sudo ip netns exec red ip route
sudo ip netns exec red ping -c 2 192.168.1.1

# For green: (repeat similar steps as red)
sudo ip link add veth1 type veth peer name ceth1
sudo ip link set veth1 master br0
sudo ip link set veth1 up
sudo ip link
sudo ip link set ceth1 netns green
sudo ip netns exec green ip link set ceth1 up
sudo ip netns exec green ip addr add 192.168.1.11/24 dev ceth1
sudo ip netns exec green ping -c 2 192.168.1.11
sudo ip netns exec green ip route add default via 192.168.1.1
sudo ip netns exec green ip route
sudo ip netns exec green ping -c 2 192.168.1.1

# Step 5: Test network connectivity between two network namespaces
# from red:
sudo ip netns exec red ping -c 2 192.168.1.10
sudo ip netns exec red ping -c 2 192.168.1.1
sudo ip netns exec red ping -c 2 192.168.1.11
sudo ip netns exec red ping -c 2 <host_IP_address>       # Replace <host_IP_address> with the actual IP address of the host machine

# from green: (repeat similar steps as red)
sudo ip netns exec green ping -c 2 192.168.1.11
sudo ip netns exec green ping -c 2 192.168.1.1
sudo ip netns exec green ping -c 2 192.168.1.10
sudo ip netns exec green ping -c 2 <host_IP_address>
