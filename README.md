# Building a Home Data Centre
   1. [Introduction](#1-introduction)
   2. [Setting up a Proxmox Cluster](#2-setting-up-a-proxmox-cluster)
      1. [Update BIOS](#21-update-bios)
      2. [Install Proxmox VE](#22-install-proxmox-ve)
      3. [Install Post-Installation Scripts](#23-install-post-installation-scripts)
      4. [Update Processor Microcode](#24-update-processor-microcode)
      5. [Configuring Email Relay](#25-configuring-email-relay)
      6. [Install Tailscale](#26-install-tailscale)
      7. [Create the Proxmox Cluster](#27-create-the-proxmox-cluster)
## 1. Introduction
I’m planning to build a mini self hosted data centre. In my house. Yes, you read that correctly. Not just a fancy computer tucked under the stairs, but a proper (ish) setup with servers and networking gear.

And the first question that probably pops into your head, quite reasonably, is “Why on earth would you do that?“

It’s a fair question. It’s one my partner has asked, usually with a slightly raised eyebrow. And to be honest, it’s one I’ve asked myself a few times, when staring at a bewildering array of eBay server listings at 2 AM.

### The Allure of Doing It Yourself (When You Probably Shouldn’t)
So, why embark on this slightly unhinged quest? Well, it’s a few things, really.

I want to learn. I’ve always had this nagging curiosity about how the internet actually works. Not just the cat videos and angry political discussions, but the underlying nuts and bolts. I’ve tinkered with software, dabbled with coding, but the idea of running my own servers, managing my own little corner of the digital world, has always been there, lurking in the background.

I’ve set myself a bit of a challenge. It’s easy to throw money at a problem. Need more computing power? Spin up another instance on AWS. Need more storage? Click a button, enter your credit card details. And there’s nothing wrong with that – it’s incredibly convenient.

But I’m curious, how much can I achieve on a shoestring budget? How can I squeeze every last drop of performance out of my limited hardware. Can I build something that’s not just functional, but also power-efficient and relatively inexpensive to keep humming along 24/7?

And yes, okay, the thought of those ever-escalating cloud hosting bills does play a part. I know, you often get what you pay for, and the convenience of cloud services is undeniable. But for personal projects, for tinkering, for learning, the idea of having a fixed (and hopefully low) cost, rather than a meter constantly ticking, is quite appealing.

Plus, it sounds like a bit of fun. There’s a certain satisfaction in building something yourself, in understanding it from the ground up.

### Why a “Home Data Centre” and Not Just, You Know, a Server?
You might be thinking, “Okay, fine, you want to run a server. Why the grand ‘home data centre’ label?“

It’s because my ambition (or delusion) stretches a bit further than just one box. I want to learn it all – the hardware (what makes a good server? How does ZFS actually work? What’s ECC RAM and do I need it?), the software (operating systems, virtualisation, containers – it’s a whole new language), and the networking that glues it all together (VLANs, firewalls, VPNs). If I can get a better understanding of how all these pieces fit together, even on a small scale, that feels like a genuinely valuable skill.

### Constraints Breed Innovation
I don’t have deep pockets. I don’t have a dedicated, air-conditioned server room (my spare room will have to do). My thinking is that these limitations might just force me to find more creative, more innovative solutions to the problems I’ll inevitably encounter. It’s a challenge, and I’m (mostly) up for it.

### The Plan
It’s still evolving. But the core idea is to document this journey – the successes, the inevitable failures, the “aha!” moments, and the “why did I think this was a good idea?” moments. I’ll be sharing what I learn about choosing hardware, setting up operating systems, wrangling networks, and trying to get useful services up and running.

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