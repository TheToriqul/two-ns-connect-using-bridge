#!/bin/bash

# Step 0: Check basic package installation & network status on host machine/root namespace
sudo apt update -y
sudo apt upgrage -y
sudo apt install net-tools -y
sudo apt install iproute2 -y
sudo apt install iputils-ping -y
sudo apt install tcpdump -y
sudo apt install iptables -y

sudo ip link          # Display information about network interfaces
sudo ip route         # Show the kernel routing table
sudo route -n         # Show the kernel routing table (alternative command)
sudo ip netns list    # List all network namespaces (using recommended command)

# Step 1: Create two network namespaces
sudo ip netns add red                      # Create a network namespace named red
sudo ip netns add green                    # Create a network namespace named green
sudo ip netns list                         # List all network namespaces
sudo ls /var/run/netns/

# Step 2: Create a bridge network and attach IP to that interface
sudo ip link add br0 type bridge           # Create a bridge interface named br0
sudo ip link set br0 up                    # Activate the bridge interface
sudo ip addr add 192.168.1.1/24 dev br0    # Assign an IP address to the bridge interface
sudo ip addr                               # Display IP addresses assigned to interfaces
ping -c 2 192.168.1.1                      # Ping the bridge interface to test connectivity

# Step 3: Create two veth interfaces for two network namespaces

# For red:
sudo ip link add veth0 type veth peer name ceth0                  # Create a pair of veth interfaces
sudo ip link set ceth0 netns red                                  # Move ceth0 to red namespace and activate it within the namespace
sudo ip netns exec red ip link set ceth0 up
sudo ip link set veth0 master br0                                 # Attach veth0 to the bridge br0 after creation
sudo ip link set veth0 up
sudo ip link                                                      # Display all network interfaces
sudo ip netns exec red ip addr add 192.168.1.10/24 dev ceth0      # Assign IP address to ceth0 after attaching it to the namespace
sudo ip netns exec red ping -c 2 192.168.1.10                     # Test connectivity within the red namespace and add default route
sudo ip netns exec red ip route add default via 192.168.1.1
sudo ip netns exec red ip route
sudo ip netns exec red ping -c 2 192.168.1.1

# For green: (repeat similar steps as red)
sudo ip link add veth1 type veth peer name ceth1
sudo ip link set ceth1 netns green
sudo ip netns exec green ip link set ceth1 up
sudo ip link set veth1 master br0
sudo ip link set veth1 up
sudo ip link
sudo ip netns exec green ip addr add 192.168.1.11/24 dev ceth1
sudo ip netns exec green ping -c 2 192.168.1.11
sudo ip netns exec green ip route add default via 192.168.1.1
sudo ip netns exec green ip route
sudo ip netns exec green ping -c 2 192.168.1.1

# Step 4: Loopback interface set up
sudo ip link set lo up                            # Enable loopback interface in host machine
sudo ip netns exec red ip link set lo up          # Enable loopback interface in red namespace
sudo ip netns exec red ip link                    # Display network interfaces in red namespace
sudo ip netns exec green ip link set lo up        # Enable loopback interface in green namespace
sudo ip netns exec green ip link                  # Display network interfaces in green namespace

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

# Step 6: Connect to the internet
sudo iptables -t nat -L -n -v                                         # Checking the iptables rules
sudo iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -j MASQUERADE   # Enable NAT for internet connectivity

# In case if still it not works then we may need to add some additional firewall rules.
sudo iptables --append FORWARD --in-interface br0 --jump ACCEPT
sudo iptables --append FORWARD --out-interface br0 --jump ACCEPT

# Test internet connectivity from both namespaces (replace `<host_IP_address>` with actual IP)
sudo ip netns exec red ping -c 3 8.8.8.8
sudo ip netns exec green ping -c 3 8.8.8.8

# Step 7: Listen for the requests (replace "python3" with the appropriate command if using a different interpreter)
sudo ip netns exec red python3 -m http.server --bind 192.168.1.10 5000          # Start HTTP server in red namespace

# (Assuming you want to access the server from outside):
# Set up port forwarding on the host machine to forward traffic from a specific port (e.g., port 8080)
# to the bridge interface (port 5000). This step is not included in the script as it requires additional configuration.

# Run telnet from another source (replace `<host_IP_address>` with actual IP)
telnet <host_IP_address> 5000                  # Test port forwarding using telnet

# **Note:** This script creates resources that should be cleaned up after use. Consider adding cleanup logic for namespaces, veth interfaces, and iptables rules.
