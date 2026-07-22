Here is the complete, modular Ansible role structure tailored for your
custom Windows audio baselines.

Following standard Ansible best practices, the tasks are separated
from the variables, allowing you to easily adjust audio file mappings
or volume percentages in the future without editing the core execution
scripts.

Directory & File Architecture

Here is how you should structure the files in your project directory.


win_baselines/
├── production.ini               # Inventory file containing your hosts
└── roles/
    └── win_audio/               # The dedicated role for audio styling
        ├── defaults/
        │   └── main.yml         # Variable definitions (paths, slider levels)
        └── tasks/
            └── main.yml         # Execution tasks using win_regedit


File Contents & Suggested Names

1. The Inventory File: production.ini

This file maps out your target machines. It includes the placeholder
IP addresses and specifies the necessary WinRM connection variables
required for Ansible to manage Windows nodes over your local network.


```text

[windows]
eqr25.lan ansible_host=192.168.1.XXX
cyber23.lan ansible_host=192.168.1.YYY

[windows:vars]
ansible_user=Administrator
ansible_password=YourSecurePasswordHere
ansible_connection=winrm
ansible_winrm_server_cert_validation=ignore
```

## 2. The Configuration Defaults: roles/win_audio/defaults/main.yml

This is your centralized control panel. Instead of hardcoding paths inside the tasks, all sound variables are defined here as keys and values.

``` yaml
---
# defaults file for win_audio
# Central variables for Jerry's Windows Audio Baseline

win_audio_volume_slider: 60
win_audio_ducking_value: 50

# Map Registry Event Key Names to target WAV file paths
win_audio_scheme_map:
  WindowsUAC: 'C:\Windows\Media\Windows Notify System Generic.wav'
  SystemAsterisk: 'C:\Windows\Media\Windows Notify.wav'
  SystemNotification: 'C:\Windows\Media\Windows Notify.wav'
  SystemExclamation: 'C:\Windows\Media\Windows Notify.wav'
  .Default: ''  # Silences the system Default Beep
  SystemHand: 'C:\Windows\Media\Windows Notify System Generic.wav'
  DeviceConnect: 'C:\Windows\Media\Windows Hardware Insert.wav'
  DeviceDisconnect: 'C:\Windows\Media\Windows Hardware Remove.wav'
  MessageBeep: 'C:\Windows\Media\Windows Notify.wav'
```

## 3. The Execution Script: roles/win_audio/tasks/main.yml

This file loops through your configuration maps using the native
ansible.windows.win_regedit module. It maintains state tracking for
the current user registry hive (HKCU).

``` yaml
---
# tasks file for win_audio
# Iterates through the default variable blocks to establish the sound environment

- name: Apply UI event sound style profiles to Current User registry
  ansible.windows.win_regedit:
    path: "HKCU:\\AppEvents\\Schemes\\Apps\\.Default\\{{ item.key }}\\.Current"
    name: ""
    data: "{{ item.value }}"
    type: string
  loop: "{{ win_audio_scheme_map | dict2items }}"
  label: "Configuring sound event: {{ item.key }}"

- name: Configure Master Audio Mixer Slider Level
  ansible.windows.win_regedit:
    path: HKCU:\Software\Microsoft\Multimedia\Audio
    name: UserVolumeSlider
    data: "{{ win_audio_volume_slider }}"
    type: dword

- name: Configure Communications Audio Ducking Percentage
  ansible.windows.win_regedit:
    path: HKCU:\Software\Microsoft\Multimedia\Audio
    name: DuckingValue
    data: "{{ win_audio_ducking_value }}"
    type: dword
```

------------------------------
## 4. Running the Playbook

To link this entire role together, create a minimal orchestrator
script named site.yml in your root directory:


``` yaml

---
- name: Deploy Core OS Baselines
  hosts: windows
  gather_facts: false
  roles:
    - win_audio
```

When you are ready to push the baseline changes out to eqr25.lan and
cyber23.lan, execute it from your control node terminal using:

``` powershell
ansible-playbook -i production.ini site.yml
```

If you want to keep expanding this workflow, let me know if you would
like to look at automating Windows updates, configuring custom path
environments, or managing WSL background services within this setup!

