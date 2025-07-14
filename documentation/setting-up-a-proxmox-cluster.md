## 2. Setting up a Proxmox Cluster

After acquiring three HP EliteDesk 800 G3 PCs from eBay, the first phase of my home datacentre project was to get them from bare metal to a fully-fledged, clustered virtualisation platform.

Each node had the following specs

- Intel Core i5-7500 CPU
- 8GB DDR4-2400 SDRAM (upto 64GB)
- 256GB SSD

All three cost me £84 (local collection only).

An absolute bargain! 😁

For networking the nodes I used a TP-Link TL-SG1016D 16-Port unmanaged gigabit switch.

### 2.1 Update BIOS
Before any operating system was installed, the first job was to update the system BIOS on all three machines. It’s a step that’s easy to overlook, but it’s fundamental for security and stability.

Running the latest BIOS version patches potential hardware vulnerabilities and ensures the best possible compatibility for the software to come.

### 2.2 Install Proxmox VE
With the hardware baseline set, I installed Proxmox Virtual Environment (VE) on each machine’s 256GB SSD.

Proxmox is an incredibly powerful, open-source hypervisor that can manage both full virtual machines and lighter-weight Linux Containers (LXC).

This flexibility makes it the perfect choice, where I plan to run a diverse range of services. You can find the installer and documentation over at the [Proxmox website](https://proxmox.com/).

### 2.3 Install Post-Installation Scripts
A fresh Proxmox install is geared towards commercial users, meaning it uses enterprise repositories that require a subscription for updates and displays a reminder notice each time you log in.

To better suit a home datacentre, I turned to the excellent

➡️[Proxmox VE Helper-Scripts](https://github.com/community-scripts/ProxmoxVE)

One of these scripts automates the process of switching to the public, non-subscription repositories, which also disables the subscription nag.

This allows for seamless, cost-free updates.

Always inspect scripts from third-party sources before executing them on your system.

➡️[Proxmox VE Post Install](https://community-scripts.github.io/ProxmoxVE/scripts?id=post-pve-install)

On your Proxmox node terminal

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/post-pve-install.sh)"
```
### 2.4 Update Processor Microcode
Using another of the helper scripts, I updated the Intel processor microcode on each server.

Microcode updates can fix hardware bugs, improve performance, and enhance security features of the processor.

➡️[Proxmox VE Processor Microcode](https://community-scripts.github.io/ProxmoxVE/scripts?id=microcode)

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/microcode.sh)"
```

### 2.5 Configuring Email Relay
I configured an SMTP relay on each Proxmox node using a dedicated Gmail account. This allows each machine to send me email notifications for system events, such as backup completions, hardware failures, or other alerts.

This can be configured manually or alternatively you can use this ➡️[automated script](scripts/setup_gmail_smtp_relay.sh).



Generate Gmail App Password
1. In your Google Account, go to **Security -> 2-Step Verification** and ensure it is enabled.
2. In the Security section, go to App passwords.
3. For ‘App’, select Mail. For ‘Device’, select Other, name it (e.g., “Proxmox“), and click Generate.
4. Copy the 16-character password and save it.

**Install Packages**
```
apt update
apt install -y libsasl2-modules mailutils
```
**Create Credential File**

Create and edit the password file
```
nano /etc/postfix/sasl_passwd
```
Add the following line, replacing the placeholders with your details
```
[smtp.gmail.com]:587 your-email@gmail.com:your-16-character-app-password
```
Secure the file and create the Postfix database for it
```
chmod 600 /etc/postfix/sasl_passwd
postmap hash:/etc/postfix/sasl_passwd
```
**Configure Postfix**

Edit the main configuration file
```
nano /etc/postfix/main.cf
```
Add these lines to the very end of the file
```
relayhost = [smtp.gmail.com]:587
smtp_use_tls = yes
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
```
**Apply and Test**

Reload the Postfix service to apply the new configuration
```
 systemctl reload postfix
```
Send a test email, replacing the placeholder with your destination email address
```
echo "This is a test email from Proxmox" | mail -s "Proxmox Test" your-personal-email@example.com
```
Check your inbox to confirm it was received.

### 2.6 Install Tailscale
To manage my home datacentre remotely, I installed [Tailscale](https://tailscale.com/) on each server.

Tailscale builds a secure, private network over the internet using WireGuard, meaning I can access the Proxmox control panel from anywhere as if I were on my local network.

**Run the Installation Script**

Execute the official Tailscale installation script in your Proxmox node’s terminal. This command adds the Tailscale repository and installs the package.
```
curl -fsSL https://tailscale.com/install.sh | sh
Connect your Node
```
Start Tailscale and connect the node to your account.
```
tailscale up
```
After running the command, a login URL will be displayed. Copy this URL, paste it into a web browser, and authenticate with your Tailscale account to add the node to your network.

**Verify Installation**

Check that Tailscale is active and see your node’s new IP address.
```
tailscale status
```
Your Proxmox node is now securely connected to your Tailnet.

### 2.7 Create the Proxmox Cluster
With the individual nodes prepped, it was time to unite them. I configured them into a Proxmox cluster, which allows all three machines to be managed as a single entity from one web interface.

I made a conscious decision not to enable high-availability storage at this point. This is due to a network bottleneck, as each server currently has only a single 1GbE network interface. A redundant, high-speed storage network is a planned future upgrade.

Of course. Here is a concise guide for creating a Proxmox cluster.

**Prerequisites**

All Proxmox nodes are installed and running on the same network.
The nodes can ping each other successfully by IP address.
Each node has a unique hostname.
You are logged into the web interface or terminal of all nodes.

### On the Main Node (Node 1)

#### Create the Cluster
In the terminal of your chosen main node, run the following command. Give your cluster a unique name without spaces.
```
pvecm create YourClusterName
```
#### Copy Join Information
In the Proxmox web interface, navigate to Datacenter -> Cluster and click the “Join Information” button. Click “Copy Information“. This copies the required connection details to your clipboard.

### On Each Joining Node (Node 2, Node 3 etc.)
#### Join the Cluster
In the web interface of the node you want to add, navigate to

**Datacenter -> Cluster**.

#### Paste Join Information
- Click the “Join Cluster“ button.
- Paste the information you copied from the main node into the “Information“ text box. The IP address and Fingerprint fields will fill automatically.
- Enter the root password for the main node (Node 1) when prompted.
- Click the “Join ‘YourClusterName“ button.
The node’s web interface will refresh as it joins the cluster. Repeat this step for any other nodes you wish to add.

#### Verify the Cluster
On any node, refresh the web interface. You should now see all connected nodes listed under the Datacenter view.

Alternatively, you can run the following command in any node’s terminal to see the cluster members:
```
pvecm nodes
```