# startup.ps1
# This script runs on the first boot of the Windows VM.

# --- Part 1: Configure RAID 0 Array from Local SSDs ---

# Wait for disks to be available
Start-Sleep -s 15

# Get all disks that are offline and not the boot disk (Disk 0)
$disks = Get-Disk | Where-Object { $_.OperationalStatus -eq 'Offline' -and $_.Number -ne 0 }

# A simple string to build the PowerShell commands
$raidScript = "
    # Bring the disks online and clear any existing configuration
    $disks | Set-Disk -IsOffline $false
    $disks | Clear-Disk -RemoveData -RemoveOEM -Confirm:$false

    # Create a new striped volume (RAID 0) using all available non-boot disks
    New-Volume -Disk $disks -FriendlyName 'RAID0_Fast_Storage' -FileSystem NTFS -DriveLetter F -UseMaximumSize
"

# Execute the script block
Invoke-Command -ScriptBlock ([ScriptBlock]::Create($raidScript))

# --- Part 2: Download and Install Parsec ---

# Define the download path and installer URL
$downloadPath = "C:\Users\admin\Downloads"
$installerUrl = "https://builds.parsec.app/package/parsec-windows.exe"
$installerPath = Join-Path $downloadPath "parsec-windows.exe"

# Create the download directory if it doesn't exist
if (-not (Test-Path $downloadPath)) {
    New-Item -Path $downloadPath -ItemType Directory
}

# Download the Parsec installer
Write-Output "Downloading Parsec..."
(New-Object System.Net.WebClient).DownloadFile($installerUrl, $installerPath)

# Run the installer silently
Write-Output "Installing Parsec..."
Start-Process -FilePath $installerPath -ArgumentList "/silent" -Wait

Write-Output "Startup script finished."
