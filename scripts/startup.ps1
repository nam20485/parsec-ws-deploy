# startup.ps1 (v2 - More Robust)
# This script runs on the first boot of the Windows VM.

# --- Part 0: Setup Logging ---
$logPath = "C:\startup-log.txt"
function Write-Log {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $message"
    Add-Content -Path $logPath -Value $logMessage
    Write-Output $logMessage
}

Write-Log "Startup script started."

try {
    # --- Part 1: Wait for and Configure RAID 0 Array ---
    Write-Log "Waiting for uninitialized disks to appear..."
    $disks = $null
    $timeout = 15 # Wait up to 15 * 10 = 150 seconds
    $count = 0

    while ($count -lt $timeout) {
        $disks = Get-Disk | Where-Object { $_.PartitionStyle -eq 'Raw' -and $_.Number -ne 0 }
        if ($disks.Count -ge 2) {
            Write-Log "Found 2 or more raw disks. Proceeding with RAID configuration."
            break
        }
        Write-Log "Disks not ready yet. Waiting 10 seconds..."
        Start-Sleep -s 10
        $count++
    }

    if ($disks.Count -lt 2) {
        throw "Timed out waiting for 2 raw disks to appear. Please check the instance configuration."
    }

    Write-Log "Initializing disks and creating RAID 0 volume..."
    $raidScript = "
        # Bring the disks online, initialize as GPT, and create a new striped volume (RAID 0)
        $disks | Initialize-Disk -PartitionStyle GPT -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel 'RAID0_Fast_Storage' -Confirm:$false
    "
    
    # Using Invoke-Command to ensure it runs in the correct scope
    Invoke-Command -ScriptBlock ([ScriptBlock]::Create($raidScript))
    Write-Log "RAID 0 volume created successfully."

    # --- Part 2: Download and Install Parsec ---
    Write-Log "Starting Parsec installation..."
    $downloadPath = "C:\Users\admin\Downloads"
    $installerUrl = "https://builds.parsec.app/package/parsec-windows.exe"
    $installerPath = Join-Path $downloadPath "parsec-windows.exe"

    if (-not (Test-Path $downloadPath)) {
        New-Item -Path $downloadPath -ItemType Directory
    }

    Write-Log "Downloading Parsec installer..."
    (New-Object System.Net.WebClient).DownloadFile($installerUrl, $installerPath)

    Write-Log "Running Parsec installer silently..."
    Start-Process -FilePath $installerPath -ArgumentList "/silent" -Wait
    Write-Log "Parsec installation complete."

}
catch {
    Write-Log "AN ERROR OCCURRED: $($_.Exception.Message)"
}
finally {
    Write-Log "Startup script finished."
}
