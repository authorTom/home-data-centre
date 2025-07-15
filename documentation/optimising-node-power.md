# 3.0 Optimising Node Power
Most systems are configured for performance, leaving considerable room for power-saving adjustments without a huge impact on workloads.

With energy prices being what they are in the UK, I’m always looking for ways to make my setup more efficient.

## 3.1 Enabling CPU C-States
This was, one of the most significant change I made. Located in the BIOS.

**Advanced > Power Management Options**

The key setting is CPU C-States.

Think of C-states as different levels of “sleep” for the processor. When the system isn’t busy, the CPU can enter a C-state to save power. The deeper the state (like C6 or beyond), the more power it saves. I made sure every C-state available was enabled.

For an “always on” system that spends a lot of time idle, this made a significant difference.

I also checked that the ACPI S3 sleep state was enabled. This is the standard “Suspend to RAM” mode. It’s less useful, but I enabled it just in case I ever need to manually put the machine into a low-power state.

## 3.2 Disable Intel Turbo Boost
Found under:

**Performance > Intel Turbo Boost Technology**

The i5-7500 processor can “turbo boost” from its standard 3.4 GHz up to 3.8 GHz when it’s under heavy load. While that extra speed is nice, it comes at the cost of significantly higher power consumption.

Since my Proxmox workloads (a couple of VMs and a few light containers) aren’t constantly demanding peak performance, I decided to disable Turbo Boost.

I’ve found this gives me a slight drop in power usage when the server is busy, with almost no noticeable performance loss for my needs.

I’d recommend you experiment with this one – the trade-off might be worth it for you.

## 3.3 PowerTOP
PowerTOP is a utility that analyses power consumption and provides suggestions for optimisation.

Its most useful feature is `--auto-tune`, which automatically applies these optimisations.

### Installing PowerTOP

Within the Proxmox node’s shell
```
apt update
apt install powertop
```

### Initial Analysis

Before you enable auto-tuning, it’s a good idea to run PowerTOP in its interactive mode to see the current state of the system. This will give you a “before” snapshot.

Run the following command
```
powertop
```
It’s best to let it run for a few minutes with minimal running to get a good idle baseline reading.

On the text-based interface. Use the `Tab` key to navigate between different screens:
- Overview: Shows a summary of power usage by device and process.
- Idle stats: Shows processor C-state usage. Higher C-states (C6, C7) mean deeper sleep and less power used.
- Frequency stats: Shows processor P-state usage (how often your CPU runs at different frequencies).
- Device stats: Shows power usage estimates for individual devices.
- Tunables: This is the most important screen for our purpose. It lists all the power-saving settings that PowerTOP can manage. You’ll see many of them marked as “Bad”. Our goal is to make them “Good”.

Press Esc or q to exit PowerTOP.

### Run Auto-Tune

The `--auto-tune` flag tells PowerTOP to immediately set all tunable options to their most efficient setting.
```
powertop --auto-tune
```
The command will run and exit without any interactive prompts. It will flip all “Bad” tunables to “Good”. You can verify this by running powertop again and checking the “Tunables” tab. All settings should now be “Good”.

Important Note: PowerTOP’s effects are temporary and will be lost upon reboot. It needs to persistent.

### Auto-Tune Persistence

To have these settings apply automatically every time your Proxmox node boots, we create a systemd service.

### Create a systemd Service File

Use a text editor like nano to create the service file:
```
nano /etc/systemd/system/powertop.service
```
Add the following content to the file.
```
[Unit]
Description=PowerTOP auto-tuning

[Service]
Type=oneshot RemainAfterExit=false ExecStart=/usr/sbin/powertop --auto-tune

[Install]
WantedBy=multi-user.target
Save and exit the editor.
```
Enable the new service.
Use systemd to create a symbolic link so the service will start on boot.
```
systemctl daemon-reload
systemctl enable powertop.service
```
You should see output confirming that a symlink was created.

### Verification

Reboot your Proxmox node.

This is the ultimate test to ensure the service runs correctly on a fresh boot.
```
reboot
```
After the node is back online

Check the status of the service.
```
systemctl status powertop.service
```
You should see output indicating the service is active (exited). The green active status confirms that the command ran successfully during boot and exited as expected (due to Type=oneshot).

Run interactive PowerTOP again.
```
powertop
```
Navigate to the Tunables tab. All (or nearly all) of the settings should now be marked as “Good”, confirming that your systemd service worked perfectly.

## 3.4 CPU Governor
By default, Proxmox sets the CPU scaling governor to ‘performance‘, meaning the CPUs run at full speed constantly.

Using a helper script, I was able to change to the ‘ondemand‘ governor. This scales the CPU clock speed based on load, reducing power draw during quiet periods.

➡️[Proxmox VE CPU Scaling Governor](https://community-scripts.github.io/ProxmoxVE/scripts?id=scaling-governor)


```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/scaling-governor.sh)"
```
