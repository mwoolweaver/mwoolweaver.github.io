---
layout: post
section-type: post
title: Pi-Hole on Google Compute Engine
category: tech
tags: [ 'tutorial' ]
---

Set up a Pi-Hole Ad Blocking VPN Server with a static Anycast IP on Google Cloud's Always Free Usage Tier
Configure Full Tunnel or Split Tunnel OpenVPN connections from your Android, iOS, macOS, & Windows devices



The goal of this guide is to enable you to safely and privately use the Internet on your phones, tablets, and computers with a self-run VPN Server in the cloud. It can be run at no cost to you; shields you from intrusive advertisements; and blocks your ISP, cell phone company, public WiFi hotspot provider, and apps/websites from gaining insight into your usage activity.



Run your own privacy-first ad blocking service within the **[Free Usage Tier](https://cloud.google.com/free/)** on Google Cloud. **This guide gets you set up with a Google Cloud account, and walks you through setting up a full tunnel (all traffic) or split tunnel (DNS traffic only) VPN connection on your Android & iOS devices, and computers.**

Both Full Tunnel and Split Tunnel VPN connections provide DNS based ad-blocking over an encrypted connection to the cloud. The differences are:

- A Split Tunnel VPN allows you to interact with devices on your Local Network (such as a Chromecast or Roku).
- A Full Tunnel VPN can help bypass misconfigured proxies on corporate WiFi networks, and protects you from Man-In-The-Middle SSL proxies.

| Tunnel Type | Data Usage | Server CPU Load | Security | Ad Blocking |
| -- | -- | -- | -- | -- |
| full | +10% overhead for vpn | moderate | 100% encryption | yes
| split | just kilobytes per day | very low | dns encryption only | yes

The technical merits of major choices in this guide are outlined in [REASONS.md](https://github.com/mwoolweaver/Pi-Hole-PiVPN-Google-Compute-Engine/blob/master/REASONS.md).

---

Google Cloud Login and Account Creation

Go to https://cloud.google.com and click **Console** at the top right if you have previously used Google's Cloud Services, or click **Try Free** if it's your first time.

 Account Creation

 - **Step 1 of 2** <br> Agree to the terms and continue. <br><img src="./images/screenshots/5.png" width="265">
 - **Step 2 of 2** <br> Set up a payments profile and continue <br><img src="./images/screenshots/5.png" width="223">

  Project & Compute Engine Creation
 - Click the Hamburger Menu at the top left
 - Click **Compute Engine**
 - Select **VM instances**
 - Create a Project if you don't already have one
- Enable billing for this Project if you haven't already
- Compute Engine will begin initializing


Compute Engine Virtual Machine Setup

- Create a Virtual Machine instance on Compute Engine
- Customize the instance
- Name your Virtual Machine **pi-hole**. <br>Your Region selection should be any US region only (excluding Northern Virginia [us-east4]). I have used **us-east1** and the **us-east1-b** zone because it is closest to me. <br>Choose a **micro** Machine Type in the dropdown. <br>Change the **Boot Disk** to be **30GB** if you plan on keeping your DNS lookup records for any reason, otherwise the default **10GB** disk allocation is adequate. <br>**Allow HTTP traffic** in the Firewall (add a checkmark).
<br>**Allow HTTPS traffic** in the Firewall (add a checkmark).
- Expand **Management, Security, disks, networking, sole tenancy** and click the **Network** tab. Click the Pencil icon under **Network Interfaces**.
- The External IP Address should not be Ephemeral. Choose **Create IP Address** to Reserve a New Static IP Address
- You can log into your Virtual Machine via SSH in a Browser by clicking the SSH button. Make note of your External IP (it will be different from the screenshot below).
- Click the Hamburger Menu at the top left, click **VPC Network** and click **Firewall Rules**.  <br>Click **Create Firewall Rule** at the top center of the page. The name of your rule should be `allow-openvpn`, change the **Targets** dropdown to **All instances in the network**. The **Source IP Ranges** should be `0.0.0.0/0`. The **udp** checkbox should be selected, and the port number next to it should be changed from `all` to `1194`. Then click the **Create** button. You can disable the `default-allow-rdp` rule which Google set up with a default action of Allow, but because our server does not run any service on Port 3389 it is harmless to leave this rule alone. Do not disable the **default-allow-ssh** firewall rule, or you will disable the browser-based SSH from within the Google Cloud Console.


Debian Update & Upgrade

Once you log into your Virtual Machine via SSH, you want to update and upgrade it.

Ensure you have elevated root privileges by running this command in the bash shell:

```
sudo su
```

Update and upgrade by running this command in the bash shell:

```
apt-get update && apt-get upgrade -y
```



Pi-Hole Installation

Pi-Hole is a DNS based adblocker.

Ensure you have elevated root privileges by running this command in the bash shell:

```
sudo su
```

Install Pi-Hole by running this command in the bash shell:

```
curl -sSL https://install.pi-hole.net | bash
```

You will flow into a series of prompts in a blue screen.

- Choose OK or answer positively for all the prompts until the "Select Protocols" question appears. IPv6 needs to be deselected as shown below

- Choose OK or answer positively for all the other prompts.

Set a strong password that you will remember for the Web Interface

```
pihole -a -p
```

- Log into the web interface using the External IP that you noted down earlier at<br> `http://your-external-ip/admin/settings.php?tab=dns`

- Click **Settings**, and navigate to **DNS**. <br>Set your **Interface Listening Behavior** to **Listen on All Interfaces** on this page

- Click the **Save** Button at the bottom of the page.



 PiVPN Installation

PiVPN is an OpenVPN setup and configuration tool.

Ensure you have elevated root privileges by running this command in the bash shell:

```
sudo su
```

Install PiVPN by running this command in the bash shell:

```
curl -L https://install.pivpn.io | bash
```

You will flow into a series of prompts in a blue screen. All of the default values are appropriate.

- Choose OK or answer positively for all the prompts until you have to choose an upstream DNS provider. The default answer is Google. Choose **Custom** and set an IP Address of **10.8.0.1**

The default answer to reboot is **No** at the end of the installer. It is fine to say **No**, we have a few more things to edit while we're logged in as root.



 OpenVPN Configuration

Ensure you have elevated root privileges by running this command in the bash shell:

```
sudo su
```

Get into the openvpn directory by running this command in the bash shell:

```
cd /etc/openvpn
```

 Server Configuration for VPN over UDP on Port 1194

Edit **server.conf**. I use **nano** to edit by running this command in the bash shell:

```
nano server.conf
```

Comment out the line which reads `push "redirect-gateway def1"` so it reads as follows:

> ```
> # push "redirect-gateway def1"
> ```

The longer the keep-alive interval the longer it will take either end of the openvpn connection to detect whether the connection is no longer alive. Because mobile devices often lose connectivity and regain it, lower values are desirable.

Comment out `keepalive 1800 3600` and add `keepalive 10 60` below it, so it appears as follows:

> ```
> # keepalive 1800 3600
> keepalive 10 60
> ```

Comment out the line which reads `cipher AES-256-CBC` and add `cipher AES-128-GCM` below it, so it reads as follows:

> ```
> # cipher AES-256-CBC
> cipher AES-128-GCM
> ```

At the bottom of the file add the following lines:

> ```
> # performance stuff
> fast-io
> compress lz4-v2
> push "compress lz4-v2"
> ```

Press `CTRL` `O` to bring up the save prompt at the bottom of Nano, press **Enter** to save. Then press `CTRL` `X` to exit

 Finalize VPN Confgurations on Server

Reboot the server by running this command in your bash shell:

```
shutdown -r now
```

<img src="./images/logos/pivpn.png" width="48" align="left">

Managing the PiVPN

Connect to the Pi-Hole server and set up an OpenVPN Client Profile. (You do not need to have elevated root privileges to do this.)

```
pivpn add nopass
```

Give your client profile a name. I like to use an alphanumeric string composed of the user's first name, and their device's make and model (no spaces and no special characters).

> ## NOTE
> Make a new client profile for every device. DO NOT share a client profile between two different devices.

This command will output a success message which looks like this:

  > ```
  > ========================================================
  > Done! mypixel3xl.ovpn successfully created!
  > mypixel3xl.ovpn was copied to:
  >   /home/myusername/ovpns
  > for easy transfer. Please use this profile only on one
  > device and create additional profiles for other devices.
  > ========================================================
  > ```

To get the **mypixel3xl.ovpn** file to your phone it is easiest to maximize your SSH window and print the file to the terminal window, to copy & paste the output:

```
cat ~/ovpns/mypixel3xl.ovpn
```

Press `CTRL` `-` until the screen zooms out to a point where you can see the entire ovpn file printed on the screen. The first line will have the word `client` and the last line is `</tls-crypt>`. Highlighting this entire chunk with a mouse will cause a scissor icon to appear in the middle of your SSH window, this means this selection has been copied to your clipboard.

Saving a Split Tunnel VPN Client Profile for UDP VPN Connections on Port 1194

Paste this into your favorite Text Editor and save the file with a name that is clear: **mypixel3xl-udp-1194-split-tunnel.ovpn**

Around Line 12, edit the line which reads `cipher AES-256-CBC` and change it to read:

> ```
> cipher AES-128-GCM
> ```

 Saving a Full Tunnel VPN Client Profile for UDP VPN Connections on Port 1194

Copy the contents of **mypixel3xl-udp-1194-split-tunnel.ovpn** and paste it into your favorite Text Editor, save the file with a name that is clear: **mypixel3xl-udp-1194-full-tunnel.ovpn**

Below `cipher AES-128-GCM` add this line:

> ```
> redirect-gateway def1
> ```

Make these .ovpn files available on your phone or tablet

E-mail these files to yourself, upload in Google Drive, or use whatever secure method you prefer to transfer this file to your device. It is safe to download this file to your device.

> ## WARNING
> Anyone that gets one of these **.ovpn** files can connect to your server.
