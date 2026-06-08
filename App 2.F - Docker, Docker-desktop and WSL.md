App 2.F - Docker, Docker-desktop and WSL

# WSL2


## WSL2 reset and reinstallation

1. Resetting/Cleanup of old WSL installations.
2. Enabling WSL2


I’m writing this presuming:

1. You want a clean start.
2. You probably want to use WSL as a “server-like Linux environment” but also want to know what GUI options exist.
3. You want the *least pain* and *most correctness*.
4. You may eventually use WSL for Ansible work or development.

You can paste commands directly as-is.

---

# 1. Clean Install / Reinstall of WSL on Windows 11 Pro

Windows 11 makes this far simpler than years ago.

## 1.1. Remove old WSL cruft (optional but recommended)

If you haven’t touched WSL on this machine, skip. But if you aren’t sure:

Open an elevated PowerShell:

```
wsl --shutdown
wsl --unregister Ubuntu
wsl --unregister Ubuntu-20.04
wsl --unregister docker-desktop
wsl --unregister docker-desktop-data
```

Ignore unregister errors—they just mean those weren’t installed.

Optionally:

```
dism /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart
dism /online /disable-feature /featurename:VirtualMachinePlatform /norestart
```

Reboot.

---

## 1.2. Install WSL (the modern way)

Elevated PowerShell:

```
wsl --install
```

This enables:

* WSL2 engine
* Required virtualization features
* Installs Ubuntu by default
* Includes systemd support by default
* Includes the WSLg graphical stack (Wayland + X + audio)

Reboot after it finishes.

-----------


# Creation of WSL2 Ansible Control Node 

## Linux Distribution

## Networking (NAT or Bridged)

## Strategy: SSH keys and other secrets

## Creation of VM

  1. Configuration
  2. Name
  3. Ansible installation
  4. Ansible repository: inventory, roles, playbooks, variables

-------

---

## 1.3. Choose or change your distro

Windows now supports multiple distros cleanly. To list what’s available:

```
wsl --list --online
```

Common good choices in 2025:

| Distro                    | Notes                                                                                  |
| ------------------------- | -------------------------------------------------------------------------------------- |
| **Ubuntu**                | Default, well-supported, WSL-friendly, good for dev and Ansible.                       |
| **Ubuntu 22.04 or 24.04** | The LTS versions you probably want.                                                    |
| **Debian**                | Clean, stable, minimal. No Canonical extras.                                           |
| **Fedora**                | Very polished on WSL now; systemd works well.                                          |
| **openSUSE Tumbleweed**   | Rolling release; great for newer packages.                                             |
| **Arch (Unofficial)**     | Easily installable, but not via Microsoft Store; use the `archwsl` project if desired. |

Install a specific one:

```
wsl --install -d Ubuntu-24.04
```

Launch it:

```
wsl -d Ubuntu-24.04
```

---

---

# 3. Basic Linux experience (server-oriented) — The simplest path

If you mainly want a clean, fast Linux server environment:

1. Install Ubuntu 24.04 or Debian.
2. Open Ubuntu:
   `wsl -d Ubuntu-24.04`
3. Run basic setup:

```
sudo apt update
sudo apt install build-essential curl git ripgrep fd-find
sudo ln -s /usr/lib/cargo/bin/fd /usr/local/bin/fd 2>/dev/null || true
```

4. Confirm systemd:

```
systemctl status
```

This gives you a very normal Linux server environment.

---

### Full desktop via RDP (Optional)

This is very stable lately.

Install XFCE or MATE:

```
sudo apt install xfce4
sudo apt install xrdp
sudo systemctl enable --now xrdp
```

Then from Windows:

```
mstsc.exe
```

Connect to WSL via localhost:3389.

Pros: Smooth, supports full desktops, no X server needed.
Cons: Slightly less integration with Windows apps.

---

# 5. Recommendation: What distro *you* should use

Given your technical background and desire for:

* A clean Linux server environment
* Ansible
* Some potential GUI apps
* Systemd working
* Minimal friction

I recommend:

**Ubuntu 24.04 LTS**
(Or Ubuntu 22.04 LTS if you want more maturity.)

If you want faster packages:

**Fedora** is excellent under WSL in 2025.

If you want minimal/no corporate extras:

**Debian** is perfect.

---

# 6. Next steps

1. Set up your directory structure for WSL work / Ansible work
2. Show how to get SSH keys working cleanly
3. Show how to integrate Windows editors (like VSCode) with your WSL environment
