#!/bin/bash

# Step 0: Check basic network status on host machine/root namespace
sudo ip link                                              # Display information about network interfaces
sudo ip route                                             # Show the kernel routing table
sudo route -n                                            # Show the kernel routing table (alternative command)
sudo lsns                                                 # List all network namespaces
sudo ip netns list                                    # List all network namespaces (alternative command)

# Step 1: Create a bridge network and attach IP to that interface
sudo ip link add br0 type bridge                    # Create a bridge interface named br0
sudo ip link set br0 up                                  # Activate the bridge interface
sudo ip addr add 192.168.1.1/24 dev br0       # Assign an IP address to the bridge interface
sudo ip addr                                              # Display IP addresses assigned to interfaces
ping -c 2 192.168.1.1                                   # Ping the bridge interface to test connectivity

# Step 2: Create two network namespaces
sudo ip netns add red                                  # Create a network namespace named red
sudo ip netns add green                             # Create a network namespace named green
sudo ip netns list                                    # List all network namespaces
sudo ls /var/run/netns/                            # List network namespace files in the filesystem

# Step 3: Loopback interface set up
sudo ip netns exec red ip link set lo up       # Enable loopback interface in red namespace
sudo ip netns exec red ip link                           # Display network interfaces in red namespace
sudo ip netns exec green ip link set lo up    # Enable loopback interface in green namespace
sudo ip netns exec green ip link                     # Display network interfaces in green namespace

# Step 4: Create two veth interfaces for two network namespaces
# For red:
sudo ip link add veth0 type veth peer name ceth0  # Create a pair of veth interfaces (veth0 and ceth0)
sudo ip link set veth0 master br0                           # Attach veth0 to the bridge br0
sudo ip link set veth0 up                                       # Activate veth0
sudo ip link                                                           # Display all network interfaces
sudo ip link set ceth0 netns red                              # Move ceth0 to red namespace
sudo ip netns exec red ip link set ceth0 up          # Activate ceth0 in red namespace
sudo ip netns exec red ip addr add 192.168.1.10/24 dev ceth0    # Assign IP address to ceth0 in red namespace
sudo ip netns exec red ping -c 2 192.168.1.10             # Ping ceth0 from within red namespace
sudo ip netns exec red ip route add default via 192.168.1.1    # Add default route in red namespace
sudo ip netns exec red ip route                                        # Display routing table in red namespace
sudo ip netns exec red ping -c 2 192.168.1.1                # Ping the bridge from red namespace

# For green:
sudo ip link add veth1 type veth peer name ceth1    # Create a pair of veth interfaces (veth1 and ceth1)
sudo ip link set veth1 master br0                            # Attach veth1 to the bridge br0
sudo ip link set veth1 up                                        # Activate veth1
sudo ip link                                                            # Display all network interfaces
sudo ip link set ceth1 netns green                         # Move ceth1 to green namespace
sudo ip netns exec green ip link set ceth1 up       # Activate ceth1 in green namespace
sudo ip netns exec green ip addr add 192.168.1.11/24 dev ceth1   # Assign IP address to ceth1 in green namespace
sudo ip netns exec green ping -c 2 192.168.1.11              # Ping ceth1 from within green namespace
sudo ip netns exec green ip route add default via 192.168.1.1     # Add default route in green namespace
sudo ip netns exec green ip route                                      # Display routing table in green namespace
sudo ip netns exec green ping -c 2 192.168.1.1                  # Ping the bridge from green namespace

# Step 5: Test network connectivity between two network namespaces
# from red:
sudo ip netns exec red ping -c 2 192.168.1.10            # Ping ceth0 from red namespace
sudo ip netns exec red ping -c 2 192.168.1.1               # Ping bridge from red namespace
sudo ip netns exec red ping -c 2 192.168.1.11              # Ping ceth1 from red namespace
ping -c 2 <host_IP_address>                              # Ping host from red namespace

# from green:
sudo ip netns exec green ping -c 2 192.168.1.11       # Ping ceth1 from green namespace
sudo ip netns exec green ping -c 2 192.168.1.1          # Ping bridge from green namespace
sudo ip netns exec green ping -c 2 192.168.1.10         # Ping ceth0 from green namespace
ping -c 2 <host_IP_address>                              # Ping host from green namespace
