# 4.0 Virtual Machines

While Proxmox offers lightweight LXC containers, VMs were chosen to provide a greater level of security and a richer feature set by ensuring full kernel-level isolation.

The chosen operating system for the VMs is Ubuntu Server. This decision was based on familiarity with the platform and its extensive community support. Although a more recent version of Ubuntu Server was initially installed, it is generally recommended to use the Long-Term Support (LTS) version for production environments due to its focus on stability and extended support window.

Setting up a VM in Proxmox is a straightforward process. For optimal performance and features, the following settings are recommended:

*   **Memory:** Enable the 'Ballooning Device' option. This allows for dynamic memory allocation, where the VM can request more RAM from the host when needed and release it when idle, improving overall resource utilisation.
*   **Processor:** Set the 'Type' to 'host'. This passes the host CPU's features directly to the VM, which can significantly boost performance by enabling all the instruction sets of the host CPU.
*   **Machine Type:** Select 'Q35'. This is the recommended machine type for modern systems as it provides support for more recent technologies out-of-the-box, including PCI Express, NVMe emulation, and USB 3.0.

## 4.1 QEMU Guest Agent

The QEMU Guest Agent is an important service that should be installed on all VMs running in a Proxmox environment. It acts as a bridge between the Proxmox host and the guest operating system.

**Key benefits of installing the QEMU Guest Agent include:**

*   **Graceful Shutdown and Reboot:** Allows Proxmox to properly shut down or reboot the VM from the web interface without having to force the power off, which can lead to data corruption.
*   **Live Snapshots:** The agent is crucial for creating consistent, live snapshots by quiescing the guest's file system during the backup process.
*   **Accurate Information:** It enables the Proxmox host to retrieve detailed information from the VM, such as its IP addresses, which is then displayed in the Proxmox summary panel.
*   **Improved Resource Management:** Facilitates features like memory ballooning.

**Installation Steps:**

First, ensure the 'Guest Agent' option is enabled in the VM's 'Options' tab within the Proxmox web interface. Then, connect to your Ubuntu Server VM and run the following commands.

1.  Update your package lists:
    ```bash
    sudo apt update
    ```

2.  Install the agent:
    ```bash
    sudo apt install qemu-guest-agent -y
    ```

3.  Start and enable the service to ensure it runs on boot:
    ```bash
    sudo systemctl start qemu-guest-agent
    sudo systemctl enable qemu-guest-agent
    ```

After installation, a reboot is recommended. You should then see the VM's IP addresses on the 'Summary' page in the Proxmox UI.

## 4.2 Setting up Email Relay

To configure the VM to send email notifications, for services like `unattended-upgrades`, an email relay needs to be set up. The process is identical to configuring the Proxmox host itself.

Please refer to the detailed instructions in the main project documentation:
[Setting up a Proxmox Cluster: 2.5 Configuring Email Relay](https://github.com/authorTom/home-data-centre/blob/main/documentation/setting-up-a-proxmox-cluster.md#25-configuring-email-relay)

## 4.3 Installing Tailscale

Tailscale provides a secure and straightforward way to connect to your VMs from anywhere.

For installation instructions, please see:
[Setting up a Proxmox Cluster: 2.6 Install Tailscale](https://github.com/authorTom/home-data-centre/blob/main/documentation/setting-up-a-proxmox-cluster.md#26-install-tailscale)

## 4.4 Unattended-Upgrades

The `unattended-upgrades` package is a vital tool for maintaining system security by automatically installing the latest security updates. Configuring it to send email notifications ensures you are always aware of the changes made to your system.

The primary configuration file is located at `/etc/apt/apt.conf.d/50unattended-upgrades`.

1.  Open the configuration file using a text editor such as `nano`:
    ```bash
    sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
    ```

2.  Enable and configure email notifications. Find the following line, uncomment it by removing the `//`, and replace the placeholder with your email address:
    ```diff
    - //Unattended-Upgrade::Mail "root";
    + Unattended-Upgrade::Mail "your-email@example.com";
    ```

3.  Specify when to receive emails. The `Unattended-Upgrade::MailOnlyOnError` option controls the frequency of notifications. To receive an email every time an upgrade occurs, ensure this line is either commented out or set to `false`:
    ```bash
    // Unattended-Upgrade::MailOnlyOnError "true";
    ```
    or
    ```bash
    Unattended-Upgrade::MailOnlyOnError "false";
    ```

4.  Save your changes and exit the editor (in `nano`, press `Ctrl+X`, then `Y`, and `Enter`).

5.  To test your configuration, you can perform a dry run. This simulates the upgrade process and should trigger an email if everything is configured correctly and updates are pending.
    ```bash
    sudo unattended-upgrades --debug --dry-run
    ```
    Check the command output for any errors and monitor your inbox (including the spam folder) for the notification.

## 4.5 Installing Docker and Docker Compose

Docker is a platform for developing, shipping, and running applications in containers. Docker Compose is a tool for defining and running multi-container Docker applications.

**Installation Steps:**

These steps follow the official Docker repository method, which is the recommended approach.

1.  Set up Docker's `apt` repository.
    ```bash
    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    ```

2.  Install the Docker packages.
    ```bash
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    ```

3.  (Optional but recommended) Add your user to the `docker` group to run Docker commands without `sudo`. You will need to log out and back in for this change to take effect.
    ```bash
    sudo usermod -aG docker $USER
    ```

4.  Verify the installation by running the "hello-world" container.
    ```bash
    docker run hello-world
    ```

## 4.6 Watchtower

Watchtower is a container that monitors your running Docker containers and automatically updates them to the latest image available. This simplifies maintenance and ensures your applications are always running the most recent, and often more secure, versions.

**Installation:**

Watchtower runs as a Docker container itself. The simplest way to deploy it is with the following `docker run` command:

```bash
docker run -d \
  --name watchtower \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower
```

This command starts Watchtower and gives it access to the Docker socket, allowing it to manage other containers on the host. By default, it will check for new images every 24 hours.

## 4.7 Portainer

Portainer is a powerful, lightweight management UI that allows you to easily manage your Docker environments. It provides a detailed overview of your containers, images, volumes, and networks, and allows you to deploy applications quickly and easily through its web interface.

**Installation:**

1.  First, create a volume for Portainer to store its data:
    ```bash
    docker volume create portainer_data
    ```

2.  Now, run the Portainer Server container:
    ```bash
    docker run -d -p 8000:8000 -p 9443:9443 --name portainer \
        --restart=always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v portainer_data:/data \
        portainer/portainer-ce:latest
    ```
    This command starts the Portainer Community Edition, exposes its UI on port `9443` (HTTPS), and ensures it restarts automatically.

Once running, you can access the Portainer UI by navigating to `https://<your-vm-ip>:9443` in your web browser. You will be prompted to create an administrator account on your first visit.

## 4.8 Fail2ban

Fail2ban is an intrusion prevention software framework that protects computer servers from brute-force attacks. It works by monitoring log files (e.g., `/var/log/auth.log`) for suspicious activity, such as repeated failed login attempts, and temporarily bans the offending IP addresses using firewall rules.

**Installation and Configuration:**

1.  Install the Fail2ban package:
    ```bash
    sudo apt update
    sudo apt install fail2ban -y
    ```

2.  The default configuration is stored in `/etc/fail2ban/jail.conf`. You should not edit this file directly. Instead, create a local configuration file to make your customisations, which will override the defaults.
    ```bash
    sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    ```

3.  Open your new local configuration file to customise the settings. For example, you can enable the SSH protection jail.
    ```bash
    sudo nano /etc/fail2ban/jail.local
    ```

4.  Inside `jail.local`, find the `[sshd]` section and ensure it is enabled:
    ```ini
    [sshd]
    enabled = true
    port    = ssh
    logpath = %(sshd_log)s
    backend = %(sshd_backend)s
    ```

5.  Restart the Fail2ban service to apply the changes:
    ```bash
    sudo systemctl restart fail2ban
    ```

You can check the status of your jails and banned IPs with the command `sudo fail2ban-client status sshd`.

## 4.9 Testing VM Migration

VM migration is the process of moving a running virtual machine from one Proxmox host to another. This is a key feature for performing hardware maintenance without service interruption.

Currently, with local storage on each node, the migration process involves copying the entire VM disk image over the network. This process is functional but can be very slow, especially over a 1GbE network connection. For large VMs, this can lead to significant downtime.

**Future Improvements:**

The long-term goal for this project is to implement a High Availability (HA) storage solution, such as Ceph. Ceph is a distributed storage platform that provides a unified storage pool across all nodes in the cluster. When a VM's disk is stored on Ceph, the migration process becomes nearly instantaneous. This is because the disk image is already accessible to all nodes, so only the VM's running state (the contents of its RAM) needs to be transferred over the network.

Upgrading the network infrastructure from 1GbE to 10GbE or faster is also a planned improvement. This will not only speed up local storage migrations but is also a prerequisite for achieving good performance with distributed storage systems like Ceph.