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


#install windows updates
Install-Module PSWindowsUpdate -Force
Import-Module PSWindowsUpdate
Get-WindowsUpdate
Get-WindowsUpdate -AcceptAll -Install -AutoReboot

