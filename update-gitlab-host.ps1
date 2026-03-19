# Script to update hosts file and open GitLab in browser

# 1. Ensure we are in the script's directory (to find Vagrantfile)
Set-Location $PSScriptRoot

# 2. Administrator privileges check (required to edit hosts file)
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script requires administrator privileges to modify the hosts file." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit
}

$HostName = "gitlab.local"
$HostsPath = "C:\Windows\System32\drivers\etc\hosts"

# 3. Check VM status and start if necessary
Write-Host "Checking GitLab VM status..." -ForegroundColor Cyan
try {
    $vagrantStatus = vagrant status --machine-readable | Select-String ",state,(\w+)$"
    $vmState = "unknown"
    if ($vagrantStatus) {
        $vmState = $vagrantStatus.Matches.Groups[1].Value
    }

    if ($vmState -ne "running") {
        Write-Host "VM is not running (status: $vmState). Starting VM..." -ForegroundColor Yellow
        vagrant up
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to start Vagrant VM."
        }
    } else {
        Write-Host "VM is already running." -ForegroundColor Green
    }
} catch {
    Write-Host "Error checking/starting VM: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit
}

Write-Host "Getting GitLab VM IP address..." -ForegroundColor Cyan

# 4. Get IP address via vagrant ssh
# vagrant ssh -c "hostname -I" returns a list of IPs, we take the first one (most likely for external network)
try {
    $rawIpOutput = vagrant ssh -c "hostname -I" 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($rawIpOutput)) {
        throw "Failed to get IP from Vagrant. Make sure the virtual machine is running (vagrant status)."
    }
    # Clean up and extract the first IP
    $GitlabIp = ($rawIpOutput -split '\s+').Trim() | Where-Object { $_ -match '^\d{1,3}(\.\d{1,3}){3}$' } | Select-Object -First 1
    
    if (-not $GitlabIp) {
        throw "IP address not found in vagrant command output."
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit
}

Write-Host "Found IP: $GitlabIp" -ForegroundColor Green

# 5. Update hosts file
Write-Host "Updating hosts file..." -ForegroundColor Cyan

$hostsContent = Get-Content $HostsPath
$newHostsContent = @()
$found = $false

foreach ($line in $hostsContent) {
    if ([string]::IsNullOrWhiteSpace($line)) {
        $newHostsContent += $line
        continue
    }
    if ($line.Trim() -match "(^|\s)$($HostName.Replace('.', '\.'))(\s|$)") {
        # If we found a line with gitlab.local, skip it, we'll add a new one at the end
        continue
    } else {
        $newHostsContent += $line
    }
}

# Add new entry at the end
$newHostsContent += "$GitlabIp`t$HostName"

# Save hosts file
try {
    $newHostsContent | Out-File $HostsPath -Encoding ASCII
    Write-Host "Hosts file successfully updated." -ForegroundColor Green
} catch {
    Write-Host "Failed to write to hosts file: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit
}

# 6. Create desktop shortcut
Write-Host "Creating desktop shortcut..." -ForegroundColor Cyan

$WshShell = New-Object -ComObject WScript.Shell
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$ShortcutPath = Join-Path $DesktopPath "gitlab.lnk"
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)

# Shortcut parameters: run PowerShell with this script and require admin rights
$Shortcut.TargetPath = "powershell.exe"
$ScriptPath = $MyInvocation.MyCommand.Path
# To run as admin, a wrapper could be used, but it's easier to set the flag in the shortcut (though difficult via COM)
# Leave the direct path to the script, it will check for privileges on launch (code above)
$Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
$Shortcut.WorkingDirectory = $PSScriptRoot
$Shortcut.IconLocation = Join-Path $PSScriptRoot "gitlab.ico"
$Shortcut.Description = "Update IP and open GitLab.local"
$Shortcut.Save()

Write-Host "Shortcut created on desktop: $ShortcutPath" -ForegroundColor Green

# 7. Launch browser
Write-Host "Opening http://$HostName in browser..." -ForegroundColor Cyan
Start-Process "http://$HostName"

Write-Host "Done!" -ForegroundColor Green
Start-Sleep -Seconds 3
