# BOOTSTRAP.md  
## Bringing New Machines Under Ansible Management

This document explains the **manual steps required** to prepare a new Linux or Windows machine for management by the `homelab` project.

This *is not* a guidelines/style document.  
This *is* the “real-world checklist” for on-boarding machines.

---

# 1. Overview

Your homelab uses a minimal, safe bootstrap flow:

- No secrets in the repo  
- No private keys in Git  
- One admin identity: `homelab_admin_user` (defined in `group_vars/all.yml`)  
- SSH public keys provided via **file lookup** from the control node  
- Passwords and sensitive values stored in **vaulted var files**  
- After bootstrap, all access uses **key-based auth (Linux)** or **WinRM**  

---

# 2. Control Node Requirements

Your Ansible control node is:

- Windows 11 Pro  
- Using **WSL2 (Ubuntu)**  
- With Ansible installed:

```bash
sudo apt update
sudo apt install -y ansible python3-venv
```

You should also have your SSH keypair (used for all Linux bootstrap):

```text
~/.ssh/homelab_admin_ed25519
~/.ssh/homelab_admin_ed25519.pub
```

Store only the public key path in Ansible:

`group_vars/all.yml`:

```yaml
homelab_admin_user: jerry
homelab_admin_shell: /bin/bash
homelab_admin_sudo_nopasswd: true

homelab_admin_ssh_public_key_file: "~/.ssh/homelab_admin_ed25519.pub"
```

Bootstrap roles load it dynamically:

```yaml
lookup('file', homelab_admin_ssh_public_key_file)
```

This lets you rotate or regenerate keys with **no changes to repo data**.

---

# 3. Secrets Layout (Required Before Bootstrapping Anything)

Secrets are stored separately and encrypted. The expected structure:

```text
group_vars/
  all.yml                # non-secret global defaults
  all.vault.yml          # encrypted global secrets

inventories/
  dev/
    group_vars/
      dev.yml            # non-secret overrides
      dev.vault.yml      # dev-only secrets (optional)
    host_vars/
      mintbook-lab.yml   # non-secret host data
      mintbook-lab.vault.yml   # host secrets (also optional)
```

Create vault files:

```bash
ansible-vault create group_vars/all.vault.yml
```

Typical vaulted values:

```yaml
homelab_bootstrap_linux_password: "temporary-linux-password"
homelab_windows_admin_password: "windows-admin-password"
```

Use `--ask-vault-pass` or a vault password file (which must be `.gitignore`d).

---

# 4. Bootstrapping Linux Machines (Mint, Ubuntu, Debian)

This process gets a fresh Linux system to the point where it has:

- Your standard admin user created  
- SSH key-based login enabled  
- Passwordless sudo (if enabled)  
- Python installed  
- Safe defaults for future roles  

### 4.1 On the New Linux Machine (Manual)

1. **Install OS normally.**
2. **Create a temporary admin account** (ex: `jerry`).
3. **Ensure SSH is installed and running:**

```bash
sudo apt install -y openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh
```

4. **Set a permanent hostname:**

```bash
sudo hostnamectl set-hostname acer
```

5. **Verify SSH access from WSL:**

```bash
ssh jerry@acer.lan
```

If this works, you’re ready for Ansible.

---

### 4.2 Add Host to Inventory

`inventories/dev/hosts.yml` (example snippet):

```yaml
linux_desktops:
  hosts:
    acer:
      ansible_host: acer.lan
      ansible_user: jerry
      ansible_become: true
      ansible_python_interpreter: /usr/bin/python3
```

(Your full inventory will have more groups; see `inventories/dev/hosts.yml`.)

---

### 4.3 Run Linux Bootstrap Playbook

```bash
cd homelab-ansible

ansible-playbook \
  -i inventories/dev/hosts.yml \
  playbooks/bootstrap-linux-access.yml \
  -l acer \
  --ask-pass \
  --ask-become-pass
```

The bootstrap role will:

- Ensure Python exists  
- Create `homelab_admin_user`  
- Install your SSH public key  
- Enable passwordless sudo (if configured)  

---

### 4.4 Switch Inventory to Managed Admin User

After bootstrap, modify `inventories/dev/hosts.yml` for `acer`:

```yaml
acer:
  ansible_host: acer.lan
  ansible_user: "{{ homelab_admin_user }}"
  ansible_become: true
  ansible_ssh_private_key_file: ~/.ssh/homelab_admin_ed25519
```

From here onward, the machine is fully managed by Ansible.

---

# 5. Bootstrapping Windows Machines (Windows 10/11)

Goal: enable a stable, Ansible-ready WinRM configuration.

### 5.1 On the New Windows Machine (Manual)

1. Install Windows normally.
2. Create an admin user (ex: `Jerry`).
3. Open **an elevated PowerShell** and run:

```powershell
winrm quickconfig
```

or, better, Microsoft’s official script:

```powershell
iwr -useb https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1 | iex
```

This configures:

- WinRM HTTP listener  
- Firewall rules  
- Basic/NTLM auth settings  
- Service autostart  

4. Verify network access from WSL (optional sanity check):

```bash
winrs -r:eqr2025 cmd
```

---

### 5.2 Add Host to Inventory

Inventory snippet for `eqr2025`:

```yaml
windows_desktops:
  hosts:
    eqr2025:
      ansible_host: eqr2025.lan
      ansible_user: Jerry
      ansible_password: "{{ homelab_windows_admin_password }}"
      ansible_connection: winrm
      ansible_winrm_transport: ntlm
      ansible_winrm_server_cert_validation: ignore
```

The password should come from `group_vars/all.vault.yml`.

---

### 5.3 Run the Windows Bootstrap Playbook

```bash
ansible-playbook \
  -i inventories/dev/hosts.yml \
  playbooks/bootstrap-windows-access.yml \
  -l eqr2025 \
  --ask-vault-pass
```

Your role currently handles:

- Ensuring a standardized `homelab_admin_user` exists (if you choose to create one)  
- Ensuring WinRM is enabled and auto-starting  
- Enabling reliable remote command execution  

---

### 5.4 Switch Inventory to Homelab Admin Account (Optional)

If you choose to create a dedicated Windows homelab admin account, update inventory:

```yaml
eqr2025:
  ansible_host: eqr2025.lan
  ansible_user: homelab_admin
  ansible_password: "{{ homelab_windows_admin_password }}"
  ansible_connection: winrm
  ansible_winrm_transport: ntlm
  ansible_winrm_server_cert_validation: ignore
```

Your Windows machine is now ready for full Ansible configuration.

---

# 6. Managing the Control Node (WSL Ubuntu)

The control node’s WSL Ubuntu environment is just another Linux host from Ansible’s point of view.

Inventory:

```yaml
control_nodes:
  hosts:
    control:
      ansible_connection: local
      ansible_python_interpreter: /usr/bin/python3
```

You can safely apply roles like:

- `linux-base`
- `dev-tools-linux`
- `control-node-extras`

Avoid roles that aggressively remove packages or change system services unless they are explicitly written for control nodes.

---

# 7. After Bootstrap: What Happens Next

Once a machine has switched to the `homelab_admin_user`, it is safe to apply:

- `linux-base`
- `windows-base`
- `mint-xfce-desktop-base`
- `dev-tools-common`
- `dev-tools-linux`
- `dev-tools-windows`
- Hardware-specific or hypervisor-specific roles

All of these roles should be idempotent and safe to re-run.

---

# 8. Regenerating SSH Keys (Recommended)

Since the repo stores only:

```yaml
homelab_admin_ssh_public_key_file: "~/.ssh/homelab_admin_ed25519.pub"
```

…you can do:

```bash
rm ~/.ssh/homelab_admin_ed25519*
ssh-keygen -t ed25519 -f ~/.ssh/homelab_admin_ed25519
```

Then simply re-run `bootstrap-linux-access` against any machine:

```bash
ansible-playbook -i inventories/dev/hosts.yml playbooks/bootstrap-linux-access.yml -l <host>
```

No repo edits required.

---

# 9. Summary

This doc gives you a clean, repeatable, safe flow for onboarding machines:

- Minimal manual setup  
- Centralized secrets (vault)  
- SSH public key reading from disk  
- Always-transition-to-homelab-admin  
- No private keys or passwords in Git  
- No OS meta-package modifications during bootstrap  

It sits beside your `README.md` (project description) and `GUIDELINES.md` (coding/naming/role standards).
