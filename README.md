# Connecting Two Islands: Namespaces Bridged Together and Connected to the Internet

Imagine two separate islands, each with its own unique environment and resources. To connect and enable communication between them, we can build a bridge. This project is similar, but instead of physical islands, we're dealing with virtual namespaces.

Namespaces are like isolated containers within a system, holding their own network resources like IP addresses and routing tables. This project aims to **connect two such namespaces** using a **bridge**, allowing them to **communicate and share data**.

Think of the bridge as a central hub, forwarding messages between the two islands (namespaces). This connection can be useful for various purposes, such as:

* **Isolating network segments:** Keeping different parts of a system's network separate while enabling controlled communication.
* **Testing and development:** Creating isolated environments for testing applications or configurations without affecting the main system.
* **Security:** Enhancing security by restricting communication between different parts of the system.


**Key Components:**

- **Namespaces:** The two independent environments you want to connect. (Specific nature and purpose may vary depending on the use case.)
- **Bridge:** A virtual network device that forwards traffic between the namespaces according to defined rules. It operates at the data link layer (Layer 2) of the OSI model.

**Implementation Steps (General Guide):**

1. **Create Namespaces:** Establish the two isolated environments using system or programming language-specific commands or functions. The exact method depends on the context and technology involved.
2. **Select Bridge Type:** Choose an appropriate bridge implementation based on your requirements. Common options include software-based bridges (e.g., Linux brctl) or virtual switch appliances.
3. **Connect Interfaces:** Attach network interfaces (virtual or physical) to the bridge. These interfaces provide communication channels between the namespaces and the bridge itself.
4. **Configure Bridge:** Set up necessary parameters for the bridge, such as filtering rules, forwarding policies, and security measures.
5. **Assign IP Addresses:** Configure IP addresses for the interfaces within each namespace, ensuring unique addresses to enable communication without conflicts.
6. **Activate Interfaces:** Bring up the interfaces in both namespaces and the bridge to allow network traffic to flow.
7. **Verify Connection:** Test the connection between the namespaces by pinging or using other network communication tools.

**Use Cases and Benefits:**

- **Virtualization:** Enable secure, segregated network environments for virtual machines or containers, preventing resource contention and potential security risks.
- **Testing and Development:** Create isolated test environments for applications or services without affecting the production system.
- **Network Segmentation:** Divide a network into smaller, manageable segments for improved security and traffic control.
- **Process Isolation:** Isolate critical processes from the main system for enhanced reliability and security.


## Deep Dive into Network Namespaces and Bridging: A Step-by-Step Analysis

The provided script delves into the realm of network namespaces and bridging, creating isolated network environments and enabling their communication with the internet. It also demonstrates setting up a basic server and port forwarding. Let's dissect each step, unraveling the underlying concepts and their significance:

**0. Initial Network Assessment:**

The script commences by meticulously examining the host machine's network status using various commands:

- `ip link`: Unveils existing network interfaces and their configurations.
- `ip route`: Presents active routing tables, displaying how packets are directed.
- `route -n`: Offers a numerical rendition of the routing table, useful for detailed analysis.
- `lsns`: Lists currently established network namespaces.
- `ip netns list`: Provides a more comprehensive overview of available network namespaces, including their PIDs and creation times.

**Step 1: Create Bridge Network (Lines 6-10)**

* `sudo ip link add br0 type bridge`: Creates a new bridge interface named `br0`.
* `sudo ip link set br0 up`: Activates the bridge interface.
* `sudo ip addr add 192.168.1.1/24 dev br0`: Assigns an IP address (`192.168.1.1/24`) to the bridge interface.
* `sudo ip addr`: Displays information about all network interfaces, including the newly created bridge.
* `ping -c 2 192.168.1.1`: Tests connectivity to the bridge by pinging its IP address.

**Step 2: Create Network Namespaces (Lines 12-14)**

* `sudo ip netns add red`: Creates a new network namespace named `red`.
* `sudo ip netns add green`: Creates another new network namespace named `green`.
* `sudo ip netns list`: Lists all existing network namespaces on the system.
* `sudo ls /var/run/netns/`: Shows the files representing the created namespaces in the filesystem.

**Step 3: Enable Loopback Interfaces (Lines 16-19)**

* `sudo ip netns exec red ip link set lo up`: Activates the loopback interface (lo) within the `red` namespace, allowing basic network communication within the namespace.
* `sudo ip netns exec red ip link`: Displays information about network interfaces within the `red` namespace.
* Similar commands are repeated for the `green` namespace, enabling its loopback interface.

**Step 4: Create and Connect Veth Interfaces (Lines 21-54)**

* **For red namespace:**
    * `sudo ip link add veth0 type veth peer name ceth0`: Creates a pair of virtual ethernet interfaces named `veth0` and `ceth0`. They act like virtual cables connecting the namespaces to the bridge.
    * `sudo ip link set veth0 master br0`: Attaches `veth0` to the bridge `br0`.
    * `sudo ip link set veth0 up`: Activates `veth0`.
    * `sudo ip link set ceth0 netns red`: Moves `ceth0` to the `red` namespace.
    * Commands within `sudo ip netns exec red` configure the `red` namespace:
        * `ip link set ceth0 up`: Activates `ceth0` within the namespace.
        * `ip addr add 192.168.1.10/24 dev ceth0`: Assigns an IP address (`192.168.1.10/24`) to `ceth0`.
        * `ping -c 2 192.168.1.10`: Tests connectivity to `ceth0` from within the `red` namespace.
        * `ip route add default via 192.168.1.1`: Sets the default route for the `red` namespace, directing traffic through the bridge (`192.168.1.1`).
        * `ip route`: Displays the routing table within the `red` namespace.
        * `ping -c 2 192.168.1.1`: Tests connectivity to the bridge from the `red` namespace.
* **Similar commands are repeated for the `green` namespace**, creating `veth1` and `ceth1`, assigning an IP address (`192.168.1.11/24`), and configuring routing.

**Step 5: Test Connectivity between Namespaces (Lines 56-67)**

* `ping -c 2 192.168.1.1`: Pings the bridge IP address from the `red` namespace.
* `ping -c 2 192.168.1.11`: Pings the IP address of the `green` namespace (`ceth1`) from the `red` namespace.
* `ping -c 2 <host_IP_address>`: Replace `<host_IP_address>` with a real IP address and ping it from the `red` namespace to test external connectivity (requires additional configuration in Step 6).

Similar commands are executed within `sudo ip netns exec green` to test connectivity from the `green` namespace:

* `ping -c 2 192.168.1.11`: Pings its own IP address (`ceth1`).
* `ping -c 2 192.168.1.1`: Pings the bridge IP address from the `green` namespace.
* `ping -c 2 192.168.1.10`: Pings the IP address of the `red` namespace (`ceth0`) from the `green` namespace.
* `ping -c 2 <host_IP_address>`: Replace `<host_IP_address>` with a real IP address and ping it from the `green` namespace (requires additional configuration).

**Step 6: Connect to the Internet (Lines 69-73)**

* These lines are commented out by default. Uncommenting and applying them enables internet access for the namespaces.
* `sudo iptables`: This command is used to configure firewall rules.
* `-t nat`: Specifies that the following rules apply to the NAT (Network Address Translation) table.
* `-A POSTROUTING`: Specifies that the rule will be inserted into the POSTROUTING chain, which modifies packets after routing decisions are made.
* `-s 192.168.1.0/24`: Selects packets originating from the `192.168.1.0/24` subnet (created namespaces).
* `! -o br0`: Excludes packets that are already leaving through the bridge interface (`br0`).
* `-j MASQUERADE`: Instructs the firewall to rewrite the source IP address of the packets to the IP address of the host machine, enabling them to reach the internet through the host's connection.

**Uncommenting and running these lines allow internet access within the namespaces.**

**Step 7: Listen for Requests (Lines 75-80)**

* This section demonstrates setting up a simple HTTP server within the `red` namespace.
* `sudo ip netns exec red python3 -m http.server --bind 192.168.1.10 5000`: This command starts a server listening on port 5000 within the `red` namespace, accessible at its IP address (`192.168.1.10`).

**Additional configuration (commented out) is required to forward traffic from the host machine to the server:**

* `sudo iptables`: Similar to Step 6, this line is used for firewall rules.
* `-t nat`: Specifies the NAT table.
* `-A PREROUTING`: Specifies the PREROUTING chain, which modifies packets before routing decisions are made.
* `<host_IP_address>`: Replace this with the actual IP address of your host machine.
* `-p tcp -m tcp --dport 5000`: Selects incoming TCP packets directed to port 5000 on the host machine.
* `-j DNAT --to-destination 192.168.1.10:5000`: Redirects those packets to the server running in the `red` namespace on port 5000.

**Uncommenting and applying these rules allow accessing the server from outside the namespaces using the host machine's IP address and port 5000.**

**Step 8: Run Telnet (Line 82)**

* This line is commented out and demonstrates testing the port forwarding using the `telnet` command.
* Replace `<host_IP_address>` with the IP address of your host machine and run the command to connect to port 5000 and interact with the server.

**Remember:**

- This script requires root privileges to execute due to network configuration commands.
- Replace IP addresses and ports as needed for your specific use case.
- Ensure proper firewall configurations are in place for security when enabling internet access within namespaces.
- This script provides a basic example and might require adjustments for your specific network configuration.
- Modifying network configurations and using tools like iptables can impact your system's security and functionality. Proceed with caution and understand the potential risks.

In essence, the script meticulously constructs a network environment with isolated namespaces that can communicate internally and access the internet. It showcases fundamental concepts like bridging, NAT, and basic firewall rules to achieve this functionality.

Feel free to ask if you have any further questions! *Email: ``` toriqul.int@gmail.com ```*
