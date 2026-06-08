
# App 2.B - Host Network Configuration for Remote Management

## 1. Objectives and Scope

The purpose of this module is to establish reliable network visibility, configuration management, and orchestration paths across a diverse homelab sandbox environment. Remote administration requires a foundational, automated network layout that ensures zero-configuration discovery, dual-stack transparency, and secure transport access.

While this architecture is designed to eventually scale across multiple operating systems (including Linux distributions and Android environments), this appendix currently details the automation routines for **Windows-based nodes** (Windows 11 Pro).

The primary objectives include:

* Establishing reliable network visibility using dual-stack (IPv4/IPv6) diagnostic tracing.
* Programmatically configuring host and guest firewalls to allow inbound orchestration services (Ansible, OpenSSH, WinRM).
* Enforcing consistent network profile classifications to eliminate transport constraints.
* Utilizing idempotent scripting architectures to safely allow repeated execution without state degradation.

---

## 2. Design Decisions & Architecture

```
+------------------------------------+               +------------------------------------+
|        Management Host             |               |            Target Guest            |
|   (e.g., Physical Workstation)     |               |         (e.g., Win 11 VM)          |
|                                    |               |                                    |
|  +------------------------------+  |  Diagnostics  |  +------------------------------+  |
|  |  Diagnostic Inbound Perim.   |=============>>===|  |   Echo Request & ICMPv6      |  |
|  +------------------------------+  |  (ICMP / v6)  |  +------------------------------+  |
|                                    |               |                                    |
|  +------------------------------+  |  Orchestrate  |  +------------------------------+  |
|  |   Ansible / Control Plane    |=============>>===|  | SSH (22) / WinRM (5985/5986) |  |
|  +------------------------------+  |               |  +------------------------------+  |
|                                    |               |                                    |
|  +------------------------------+  |               |                                    |
|  | Virtual Adapter Profile Pin  |  |               |                                    |
|  | (Public -> Private Profile)  |  |               |                                    |
|  +------------------------------+  |               |                                    |
+------------------------------------+               +------------------------------------+

```

### Dual-Stack Support with IPv4 Emphasis

Firewall mechanisms handle IPv4 and IPv6 traffic under distinct rulesets. Both communication pathways must be explicitly provisioned to ensure that zero-configuration multicast DNS (`.local`) matches across both network stacks without causing silent connection drops.

### Network Profile Enforcement

Host operating systems often isolate network segments by default. Custom management interfaces (such as virtual host-only adapters) must be explicitly pinned to a **Private** or **Domain** network profile category. Management protocols like WinRM and OpenSSH are blocked by default on profiles classified as **Public**.

### Idempotent Scripting Architecture

All configuration blocks are written to inspect the live state of firewall policies and network classifications before attempting changes. This allows safe, repeated execution during provisioning pipelines.

---

## 3. Prerequisites and Assumptions

* **Target OS:** Windows 11 Pro (Version 24H2 or later for Windows targets).
* **Execution Environment:** Windows PowerShell 5.1+.
* **Privileges:** Commands must be executed from an elevated administrative session (**Run as Administrator**).
* **Execution Policy:** Configured to permit automation scripting:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

```



---

## 4. Target Environment Configuration (Windows Guest)

Run the following unified PowerShell script inside the **Target Guest** (the virtual machine or remote physical node being managed).

Before execution, verify and adjust the initialization parameters in the `$TargetEnv` block to match your intended configuration.

```powershell
# ==============================================================================
# ENVIRONMENT PARAMETERS - TARGET GUEST CONFIGURATION
# ==============================================================================
$TargetEnv = @{
    SSHPort       = 22         # Default Scoop/OpenSSH Port
    WinRMTTTPPort = 5985       # WinRM HTTP Port
    WinRMHTTPSPort= 5986       # WinRM HTTPS Port
}

Write-Host "Starting Target Machine Configuration..." -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# Step 1: Open Diagnostic Tracing Vectors (ICMPv4 / ICMPv6)
# ------------------------------------------------------------------------------
Write-Host "[1/2] Configuring Diagnostic Tracing Vectors..." -ForegroundColor Yellow

$DiagnosticRules = @(
    "CoreNet-Diag-ICMP4-EchoRequest-In",
    "CoreNet-Diag-ICMP6-EchoRequest-In"
)

foreach ($RuleName in $DiagnosticRules) {
    $Rule = Get-NetFirewallRule -Name $RuleName -ErrorAction SilentlyContinue
    if ($Rule) {
        if ($Rule.Enabled -ne 'True') {
            Enable-NetFirewallRule -Name $RuleName
            Write-Host "  -> Enabled rule: $RuleName" -ForegroundColor Green
        } else {
            Write-Host "  -> Rule already active: $RuleName" -ForegroundColor DarkGray
        }
    } else {
        Write-Warning "  -> Built-in rule '$RuleName' not found on this system."
    }
}

# ------------------------------------------------------------------------------
# Step 2: Open Management Infrastructure Ports (SSH & WinRM)
# ------------------------------------------------------------------------------
Write-Host "[2/2] Configuring Management Infrastructure Ports..." -ForegroundColor Yellow

$ManagementPorts = @(
    @{ Name = "Homelab-Inbound-SSH";   Port = $TargetEnv.SSHPort;        Proto = "TCP"; Desc = "Inbound OpenSSH for Ansible" },
    @{ Name = "Homelab-Inbound-WinRM"; Port = $TargetEnv.WinRMTTTPPort;  Proto = "TCP"; Desc = "Inbound WinRM HTTP" },
    @{ Name = "Homelab-Inbound-WinRMS";Port = $TargetEnv.WinRMHTTPSPort; Proto = "TCP"; Desc = "Inbound WinRM HTTPS" }
)

foreach ($Service in $ManagementPorts) {
    $ExistingRule = Get-NetFirewallRule -Name $Service.Name -ErrorAction SilentlyContinue
    if (-not $ExistingRule) {
        New-NetFirewallRule -Name $Service.Name `
                            -DisplayName $Service.Name `
                            -Description $Service.Desc `
                            -Direction Inbound `
                            -Action Allow `
                            -Protocol $Service.Proto `
                            -LocalPort $Service.Port `
                            -Profile Any `
                            -ErrorAction Stop | Out-Null
        Write-Host "  -> Created and enabled rule: $($Service.Name) (Port $($Service.Port))" -ForegroundColor Green
    } else {
        if ($ExistingRule.Enabled -ne 'True') {
            Enable-NetFirewallRule -Name $Service.Name
            Write-Host "  -> Re-enabled existing rule: $($Service.Name)" -ForegroundColor Green
        } else {
            Write-Host "  -> Management port rule already active: $($Service.Name)" -ForegroundColor DarkGray
        }
    }
}

Write-Host "Target Environment Configuration Complete." -ForegroundColor Cyan

```

---

## 5. Management Host Configuration (VM Host Workstation)

Run this unified script from an elevated administrative shell on the **Virtual Machine Host** workstation.

Modify the `$HostEnv` variables below to specify the naming convention or wildcards of your virtual hypervisor adapters (e.g., `*VirtualBox*`, `*vEthernet*`, or `*VMware*`).

```powershell
# ==============================================================================
# ENVIRONMENT PARAMETERS - MANAGEMENT HOST CONFIGURATION
# ==============================================================================
$HostEnv = @{
    # Pattern to match your target virtual switch/host-only network interface adapters
    VirtualAdapterPattern = "*VirtualBox*" 
}

Write-Host "Starting Management Host Configuration..." -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# Step 1: Open Host Diagnostic Perimeters
# ------------------------------------------------------------------------------
Write-Host "[1/2] Opening Host Diagnostic Perimeters (ICMP Echo Requests)..." -ForegroundColor Yellow

$HostDiagRules = @(
    "CoreNet-Diag-ICMP4-EchoRequest-In",
    "CoreNet-Diag-ICMP6-EchoRequest-In"
)

foreach ($RuleName in $HostDiagRules) {
    $Rule = Get-NetFirewallRule -Name $RuleName -ErrorAction SilentlyContinue
    if ($Rule) {
        if ($Rule.Enabled -ne 'True') {
            Enable-NetFirewallRule -Name $RuleName
            Write-Host "  -> Enabled host rule: $RuleName" -ForegroundColor Green
        } else {
            Write-Host "  -> Host rule already active: $RuleName" -ForegroundColor DarkGray
        }
    } else {
        Write-Warning "  -> Built-in rule '$RuleName' not found on this Host."
    }
}

# ------------------------------------------------------------------------------
# Step 2: Rectify Virtual Network Adapter Classifications
# ------------------------------------------------------------------------------
Write-Host "[2/2] Evaluating and Correcting Virtual Network Adapter Classifications..." -ForegroundColor Yellow

# Query all interfaces matching the hypervisor adapter pattern
$TargetAdapters = Get-NetConnectionProfile -InterfaceAlias $HostEnv.VirtualAdapterPattern -ErrorAction SilentlyContinue

if ($TargetAdapters) {
    foreach ($Adapter in $TargetAdapters) {
        if ($Adapter.NetworkCategory -ne 'Private' -and $Adapter.NetworkCategory -ne 'Domain') {
            Write-Host "  -> Found adapter '$($Adapter.InterfaceAlias)' categorized as '$($Adapter.NetworkCategory)'." -ForegroundColor Yellow
            Set-NetConnectionProfile -InterfaceIndex $Adapter.InterfaceIndex -NetworkCategory Private
            Write-Host "     ==> Successfully reclassified to 'Private'." -ForegroundColor Green
        } else {
            Write-Host "  -> Adapter '$($Adapter.InterfaceAlias)' already correctly assigned to profile: $($Adapter.NetworkCategory)" -ForegroundColor DarkGray
        }
    }
} else {
    Write-Warning "  -> No network interfaces matched the pattern: '$($HostEnv.VirtualAdapterPattern)'"
    Write-Host "     Verify your hypervisor network naming conventions and update `$HostEnv.VirtualAdapterPattern." -ForegroundColor DarkGray
}

Write-Host "Management Host Configuration Complete." -ForegroundColor Cyan

```

---

## 6. Verification and Validation

Execute these routines to mathematically and functionally verify that the environment-specific configurations are passing transport constraints.

### 1. Evaluate Rule Deployment States (Run on Target Guest)

Verify rule assignment and operational status inside the target environment by evaluating this block:

```powershell
# Define target identifiers for evaluation
$RuleChecks = @("Homelab-Inbound-SSH", "Homelab-Inbound-WinRM", "Homelab-Inbound-WinRMS")

Get-NetFirewallRule -Name $RuleChecks -ErrorAction SilentlyContinue | 
    Select-Object Name, Enabled, Direction, Action, Profile | 
    Format-Table -AutoSize

```

#### Expected Verification Output Matrix:

| Name | Enabled | Direction | Action | Profile |
| --- | --- | --- | --- | --- |
| Homelab-Inbound-SSH | True | Inbound | Allow | Any |
| Homelab-Inbound-WinRM | True | Inbound | Allow | Any |
| Homelab-Inbound-WinRMS | True | Inbound | Allow | Any |

### 2. Verify Diagnostic Accessibility (Run on Management Host)

From your management host workstation, customize the parameters below to match your live network layout to test multi-stack routing boundaries:

```powershell
# ==============================================================================
# VERIFICATION CONFIGURATION PARAMETERS
# ==============================================================================
$VerifyEnv = @{
    TargetIPv4 = "192.168.56.101"        # Swap with your actual Target Guest IPv4
    TargetIPv6 = "fe80::a00:27ff:fec4:1" # Swap with your actual Target Guest Link-Local IPv6
    TargetHost = "win11pro24h2.local"   # Swap with target hostname or mDNS locator
    SSHPort    = 22
    WinRMPort  = 5985
}

Write-Host "Running Diagnostic Diagnostics..." -ForegroundColor Cyan

# Test Core Routing Latency
Write-Host "[ICMPv4 Ping]: " -NoNewline; Test-Connection -ComputerName $VerifyEnv.TargetIPv4 -Count 1 -Quiet
Write-Host "[ICMPv6 Ping]: " -NoNewline; Test-Connection -ComputerName $VerifyEnv.TargetIPv6 -Count 1 -Quiet

# Test Application Socket Bindings
foreach ($Port in @($VerifyEnv.SSHPort, $VerifyEnv.WinRMPort)) {
    $Result = Test-NetConnection -ComputerName $VerifyEnv.TargetHost -Port $Port -ErrorAction SilentlyContinue
    Write-Host "[Port $Port Transport Active]: $($Result.TcpTestSucceeded)"
}

```

#### Expected Operational Response Rules:

* **IPv4 Validation** maps straight to your designated target network pool address.
* **IPv6 Validation** displays local structural routing markers (such as link-local addresses prefixed with `fe80::`).
* `TransportActive` evaluates as `True` for each target port if the corresponding service daemon (`OpenSSH` or `WinRM`) is actively listening on the target guest operating system.